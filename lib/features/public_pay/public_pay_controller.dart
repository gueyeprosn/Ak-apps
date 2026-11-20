import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../core/providers.dart';
import '../payment/pay_flow_controller.dart' show urlOpenerProvider;
import '../payment/payment_repository.dart';
import '../payment/payment_security.dart';
import 'public_pay_repository.dart';

final publicPayRepositoryProvider = Provider<PublicPayRepository>(
  (ref) => PublicPayRepository(ref.watch(apiClientsProvider)),
);

/// Fréquence d'interrogation du statut public. Le serveur limite cette route à
/// 60 appels / 5 min / adresse IP (et beaucoup de membres partagent la même
/// adresse mobile) : 6 s × 30 = 3 min, soit 50 appels au plus, et un refus 429
/// est respecté (`Retry-After`).
class PublicPollConfig {
  const PublicPollConfig({
    this.interval = const Duration(seconds: 6),
    this.maxAttempts = 30,
    this.rateLimitedWait = const Duration(seconds: 30),
  });
  final Duration interval;
  final int maxAttempts;
  final Duration rateLimitedWait;
}

final publicPollConfigProvider = Provider<PublicPollConfig>(
  (ref) => const PublicPollConfig(),
);

enum PublicPayStep { form, method, waiting, done, failed, timeout, waveManual }

class PublicPayState {
  const PublicPayState({
    this.step = PublicPayStep.form,
    this.request,
    this.payment,
    this.manual,
    this.method = PayMethod.wave,
    this.result,
    this.error,
    this.busy = false,
    this.openFailed = false,
    this.openedUrl,
  });

  final PublicPayStep step;

  /// Ce que le membre a saisi (conservé pour « Modifier mes informations »).
  final PublicPayRequest? request;

  /// Paiement créé côté serveur pour [request] (toujours « pending »).
  final HostedPayment? payment;
  final WaveManualPayment? manual;
  final PayMethod method;
  final PaymentSnapshot? result;
  final Object? error;
  final bool busy;
  final bool openFailed;
  final String? openedUrl;

  PublicPayState copyWith({
    PublicPayStep? step,
    PublicPayRequest? request,
    HostedPayment? payment,
    bool clearPayment = false,
    WaveManualPayment? manual,
    PayMethod? method,
    PaymentSnapshot? result,
    Object? error,
    bool clearError = false,
    bool? busy,
    bool? openFailed,
    String? openedUrl,
  }) => PublicPayState(
    step: step ?? this.step,
    request: request ?? this.request,
    payment: clearPayment ? null : (payment ?? this.payment),
    manual: manual ?? this.manual,
    method: method ?? this.method,
    result: result ?? this.result,
    error: clearError ? null : (error ?? this.error),
    busy: busy ?? this.busy,
    openFailed: openFailed ?? this.openFailed,
    openedUrl: openedUrl ?? this.openedUrl,
  );
}

typedef _Creator = Future<CreatedPayment> Function(
  PublicPayRepository repo,
  PublicPayRequest request,
);

/// Parcours de paiement d'une adhésion ou d'un don : formulaire → moyen de
/// paiement → attente → résultat.
///
/// **Règle centrale (identique à la cotisation) : ce contrôleur ne déclare
/// jamais un paiement réussi.** Il passe à `done` uniquement quand le serveur
/// renvoie `completed` pour ce paiement. Le retour du prestataire, une page
/// ouverte ou un délai écoulé ne prouvent rien.
class PublicPayController extends AutoDisposeNotifier<PublicPayState> {
  PublicPayController(this._create);

  final _Creator _create;
  int _generation = 0;
  bool _disposed = false;

  PublicPayRepository get _repo => ref.read(publicPayRepositoryProvider);

  @override
  PublicPayState build() {
    ref.onDispose(() {
      _disposed = true;
      _generation++;
    });
    return const PublicPayState();
  }

  void _set(PublicPayState s) {
    if (!_disposed) state = s;
  }

  /// Valide le formulaire côté serveur : crée le paiement (ou réutilise celui
  /// d'une demande identique), puis passe au choix du moyen.
  Future<void> submit(PublicPayRequest request) async {
    if (state.busy) return;
    if (state.payment != null && state.request == request) {
      _set(
        state.copyWith(
          step: PublicPayStep.method,
          clearError: true,
          openFailed: false,
        ),
      );
      return;
    }
    _set(state.copyWith(busy: true, clearError: true));
    try {
      final created = await _create(_repo, request);
      switch (created) {
        case HostedPayment():
          _set(
            PublicPayState(
              step: PublicPayStep.method,
              request: request,
              payment: created,
            ),
          );
        case WaveManualPayment():
          _set(
            PublicPayState(
              step: PublicPayStep.waveManual,
              request: request,
              manual: created,
            ),
          );
      }
    } on ApiException catch (e) {
      _set(state.copyWith(busy: false, error: e));
    }
  }

