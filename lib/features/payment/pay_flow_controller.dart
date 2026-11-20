import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../core/providers.dart';
import 'payment_repository.dart';
import 'payment_security.dart';

final paymentRepositoryProvider =
    Provider<PaymentRepository>((ref) => PaymentRepository(ref.watch(apiClientsProvider)));

final urlOpenerProvider = Provider<UrlOpener>((ref) => const LaunchUrlOpener());

/// Fréquence d'interrogation du serveur pendant l'attente (modifiable en test).
class PayPollConfig {
  const PayPollConfig({this.interval = const Duration(seconds: 3), this.maxAttempts = 60});
  final Duration interval;

  /// 60 × 3 s = 3 minutes, puis l'écran « confirmation pas encore reçue ».
  final int maxAttempts;
}

final payPollConfigProvider = Provider<PayPollConfig>((ref) => const PayPollConfig());

enum PayStep {
  loading,
  loadError,
  unavailable,
  upToDate,
  choose,
  method,
  waiting,
  done,
  failed,
  timeout,
}

class PayFlowState {
  const PayFlowState({
    this.step = PayStep.loading,
    this.due,
    this.months = 1,
    this.method = PayMethod.wave,
    this.intent,
    this.intentMonths = 0,
    this.result,
    this.error,
    this.busy = false,
    this.openFailed = false,
    this.openedUrl,
  });

  final PayStep step;
  final DueInfo? due;
  final int months;
  final PayMethod method;

  /// Paiement déjà créé côté serveur : réutilisé si le membre change de moyen
  /// sans changer le nombre de mois (pas de facture orpheline en double).
  final PaymentIntent? intent;
  final int intentMonths;
  final PaymentSnapshot? result;
  final Object? error;
  final bool busy;
  final bool openFailed;
  final String? openedUrl;

  PayFlowState copyWith({
    PayStep? step,
    DueInfo? due,
    int? months,
    PayMethod? method,
    PaymentIntent? intent,
    bool clearIntent = false,
    int? intentMonths,
    PaymentSnapshot? result,
    Object? error,
    bool clearError = false,
    bool? busy,
    bool? openFailed,
    String? openedUrl,
  }) =>
      PayFlowState(
        step: step ?? this.step,
        due: due ?? this.due,
        months: months ?? this.months,
        method: method ?? this.method,
        intent: clearIntent ? null : (intent ?? this.intent),
        intentMonths: clearIntent ? 0 : (intentMonths ?? this.intentMonths),
        result: result ?? this.result,
        error: clearError ? null : (error ?? this.error),
        busy: busy ?? this.busy,
        openFailed: openFailed ?? this.openFailed,
        openedUrl: openedUrl ?? this.openedUrl,
      );
}

/// Parcours de paiement d'une cotisation.
///
/// **Règle centrale : ce contrôleur ne déclare jamais un paiement réussi.** Il
/// passe à `done` uniquement quand le serveur renvoie `completed` pour ce
/// paiement. Une panne réseau pendant l'attente ne conclut rien : on continue
/// d'interroger, puis on propose de vérifier plus tard.
class PayFlowController extends AutoDisposeNotifier<PayFlowState> {
  int _generation = 0;
  bool _disposed = false;

  PaymentRepository get _repo => ref.read(paymentRepositoryProvider);

  @override
  PayFlowState build() {
    ref.onDispose(() {
      _disposed = true;
      _generation++;
    });
    return const PayFlowState();
  }

  void _set(PayFlowState s) {
    if (!_disposed) state = s;
  }

  Future<void> load() async {
    _generation++;
    _set(const PayFlowState());
    try {
      final due = await _repo.due();
      if (!due.paymentsEnabled) {
        _set(PayFlowState(step: PayStep.unavailable, due: due));
      } else if (due.periods.isEmpty) {
        _set(PayFlowState(step: PayStep.upToDate, due: due));
      } else {
        _set(PayFlowState(step: PayStep.choose, due: due, months: 1));
      }
    } on ApiException catch (e) {
      _set(PayFlowState(step: PayStep.loadError, error: e));
    }
  }

  void setMonths(int n) {
    final due = state.due;
    if (due == null) return;
    final max = due.selectableMonths;
    _set(state.copyWith(months: n.clamp(1, max < 1 ? 1 : max), clearError: true));
  }

