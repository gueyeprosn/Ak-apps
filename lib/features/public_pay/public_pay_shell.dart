import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/api/api_error.dart';
import '../../core/errors/error_messages.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/ak_widgets.dart';
import '../payment/pay_flow_controller.dart' show urlOpenerProvider;
import '../payment/pay_widgets.dart';
import '../payment/payment_repository.dart';
import '../payment/payment_security.dart';
import 'public_pay_controller.dart';
import 'public_pay_repository.dart';

/// Textes propres à chaque parcours (adhésion / don).
class PublicPayCopy {
  const PublicPayCopy({
    required this.title,
    required this.notYetPaidBody,
    required this.editLabel,
    required this.doneTitle,
    required this.doneBody,
    this.loginAfterDone = false,
  });

  final String title;
  final String notYetPaidBody;
  final String editLabel;
  final String doneTitle;

  /// Reçoit le montant confirmé par le **serveur**, déjà mis en forme.
  final String Function(String amount) doneBody;

  /// Propose « Se connecter » après un paiement confirmé (adhésion).
  final bool loginAfterDone;
}

/// Parcours commun : formulaire (fourni) → moyen → attente → résultat.
///
/// Le formulaire reste construit (mais caché) pendant les étapes suivantes :
/// « Modifier mes informations » retrouve toute la saisie.
class PublicPayShell extends ConsumerStatefulWidget {
  const PublicPayShell({
    super.key,
    required this.provider,
    required this.copy,
    required this.form,
  });

  final AutoDisposeNotifierProvider<PublicPayController, PublicPayState> provider;
  final PublicPayCopy copy;
  final Widget form;

  @override
  ConsumerState<PublicPayShell> createState() => _PublicPayShellState();
}

class _PublicPayShellState extends ConsumerState<PublicPayShell> with WidgetsBindingObserver {
  final _phone = TextEditingController();
  bool _phonePrefilled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _phone.dispose();
    super.dispose();
  }

  /// Retour dans l'application après le prestataire : vérification immédiate.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(widget.provider.notifier).checkNow();
    }
  }

  /// Pré-remplit le numéro à débiter avec le téléphone saisi s'il est sénégalais.
  void _prefillPhone(PublicPayRequest? r) {
    if (_phonePrefilled) return;
    _phonePrefilled = true;
    final tel = switch (r) {
      AdhesionDraft(:final tel) => tel,
      DonationDraft(:final tel) => tel,
      _ => '',
    };
    if (tel.startsWith('+221')) _phone.text = tel.substring(4);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(widget.provider);
    final c = ref.read(widget.provider.notifier);
    final enabled = ref.watch(configProvider).value?.config.featureEnabled('payments') ?? true;

    return PopScope(
      // Pendant l'attente, « retour » ramène au choix du moyen au lieu de quitter.
      canPop: s.step != PublicPayStep.waiting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) c.leaveWaiting();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(widget.copy.title, style: AkText.titleLg),
        ),
        body: SafeArea(
          child: !enabled
              ? StateView(
                  icon: Icons.block,
                  tone: AkTone.warning,
                  title: l.payUnavailableTitle,
                  body: l.payUnavailableBody,
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Offstage(
                      offstage: s.step != PublicPayStep.form,
                      child: widget.form,
                    ),
                    if (s.step != PublicPayStep.form) _stepView(context, l, s, c),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _stepView(
    BuildContext context,
    AppLocalizations l,
    PublicPayState s,
    PublicPayController c,
  ) {
    switch (s.step) {
      case PublicPayStep.form:
        return const SizedBox.shrink();
      case PublicPayStep.method:
        _prefillPhone(s.request);
        return _MethodStep(
          state: s,
          controller: c,
          phone: _phone,
          copy: widget.copy,
        );
      case PublicPayStep.waiting:
        return PayWaitingView(
          methodName: payMethodName(l, s.method),
          notYetPaidBody: widget.copy.notYetPaidBody,
          onReopen: s.openedUrl != null ? c.reopen : null,
          onChangeMethod: c.leaveWaiting,
        );
      case PublicPayStep.timeout:
        return PayTimeoutView(
          body: l.publicTimeoutBody,
          onCheckNow: c.checkNow,
          onLater: () => context.pop(),
        );
      case PublicPayStep.failed:
        return StateView(
          icon: Icons.error_outline,
          tone: AkTone.danger,
          title: l.payFailedTitle,
          body: l.payFailedBody,
          actionLabel: l.payRetry,
          onAction: c.retryAfterFailure,
        );
      case PublicPayStep.done:
        return _DoneStep(state: s, copy: widget.copy);
      case PublicPayStep.waveManual:
        return _WaveManualStep(state: s);
    }
  }
}

class _MethodStep extends StatelessWidget {
  const _MethodStep({
    required this.state,
    required this.controller,
    required this.phone,
    required this.copy,
  });
  final PublicPayState state;
  final PublicPayController controller;
  final TextEditingController phone;
  final PublicPayCopy copy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final needsPhone = state.method != PayMethod.card;
    final amount = state.payment?.amount ?? state.request?.previewAmount;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AkSpace.space4,
              AkSpace.space2,
              AkSpace.space4,
              AkSpace.space4,
            ),
            children: [
              AkHeading(title: l.payMethodTitle, section: true),
              const SizedBox(height: AkSpace.space3),
              PayMethodList(
                selected: state.method,
                onSelect: controller.selectMethod,
              ),
              if (needsPhone) ...[
                const SizedBox(height: AkSpace.space5),
                AkTextField(
                  fieldKey: const Key('pay-phone'),
                  label: l.payPhoneLabel,
                  controller: phone,
                  prefixText: '+221',
                  keyboardType: TextInputType.phone,
                ),
              ],
              if (state.openFailed) ...[
                const SizedBox(height: AkSpace.space4),
                AkBanner(
                  tone: AkTone.warning,
                  icon: Icons.warning_amber_rounded,
                  text: l.payOpenFailed,
                ),
              ],
              if (state.error != null) ...[
                const SizedBox(height: AkSpace.space4),
                AkBanner(
                  tone: AkTone.danger,
                  icon: Icons.error_outline,
                  text: publicErrorMessage(l, state.error!),
                ),
              ],
            ],
          ),
        ),
        PayFooter(
          total: amount == null ? '' : formatAmount(amount, lang),
          button: AkButton(
            key: const Key('pay-button'),
            label: l.payWithMethod(payMethodName(l, state.method)),
            loading: state.busy,
            onPressed: () {
              final digits = phone.text.replaceAll(RegExp(r'\D'), '');
              controller.pay(phone: needsPhone ? '+221$digits' : null);
            },
          ),
          secondary: AkButton(
            key: const Key('edit-info'),
            kind: AkButtonKind.text,
            label: copy.editLabel,
            onPressed: controller.backToForm,
          ),
        ),
      ],
    );
  }
}

