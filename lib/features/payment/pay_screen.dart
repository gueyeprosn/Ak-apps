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
import '../../shared/widgets/official_page_button.dart';
import 'pay_flow_controller.dart';
import 'pay_widgets.dart';
import 'payment_repository.dart';
import 'payment_security.dart';

/// Message d'erreur propre au paiement (jamais de code technique).
String payErrorMessage(AppLocalizations l, Object error) {
  if (error is ApiException) {
    switch (error.code) {
      case 'payments_unavailable':
      case 'softpay_error':
        return l.payUnavailableBody;
      case 'nothing_due':
        return l.payUpToDateBody;
      case 'phone_required':
        return l.payPhoneRequired;
    }
  }
  return messageForError(l, error);
}

class PayScreen extends ConsumerStatefulWidget {
  const PayScreen({super.key});

  @override
  ConsumerState<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends ConsumerState<PayScreen> with WidgetsBindingObserver {
  final _phone = TextEditingController();
  bool _phonePrefilled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() => ref.read(payFlowProvider.notifier).load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _phone.dispose();
    super.dispose();
  }

  /// Retour dans l'application après avoir validé chez le prestataire :
  /// vérification immédiate auprès du serveur.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(payFlowProvider.notifier).checkNow();
    }
  }

  /// Pré-remplit le numéro (national, sans +221) avec celui du compte.
  void _prefillPhone() {
    if (_phonePrefilled) return;
    final auth = ref.read(authControllerProvider);
    if (auth is! AuthLoggedIn) return;
    final raw = auth.member.whatsapp.isNotEmpty ? auth.member.whatsapp : auth.member.tel;
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('221') && digits.length > 9) digits = digits.substring(3);
    _phone.text = digits;
    _phonePrefilled = true;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(payFlowProvider);
    final c = ref.read(payFlowProvider.notifier);

    return PopScope(
      // Pendant l'attente, « retour » ramène au choix du moyen au lieu de quitter.
      canPop: s.step != PayStep.waiting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) c.leaveWaiting();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.payTitle),
        ),
        body: SafeArea(child: _body(context, l, s, c)),
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l, PayFlowState s, PayFlowController c) {
    switch (s.step) {
      case PayStep.loading:
        return Center(child: CircularProgressIndicator(semanticsLabel: l.loading));
      case PayStep.loadError:
        final error = s.error;
        final offline = error is ApiException && error.isNetwork;
        final missingRoute = error is ApiException && error.status == 404;
        return StateView(
          icon: offline ? Icons.wifi_off : Icons.account_balance_wallet_outlined,
          tone: AkTone.warning,
          title: offline ? l.offlineTitle : l.payUnavailableTitle,
          body: missingRoute ? l.payMobileUnavailable : payErrorMessage(l, error ?? ''),
          actionLabel: missingRoute ? null : l.retryButton,
          onAction: missingRoute ? null : c.load,
          secondaryAction: OfficialPageButton(page: OfficialPage.account, label: l.accountOpenWeb),
        );
      case PayStep.unavailable:
        return StateView(
          icon: Icons.block,
          tone: AkTone.warning,
          title: l.payUnavailableTitle,
          body: l.payUnavailableBody,
          actionLabel: l.retryButton,
          onAction: c.load,
        );
      case PayStep.upToDate:
        return StateView(
          icon: Icons.check_circle_outline,
          tone: AkTone.success,
          title: l.payUpToDateTitle,
          body: l.payUpToDateBody,
          actionLabel: l.payFinish,
          onAction: () => context.pop(),
        );
      case PayStep.choose:
        return _ChooseStep(state: s, controller: c);
      case PayStep.method:
        _prefillPhone();
        return _MethodStep(state: s, controller: c, phone: _phone);
      case PayStep.waiting:
        return PayWaitingView(
          methodName: payMethodName(l, s.method),
          notYetPaidBody: l.payNotYetPaidBody,
          onReopen: s.openedUrl != null ? c.reopen : null,
          onChangeMethod: c.leaveWaiting,
        );
      case PayStep.done:
        return _DoneStep(state: s);
      case PayStep.failed:
        return StateView(
          icon: Icons.error_outline,
          tone: AkTone.danger,
          title: l.payFailedTitle,
          body: l.payFailedBody,
          actionLabel: l.payRetry,
          onAction: c.retryAfterFailure,
        );
      case PayStep.timeout:
        return PayTimeoutView(
          body: l.payTimeoutBody,
          onCheckNow: c.checkNow,
          onLater: () => context.pop(),
        );
    }
  }
}

