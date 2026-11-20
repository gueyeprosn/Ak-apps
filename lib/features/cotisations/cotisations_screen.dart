import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/auth/member.dart';
import '../../core/format.dart';
import '../../core/errors/error_messages.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/ak_widgets.dart';
import '../../shared/widgets/official_page_button.dart';

/// Historique des versements et accès au paiement de cotisation.
class CotisationsScreen extends ConsumerWidget {
  const CotisationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final auth = ref.watch(authControllerProvider);
    if (auth is! AuthLoggedIn) return const SizedBox.shrink();
    final versements = auth.member.versements;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          try {
            await ref.read(authControllerProvider.notifier).reloadProfile();
          } catch (error) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messageForError(l, error))));
          }
        },
        child: ListView(
          padding: akPagePadding,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            AkHeading(title: l.versementsTitle),
            const SizedBox(height: AkSpace.space4),
            AkButton(
              key: const Key('open-pay'),
              icon: Icons.account_balance_wallet_outlined,
              label: l.actionPay,
              onPressed: () => context.push('/pay'),
            ),
            const SizedBox(height: AkSpace.space2),
            OfficialPageButton(page: OfficialPage.history, label: l.historyOpenWeb),
            const SizedBox(height: AkSpace.space4),
            if (versements.isEmpty)
              SizedBox(
                height: 360,
                child: StateView(
                  icon: Icons.account_balance_wallet_outlined,
                  title: l.noVersements,
                  body: l.noVersementsBody,
                ),
              )
            else
              AkCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < versements.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: context.ak.border),
                      _Row(v: versements[i], lang: lang),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.v, required this.lang});
  final Versement v;
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(periodeLabel(v.periode, lang), style: AkText.bodyStrong),
                  Text(formatAmount(v.montant, lang), style: AkText.bodySm.copyWith(color: p.inkSoft)),
                ],
              ),
            ),
            const SizedBox(width: AkSpace.space2),
            Flexible(
              child: StatusChip(
                label: v.isPaid ? l.paidLabel : l.statusPending,
                tone: v.isPaid ? AkTone.success : AkTone.warning,
                icon: v.isPaid ? Icons.check_circle_outline : Icons.schedule,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