  void toMethod() => _set(state.copyWith(step: PayStep.method, clearError: true, openFailed: false));

  void toChoose() => _set(state.copyWith(step: PayStep.choose, clearError: true, openFailed: false));

  void selectMethod(PayMethod m) => _set(state.copyWith(method: m, clearError: true, openFailed: false));

  /// Crée (ou réutilise) le paiement, ouvre le prestataire, puis attend la
  /// confirmation du serveur.
  Future<void> pay({String? phone}) async {
    if (state.busy) return;
    if (state.method != PayMethod.card) {
      var digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
      if (digits.startsWith('221') && digits.length > 9) digits = digits.substring(3);
      if (digits.length < 9) {
        // Numéro incomplet : refusé avant tout appel au serveur.
        _set(state.copyWith(
          error: const ApiException(code: 'phone_required', message: 'Numéro requis'),
          openFailed: false,
        ));
        return;
      }
    }
    _set(state.copyWith(busy: true, clearError: true, openFailed: false));
    try {
      var intent = state.intent;
      if (intent == null || state.intentMonths != state.months) {
        intent = await _repo.create(state.months);
        _set(state.copyWith(intent: intent, intentMonths: state.months));
      }

      String? url;
      if (state.method == PayMethod.card) {
        url = intent.checkoutUrl;
      } else {
        final target = await _repo.startSoftpay(intent.paymentId, state.method, phone: phone);
        if (target.alreadyPaid) {
          _set(state.copyWith(busy: false, step: PayStep.waiting));
          await _poll(intent.paymentId);
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
      _set(state.copyWith(busy: false, step: PayStep.waiting, openedUrl: url));
      await _poll(intent.paymentId);
    } on ApiException catch (e) {
      _set(state.copyWith(busy: false, error: e));
    }
  }

  /// Interroge le serveur jusqu'à un état final, ou jusqu'au délai.
  Future<void> _poll(String paymentId) async {
    final gen = ++_generation;
    final cfg = ref.read(payPollConfigProvider);
    for (var i = 0; i < cfg.maxAttempts; i++) {
      if (_disposed || gen != _generation) return;
      try {
        final snap = await _repo.status(paymentId);
        if (_disposed || gen != _generation) return;
        if (snap.isFinal) {
          _finish(snap);
          return;
        }
      } on ApiException catch (e) {
        // Session perdue : le routeur ramène à la connexion. Réseau : on continue.
        if (e.isUnauthorized) return;
      }
      await Future<void>.delayed(cfg.interval);
    }
    if (!_disposed && gen == _generation) _set(state.copyWith(step: PayStep.timeout));
  }

  void _finish(PaymentSnapshot snap) {
    if (snap.state == PaymentState.completed) {
      _set(state.copyWith(step: PayStep.done, result: snap, clearIntent: true));
      // Le profil (cotisations) est relu depuis le serveur, jamais modifié ici.
      ref.read(authControllerProvider.notifier).reloadProfile().catchError((Object _) {});
    } else {
      _set(state.copyWith(step: PayStep.failed, clearIntent: true));
    }
  }

  /// Une vérification immédiate (retour dans l'application, « Vérifier maintenant »).
  Future<void> checkNow() async {
    final id = state.intent?.paymentId;
    if (id == null || state.step == PayStep.done) return;
    if (state.step != PayStep.waiting && state.step != PayStep.timeout) return;
    try {
      final snap = await _repo.status(id);
      if (snap.isFinal) _finish(snap);
    } on ApiException {
      // Réseau : on garde l'état, le membre pourra réessayer.
    }
  }

  /// Rouvre l'application du prestataire.
  Future<void> reopen() async {
    final url = state.openedUrl;
    if (!isAllowedPaymentUrl(url)) return;
    await ref.read(urlOpenerProvider).open(Uri.parse(url!));
  }

  /// Quitte l'attente pour choisir un autre moyen (le paiement reste réutilisable).
  void leaveWaiting() {
    _generation++;
    _set(state.copyWith(step: PayStep.method, busy: false));
  }

  /// Après un échec : un nouveau paiement sera créé.
  void retryAfterFailure() =>
      _set(state.copyWith(step: PayStep.method, clearIntent: true, clearError: true, openFailed: false));
}

final payFlowProvider =
    NotifierProvider.autoDispose<PayFlowController, PayFlowState>(PayFlowController.new);