// ---------------------------------------------------------------- 1 · mois
class _ChooseStep extends StatelessWidget {
  const _ChooseStep({required this.state, required this.controller});
  final PayFlowState state;
  final PayFlowController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.ak;
    final lang = Localizations.localeOf(context).languageCode;
    final due = state.due!;
    final selected = due.selection(state.months).map((d) => d.periode).toSet();
    final newest = due.newestFirst;
    final current = currentPeriode(DateTime.now());
    final max = due.selectableMonths;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding:
                const EdgeInsets.fromLTRB(AkSpace.space4, AkSpace.space2, AkSpace.space4, AkSpace.space4),
            children: [
              Row(
                children: [
                  Expanded(child: AkHeading(title: l.payMonthsLabel, section: true)),
                  const SizedBox(width: AkSpace.space2),
                  _Stepper(
                    value: state.months,
                    onMinus: state.months > 1 ? () => controller.setMonths(state.months - 1) : null,
                    onPlus: state.months < max ? () => controller.setMonths(state.months + 1) : null,
                  ),
                ],
              ),
              const SizedBox(height: AkSpace.space3),
              Text(l.payChooseIntro, style: AkText.body.copyWith(color: p.inkSoft)),
              const SizedBox(height: AkSpace.space4),
              AkCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < newest.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: p.border),
                      _PeriodRow(
                        period: newest[i],
                        selected: selected.contains(newest[i].periode),
                        isCurrent: newest[i].periode == current,
                        lang: lang,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        PayFooter(
          total: formatAmount(due.previewTotal(state.months), lang),
          button: AkButton(label: l.payContinue, onPressed: controller.toMethod),
        ),
      ],
    );
  }
}

