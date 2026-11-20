import 'package:flutter/material.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/ak_widgets.dart';
import 'payment_repository.dart';

/// Éléments d'écran communs au paiement d'une cotisation, d'une adhésion et
/// d'un don : mêmes moyens de paiement, même attente, mêmes garde-fous.

String payMethodName(AppLocalizations l, PayMethod m) => switch (m) {
      PayMethod.wave => l.payMethodWave,
      PayMethod.orange => l.payMethodOrange,
      PayMethod.card => l.payMethodCard,
    };

/// Les trois moyens de paiement (Wave, Orange Money, carte).
class PayMethodList extends StatelessWidget {
  const PayMethodList({super.key, required this.selected, required this.onSelect});
  final PayMethod selected;
  final ValueChanged<PayMethod> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget tile(PayMethod m, String name, String sub, Widget leading) => PayMethodTile(
          key: Key('method-${m.name}'),
          title: name,
          subtitle: sub,
          leading: leading,
          selected: selected == m,
          onTap: () => onSelect(m),
        );
    return Column(
      children: [
        tile(PayMethod.wave, l.payMethodWave, l.payMethodWaveSub, const PayLogo('assets/images/wave.png')),
        const SizedBox(height: AkSpace.space2),
        tile(PayMethod.orange, l.payMethodOrange, l.payMethodOrangeSub,
            const PayLogo('assets/images/orange-money.png')),
        const SizedBox(height: AkSpace.space2),
        tile(PayMethod.card, l.payMethodCard, l.payMethodCardSub,
            Icon(Icons.credit_card, size: 40, color: context.ak.primary)),
      ],
    );
  }
}

class PayFooter extends StatelessWidget {
  const PayFooter({super.key, required this.total, required this.button, this.secondary});
  final String total;
  final Widget button;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.ak;
    return Container(
      padding: const EdgeInsets.fromLTRB(AkSpace.space4, AkSpace.space3, AkSpace.space4, AkSpace.space4),
      decoration: BoxDecoration(color: p.surfaceRaised, border: Border(top: BorderSide(color: p.border))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AkSpace.space3,
              children: [
                Text(l.payTotalLabel, style: AkText.body.copyWith(color: p.inkSoft)),
                Text(total, key: const Key('pay-total'), style: AkText.amount),
              ],
            ),
          ),
          const SizedBox(height: AkSpace.space3),
          button,
          if (secondary != null) secondary!,
        ],
      ),
    );
  }
}

class PayLogo extends StatelessWidget {
  const PayLogo(this.asset, {super.key});
  final String asset;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(asset, width: 40, height: 40),
      );
}

class PayMethodTile extends StatelessWidget {
  const PayMethodTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final Widget leading;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.ak;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      label: '$title, $subtitle',
      child: InkWell(
        borderRadius: BorderRadius.circular(AkRadius.radiusMd),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: AkSpace.space4, vertical: AkSpace.space3),
          decoration: BoxDecoration(
            color: selected ? p.surfaceTint : p.surfaceRaised,
            borderRadius: BorderRadius.circular(AkRadius.radiusMd),
            border: Border.all(color: selected ? p.primary : p.borderControl, width: selected ? 2 : 1.5),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: AkSpace.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AkText.bodyStrong),
                    Text(subtitle, style: AkText.bodySm.copyWith(color: p.inkSoft)),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? p.onPrimary : p.surfaceRaised,
                  border: Border.all(color: selected ? p.primary : p.borderControl, width: selected ? 7 : 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Attente de confirmation : rappel permanent que « en attente » n'est jamais « payé ».
class PayWaitingView extends StatelessWidget {
  const PayWaitingView({
    super.key,
    required this.methodName,
    required this.notYetPaidBody,
    required this.onChangeMethod,
    this.onReopen,
  });
  final String methodName;
  final String notYetPaidBody;
  final VoidCallback onChangeMethod;

  /// Absent tant qu'aucune page de paiement n'a été ouverte.
  final VoidCallback? onReopen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.ak;
    return ListView(
      padding: const EdgeInsets.all(AkSpace.space4),
      children: [
        const SizedBox(height: AkSpace.space8),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: p.warningBg, shape: BoxShape.circle),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: CircularProgressIndicator(strokeWidth: 3, color: p.warning),
            ),
          ),
        ),
        const SizedBox(height: AkSpace.space4),
        Text(l.payWaitingTitle, style: AkText.titleLg, textAlign: TextAlign.center),
        const SizedBox(height: AkSpace.space2),
        Text(
          l.payWaitingBody(methodName),
          style: AkText.body.copyWith(color: p.inkSoft),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AkSpace.space6),
        AkBanner(
          tone: AkTone.warning,
          icon: Icons.schedule,
          title: l.payNotYetPaidTitle,
          text: notYetPaidBody,
        ),
        const SizedBox(height: AkSpace.space6),
        if (onReopen != null)
          AkButton(
            key: const Key('reopen'),
            kind: AkButtonKind.outline,
            label: l.payReopenButton,
            icon: Icons.open_in_new,
            onPressed: onReopen,
          ),
        const SizedBox(height: AkSpace.space2),
        AkButton(
          key: const Key('change-method'),
          kind: AkButtonKind.text,
          label: l.payChangeMethod,
          onPressed: onChangeMethod,
        ),
      ],
    );
  }
}

/// Délai d'attente écoulé sans réponse définitive du serveur.
class PayTimeoutView extends StatelessWidget {
  const PayTimeoutView({super.key, required this.body, required this.onCheckNow, required this.onLater});
  final String body;
  final VoidCallback onCheckNow;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        Expanded(
          child: StateView(
            icon: Icons.schedule,
            tone: AkTone.warning,
            title: l.payTimeoutTitle,
            body: body,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AkSpace.space4, 0, AkSpace.space4, AkSpace.space4),
          child: Column(
            children: [
              AkButton(key: const Key('check-now'), label: l.payCheckNow, onPressed: onCheckNow),
              const SizedBox(height: AkSpace.space2),
              AkButton(
                key: const Key('check-later'),
                kind: AkButtonKind.text,
                label: l.payCheckLater,
                onPressed: onLater,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