class _DoneStep extends StatelessWidget {
  const _DoneStep({required this.state, required this.copy});
  final PublicPayState state;
  final PublicPayCopy copy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final snap = state.result!;
    return Column(
      children: [
        Expanded(
          child: StateView(
            icon: Icons.check_circle_outline,
            tone: AkTone.success,
            title: copy.doneTitle,
            // Le montant affiché est celui du SERVEUR (paiement confirmé).
            body: copy.doneBody(formatAmount(snap.amount, lang)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AkSpace.space4,
            0,
            AkSpace.space4,
            AkSpace.space4,
          ),
          child: Column(
            children: [
              if (copy.loginAfterDone) ...[
                AkBanner(
                  tone: AkTone.info,
                  icon: Icons.info_outline,
                  text: l.joinDoneLogin,
                ),
                const SizedBox(height: AkSpace.space3),
              ],
              if (isAllowedPaymentUrl(snap.receiptUrl))
                Consumer(
                  builder: (context, ref, _) => AkButton(
                    key: const Key('receipt'),
                    kind: AkButtonKind.outline,
                    label: l.payReceipt,
                    icon: Icons.receipt_long_outlined,
                    onPressed: () => ref.read(urlOpenerProvider).open(Uri.parse(snap.receiptUrl!)),
                  ),
                ),
              const SizedBox(height: AkSpace.space2),
              if (copy.loginAfterDone)
                AkButton(
                  key: const Key('go-login'),
                  label: l.loginButton,
                  onPressed: () => context.go('/login'),
                )
              else
                AkButton(
                  key: const Key('finish'),
                  label: l.payFinish,
                  onPressed: () => context.pop(),
                ),
              if (copy.loginAfterDone)
                AkButton(
                  key: const Key('finish'),
                  kind: AkButtonKind.text,
                  label: l.payFinish,
                  onPressed: () => context.pop(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Secours Wave du site : aucune confirmation n'existe, rien n'est « payé ».
class _WaveManualStep extends StatelessWidget {
  const _WaveManualStep({required this.state});
  final PublicPayState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final m = state.manual!;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AkSpace.space4),
            children: [
              const SizedBox(height: AkSpace.space6),
              Text(
                l.waveManualTitle,
                style: AkText.titleLg,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AkSpace.space3),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  l.waveManualBody(
                    formatAmount(m.amount, lang),
                    m.number,
                    m.reference,
                  ),
                  style: AkText.body,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AkSpace.space5),
              AkBanner(
                tone: AkTone.warning,
                icon: Icons.schedule,
                text: l.waveManualNotPaid,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AkSpace.space4,
            0,
            AkSpace.space4,
            AkSpace.space4,
          ),
          child: AkButton(
            key: const Key('finish'),
            label: l.payFinish,
            onPressed: () => context.pop(),
          ),
        ),
      ],
    );
  }
}

/// Message d'erreur du formulaire ; en cas de numéro déjà inscrit (409),
/// propose de se connecter.
class PublicFormError extends StatelessWidget {
  const PublicFormError({super.key, required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final duplicate = publicErrorIsDuplicate(error);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AkBanner(
          key: const Key('form-error'),
          tone: AkTone.danger,
          icon: Icons.error_outline,
          text: publicErrorMessage(l, error),
        ),
        if (duplicate)
          AkButton(
            key: const Key('duplicate-login'),
            kind: AkButtonKind.text,
            label: l.joinHaveAccount,
            onPressed: () => context.go('/login'),
          ),
      ],
    );
  }
}

/// Renvoie `true` quand le serveur a refusé un numéro déjà inscrit.
bool publicErrorIsDuplicate(Object error) => error is ApiException && error.status == 409;