class _PeriodRow extends StatelessWidget {
  const _PeriodRow(
      {required this.period, required this.selected, required this.isCurrent, required this.lang});
  final DuePeriod period;
  final bool selected;
  final bool isCurrent;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.ak;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AkSize.sizeTouch),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AkSpace.space4, vertical: AkSpace.space3),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? p.primary : p.surfaceRaised,
                borderRadius: BorderRadius.circular(AkRadius.radiusSm),
                border: Border.all(color: selected ? p.primary : p.borderControl, width: 2),
              ),
              child: selected ? Icon(Icons.check, size: 16, color: p.onPrimary) : null,
            ),
            const SizedBox(width: AkSpace.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(periodeLabel(period.periode, lang), style: AkText.bodyStrong),
                  Text(
                    isCurrent ? l.payMonthCurrent : l.payMonthLate,
                    style: AkText.bodySm.copyWith(color: p.inkSoft),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AkSpace.space2),
            Flexible(child: Text(formatAmount(period.amount, lang), style: AkText.bodyStrong)),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onMinus, required this.onPlus});
  final int value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    final p = context.ak;
    final l = AppLocalizations.of(context);
    Widget btn(IconData icon, VoidCallback? onTap, String key, String label) => SizedBox(
          width: AkSize.sizeTouch,
          height: AkSize.sizeTouch,
          child: IconButton(
            key: Key(key),
            onPressed: onTap,
            tooltip: label,
            icon: Icon(icon, color: onTap == null ? p.inkSoft.withValues(alpha: 0.5) : p.ink),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(AkRadius.radiusPill),
        border: Border.all(color: p.borderControl, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove, onMinus, 'months-minus', l.payMonthsMinus),
          SizedBox(
            width: 32,
            child: Text(
              Localizations.localeOf(context).languageCode == 'ar' ? toArabicIndicDigits('$value') : '$value',
              key: const Key('months-value'),
              textAlign: TextAlign.center,
              style: AkText.bodyStrong,
            ),
          ),
          btn(Icons.add, onPlus, 'months-plus', l.payMonthsPlus),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- 2 · moyen
class _MethodStep extends StatefulWidget {
  const _MethodStep({required this.state, required this.controller, required this.phone});
  final PayFlowState state;
  final PayFlowController controller;
  final TextEditingController phone;

  @override
  State<_MethodStep> createState() => _MethodStepState();
}

class _MethodStepState extends State<_MethodStep> {
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(covariant _MethodStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = widget.state;
    final previous = oldWidget.state;
    if ((current.error != null && current.error != previous.error) ||
        (current.openFailed && !previous.openFailed)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final controller = widget.controller;
    final phone = widget.phone;
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final due = state.due!;
    final needsPhone = state.method != PayMethod.card;
    final months = due
        .selection(state.months)
        .map((period) => periodeLabel(period.periode, lang))
        .join(lang == 'ar' ? '، ' : ', ');

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding:
                const EdgeInsets.fromLTRB(AkSpace.space4, AkSpace.space2, AkSpace.space4, AkSpace.space4),
            children: [
              AkHeading(title: l.payMethodTitle, section: true),
              const SizedBox(height: AkSpace.space3),
              if (state.openFailed) ...[
                AkBanner(tone: AkTone.warning, icon: Icons.warning_amber_rounded, text: l.payOpenFailed),
                const SizedBox(height: AkSpace.space3),
              ],
              if (state.error != null) ...[
                AkBanner(
                    tone: AkTone.danger, icon: Icons.error_outline, text: payErrorMessage(l, state.error!)),
                const SizedBox(height: AkSpace.space3),
              ],
              AkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, color: context.ak.primary),
                        const SizedBox(width: AkSpace.space3),
                        Expanded(child: Text(months, style: AkText.bodyStrong)),
                      ],
                    ),
                    AkButton(
                      kind: AkButtonKind.text,
                      label: l.payChangeMonths,
                      expand: false,
                      onPressed: controller.toChoose,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AkSpace.space3),
              PayMethodList(selected: state.method, onSelect: controller.selectMethod),
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
            ],
          ),
        ),
        PayFooter(
          total: formatAmount(
              state.intent != null && state.intentMonths == state.months
                  ? state.intent!.amount
                  : due.previewTotal(state.months),
              lang),
          button: AkButton(
            key: const Key('pay-button'),
            label: l.payWithMethod(payMethodName(l, state.method)),
            loading: state.busy,
            onPressed: () {
              FocusScope.of(context).unfocus();
              final digits = phone.text.replaceAll(RegExp(r'\D'), '');
              controller.pay(phone: needsPhone ? '+221$digits' : null);
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- 3 · attente
// ---------------------------------------------------------------- 4 · résultat
class _DoneStep extends StatelessWidget {
  const _DoneStep({required this.state});
  final PayFlowState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final snap = state.result!;
    final months = snap.periodes.map((p) => periodeLabel(p, lang)).join(lang == 'ar' ? '، ' : ', ');
    return Column(
      children: [
        Expanded(
          child: StateView(
            icon: Icons.check_circle_outline,
            tone: AkTone.success,
            title: l.payDoneTitle,
            // Montant et mois : ceux du SERVEUR (instantané du paiement confirmé).
            body: l.payDoneBody(months, formatAmount(snap.amount, lang)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AkSpace.space4, 0, AkSpace.space4, AkSpace.space4),
          child: Column(
            children: [
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
              AkButton(key: const Key('finish'), label: l.payFinish, onPressed: () => context.pop()),
            ],
          ),
        ),
      ],
    );
  }
}
