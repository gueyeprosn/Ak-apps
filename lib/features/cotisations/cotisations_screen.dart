import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/animations/ak_motion.dart';
import '../../core/auth/member.dart';
import '../../core/errors/error_messages.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme/ak_immersive.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/ak_brand_app_bar.dart';
import '../../shared/widgets/ak_widgets.dart';
import '../../shared/widgets/official_page_button.dart';

class CotisationsScreen extends ConsumerWidget {
  const CotisationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final auth = ref.watch(authControllerProvider);
    final appBar = AkBrandAppBar(
      context: context,
      title: l.versementsTitle,
      centerTitle: true,
    );
    if (auth is! AuthLoggedIn) {
      return Scaffold(
        appBar: appBar,
        body: Center(
          child: AkButton(
            label: l.loginButton,
            expand: false,
            onPressed: () => context.push('/login'),
          ),
        ),
      );
    }

    final versements = auth.member.versements;
    final period = currentPeriode(DateTime.now());
    final current = auth.member.versementFor(period);
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AkLayout.contentMax),
            child: RefreshIndicator(
              onRefresh: () async {
                try {
                  await ref
                      .read(authControllerProvider.notifier)
                      .reloadProfile();
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(messageForError(l, error))),
                  );
                }
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: akPagePadding.copyWith(bottom: AkSpace.space4),
                    sliver: SliverToBoxAdapter(
                      child: AkReveal(
                        child: _CurrentContribution(
                          periodLabel: periodeLabel(period, lang),
                          amount: current == null
                              ? null
                              : formatAmount(current.montant, lang),
                          paid: current?.isPaid,
                        ),
                      ),
                    ),
                  ),
                  if (versements.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AkSpace.space4),
                      sliver: SliverToBoxAdapter(
                        child: AkRaisedCard(
                          child: Padding(
                            padding: const EdgeInsets.all(AkSpace.space4),
                            child: AkHeading(
                              title: l.noVersements,
                              subtitle: l.noVersementsBody,
                              section: true,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AkSpace.space4),
                      sliver: SliverList.separated(
                        itemCount: versements.length,
                        itemBuilder: (context, index) => _VersementRow(
                            versement: versements[index], lang: lang),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AkSpace.space2),
                      ),
                    ),
                  SliverPadding(
                    padding: akPagePadding,
                    sliver: SliverToBoxAdapter(
                      child: OfficialPageButton(
                        page: OfficialPage.history,
                        label: l.historyOpenWeb,
                        icon: Icons.history,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentContribution extends StatelessWidget {
  const _CurrentContribution({
    required this.periodLabel,
    required this.amount,
    required this.paid,
  });

  final String periodLabel;
  final String? amount;
  final bool? paid;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isPaid = paid;

    return AkRaisedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: AKColors.emeraldGradient,
              border:
                  Border(bottom: BorderSide(color: AKColors.gold, width: 2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AkSpace.space4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ContributionIcon(
                    icon: Icons.payments_outlined,
                    foreground: AKColors.goldLight,
                    background: AKColors.primaryMedium,
                  ),
                  const SizedBox(width: AkSpace.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            l.dueCardTitle(periodLabel),
                            style: AkText.bodyStrong
                                .copyWith(color: AKColors.ivory),
                          ),
                        ),
                        if (amount case final value?) ...[
                          const SizedBox(height: AkSpace.space1),
                          Text(
                            value,
                            style:
                                AkText.amount.copyWith(color: AKColors.ivory),
                          ),
                        ],
                        if (isPaid != null) ...[
                          const SizedBox(height: AkSpace.space2),
                          _PaymentStatus(paid: isPaid),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AkSpace.space3),
            child: AkButton(
              key: const Key('open-pay'),
              kind: AkButtonKind.gold,
              icon: Icons.payment_outlined,
              label: l.actionPay,
              onPressed: () => context.push('/pay'),
            ),
          ),
        ],
      ),
    );
  }
}

class _VersementRow extends StatelessWidget {
  const _VersementRow({required this.versement, required this.lang});

  final Versement versement;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final p = context.ak;
    return AkRaisedCard(
      child: Padding(
        padding: const EdgeInsets.all(AkSpace.space3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ContributionIcon(
              icon: Icons.calendar_today_outlined,
              foreground: p.primary,
              background: p.surfaceTint,
            ),
            const SizedBox(width: AkSpace.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    periodeLabel(versement.periode, lang),
                    style: AkText.bodyStrong.copyWith(color: p.ink),
                  ),
                  const SizedBox(height: AkSpace.space1),
                  Wrap(
                    spacing: AkSpace.space2,
                    runSpacing: AkSpace.space1,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        formatAmount(versement.montant, lang),
                        style: AkText.bodySm.copyWith(color: p.inkSoft),
                      ),
                      _PaymentStatus(paid: versement.isPaid),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContributionIcon extends StatelessWidget {
  const _ContributionIcon({
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AkRadius.radiusMd),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AkSpace.space2),
            child: Icon(icon, color: foreground, size: AkSize.sizeIcon),
          ),
        ),
      );
}

class _PaymentStatus extends StatelessWidget {
  const _PaymentStatus({required this.paid});

  final bool paid;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return StatusChip(
      label: paid ? l.paidLabel : l.statusPending,
      tone: paid ? AkTone.success : AkTone.warning,
      icon: paid ? Icons.check_circle_outline : Icons.schedule,
    );
  }
}