  void backToForm() {
    _generation++;
    _set(
      state.copyWith(
        step: PublicPayStep.form,
        busy: false,
        clearError: true,
        openFailed: false,
      ),
    );
  }

  void selectMethod(PayMethod m) =>
      _set(state.copyWith(method: m, clearError: true, openFailed: false));

  /// Ouvre le prestataire puis attend la confirmation du serveur.
  Future<void> pay({String? phone}) async {
    final payment = state.payment;
    if (state.busy || payment == null) return;
    if (state.method != PayMethod.card) {
      var digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
      if (digits.startsWith('221') && digits.length > 9) {
        digits = digits.substring(3);
      }
      if (digits.length < 9) {
        // Numéro incomplet : refusé avant tout appel au serveur.
        _set(
          state.copyWith(
            error: const ApiException(
              code: 'phone_required',
              message: 'Numéro requis',
            ),
            openFailed: false,
          ),
        );
        return;
      }
    }
    _set(state.copyWith(busy: true, clearError: true, openFailed: false));
    try {
      String? url;
      if (state.method == PayMethod.card) {
        url = payment.checkoutUrl;
      } else {
        final target = await _repo.startSoftpay(
          payment.paymentId,
          state.method,
          phone: phone,
        );
        if (target.alreadyPaid) {
          _set(state.copyWith(busy: false, step: PublicPayStep.waiting));
          await _poll(payment.paymentId);
          return;
        }
        url = target.url;
      }
      if (!isAllowedPaymentUrl(url)) {
        // URL absente ou hors liste blanche : jamais ouverte.
        _set(state.copyWith(busy: false, openFailed: true));
        return;
      }
      final opened = await ref.read(urlOpenerProvider).open(Uri.parse(url!));
      if (!opened) {
        _set(state.copyWith(busy: false, openFailed: true));
        return;
      }
      _set(
        state.copyWith(
          busy: false,
          step: PublicPayStep.waiting,
          openedUrl: url,
        ),
      );
      await _poll(payment.paymentId);
    } on ApiException catch (e) {
      _set(state.copyWith(busy: false, error: e));
    }
  }

  Future<void> _poll(String paymentId) async {
    final gen = ++_generation;
    final cfg = ref.read(publicPollConfigProvider);
    for (var i = 0; i < cfg.maxAttempts; i++) {
      if (_disposed || gen != _generation) return;
      var wait = cfg.interval;
      try {
        final snap = await _repo.status(paymentId);
        if (_disposed || gen != _generation) return;
        if (snap.isFinal) {
          _finish(snap);
          return;
        }
      } on ApiException catch (e) {
        // Réseau ou refus temporaire : on n'en conclut rien, on continue.
        if (e.isRateLimited) wait = e.retryAfter ?? cfg.rateLimitedWait;
      }
      await Future<void>.delayed(wait);
    }
    if (!_disposed && gen == _generation) {
      _set(state.copyWith(step: PublicPayStep.timeout));
    }
  }

  void _finish(PaymentSnapshot snap) {
    if (snap.state == PaymentState.completed) {
      _set(
        state.copyWith(
          step: PublicPayStep.done,
          result: snap,
          clearPayment: true,
        ),
      );
    } else {
      _set(state.copyWith(step: PublicPayStep.failed, clearPayment: true));
    }
  }

  /// Vérification immédiate (retour dans l'application, « Vérifier maintenant »).
  Future<void> checkNow() async {
    final id = state.payment?.paymentId;
    if (id == null) return;
    if (state.step != PublicPayStep.waiting &&
        state.step != PublicPayStep.timeout) {
      return;
    }
    try {
      final snap = await _repo.status(id);
      if (snap.isFinal) _finish(snap);
    } on ApiException {
      // Réseau : on garde l'état, le membre pourra réessayer.
    }
  }

  Future<void> reopen() async {
    final url = state.openedUrl;
    if (!isAllowedPaymentUrl(url)) return;
    await ref.read(urlOpenerProvider).open(Uri.parse(url!));
  }

  /// Quitte l'attente pour choisir un autre moyen (le paiement reste réutilisable).
  void leaveWaiting() {
    _generation++;
    _set(state.copyWith(step: PublicPayStep.method, busy: false));
  }

  /// Après un échec : un nouveau paiement sera créé à la prochaine validation.
  void retryAfterFailure() =>
      _set(PublicPayState(step: PublicPayStep.form, request: state.request));
}

final adhesionPayProvider =
    NotifierProvider.autoDispose<PublicPayController, PublicPayState>(
      () => PublicPayController(
        (repo, r) => repo.createAdhesion(r as AdhesionDraft),
      ),
    );

final donationPayProvider =
    NotifierProvider.autoDispose<PublicPayController, PublicPayState>(
      () => PublicPayController(
        (repo, r) => repo.createDonation(r as DonationDraft),
      ),
    );
