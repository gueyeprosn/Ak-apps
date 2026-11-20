import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/animations/ak_motion.dart';
import '../../core/assets/ak_assets.dart';
import '../../core/auth/member.dart';
import '../../core/config/remote_config.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme/ak_immersive.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/ak_immersive_header.dart';
import '../../shared/widgets/ak_widgets.dart';
import '../../shared/widgets/ak_service_tile.dart';
import '../../shared/widgets/official_page_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.now});

  /// Injectable pour les tests (période courante).
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final auth = ref.watch(authControllerProvider);
    final member = auth is AuthLoggedIn ? auth.member : null;
    final cfg =
        ref.watch(configProvider).value?.config ?? MobileConfig.embedded;
    final tabs = cfg.visibleTabs;
    final contributionsTab = tabs
        .where(
            (tab) => tab.type == TabType.native && tab.screen == 'cotisations')
        .firstOrNull;
    final barkeluTab = tabs
        .where((tab) => tab.type == TabType.native && tab.screen == 'barkelu')
        .firstOrNull;

    final period = currentPeriode(now ?? DateTime.now());
    final payment = member?.versementFor(period);
    final showCardShortcut =
        payment == null || (!payment.isPaid && contributionsTab != null);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AkLayout.contentMax),
          child: ListView(
            padding: akPagePadding,
            children: [
              Row(
                children: [
                  Image.asset(AkAssets.logo,
                      width: 44, height: 44, excludeFromSemantics: true),
                  const SizedBox(width: AkSpace.space3),
                  Expanded(
                      child: Text('Ahloul Khidmah', style: AkText.bodyStrong)),
                ],
              ),
              const SizedBox(height: AkSpace.space5),
              if (member == null) ...[
                AkReveal(
                  child: AkImmersiveHeader(
                    asset: AkAssets.toubaHero,
                    title: l.heroTitle,
                    subtitle: l.heroSubtitle,
                    photoHeight: 152,
                    child: AkButton(
                      key: const Key('home-join'),
                      label: l.homeJoin,
                      kind: AkButtonKind.gold,
                      onPressed: () => context.push('/join'),
                    ),
                  ),
                ),
                const SizedBox(height: AkSpace.space4),
                AkSecondaryButton(
                  key: const Key('home-give'),
                  label: l.homeContribute,
                  icon: Icons.favorite_border,
                  onPressed: () => context.push('/give'),
                ),
                const SizedBox(height: AkSpace.space2),
                AkButton(
                  key: const Key('home-login'),
                  kind: AkButtonKind.text,
                  label: l.loginButton,
                  icon: Icons.login,
                  onPressed: () => context.push('/login'),
                ),
              ] else ...[
                AkReveal(
                  child: AkImmersiveHeader(
                    asset: AkAssets.toubaHero,
                    title: l.homeGreeting(
                        member.prenoms.isEmpty ? member.name : member.prenoms),
                    subtitle: l.heroSubtitle,
                    photoHeight: 100,
                  ),
                ),
                const SizedBox(height: AkSpace.space4),
                AkReveal(
                  stage: 1,
                  child: AkContributionCard(
                    payment: payment,
                    period: period,
                    contributionsTabId: contributionsTab?.id,
                  ),
                ),
                const SizedBox(height: AkSpace.space5),
                AkReveal(
                    stage: 2,
                    child: AkCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          if (showCardShortcut) ...[
                            AkServiceTile(
                                icon: Icons.badge_outlined,
                                label: l.actionCard,
                                onTap: () => context.push('/card')),
                            const Divider(height: 1),
                          ],
                          if (contributionsTab != null) ...[
                            AkServiceTile(
                              icon: Icons.account_balance_wallet_outlined,
                              label: l.versementsTitle,
                              onTap: () =>
                                  context.go('/t/${contributionsTab.id}'),
                            ),
                            const Divider(height: 1),
                          ],
                          AkServiceTile(
                              icon: Icons.favorite_border,
                              label: l.actionContribute,
                              onTap: () => context.push('/give')),
                          if (barkeluTab != null) ...[
                            const Divider(height: 1),
                            AkServiceTile(
                              icon: Icons.shopping_bag_outlined,
                              label: l.actionBarkelu,
                              onTap: () => context.go('/t/${barkeluTab.id}'),
                            ),
                          ],
                        ],
                      ),
                    )),
              ],
              const SizedBox(height: AkSpace.space4),
              OfficialPageButton(
                  page: OfficialPage.media,
                  label: l.mediaOpen,
                  icon: Icons.photo_library_outlined),
              const SizedBox(height: AkSpace.space3),
              AkCard(
                padding: EdgeInsets.zero,
                child: AkServiceTile(
                  icon: Icons.photo_library_outlined,
                  label: l.galleryOpen,
                  onTap: () => context.push('/media'),
                ),
              ),
              if (kDebugMode)
                AkButton(
                  label: 'Khidmah Immersive',
                  kind: AkButtonKind.text,
                  icon: Icons.design_services_outlined,
                  onPressed: () => context.push('/design-catalogue'),
                ),
              for (final message in cfg.messages) ...[
                const SizedBox(height: AkSpace.space4),
                AkBanner(
                  tone:
                      message.level == 'warning' ? AkTone.warning : AkTone.info,
                  icon: message.level == 'warning'
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline,
                  text: message.text.resolve(lang),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AkContributionCard extends StatelessWidget {
  const AkContributionCard(
      {super.key,
      required this.payment,
      required this.period,
      required this.contributionsTabId});

  final Versement? payment;
  final String period;
  final String? contributionsTabId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final payment = this.payment;
    final (label, tone, icon) = switch (payment?.isPaid) {
      null => (l.statusDue, AkTone.warning, Icons.schedule),
      true => (l.statusUpToDate, AkTone.success, Icons.check_circle_outline),
      false => (l.statusPending, AkTone.warning, Icons.schedule),
    };
    final (action, onTap) = switch (payment?.isPaid) {
      null => (l.actionPay, () => context.push('/pay')),
      false when contributionsTabId != null => (
          l.versementsTitle,
          () => context.go('/t/$contributionsTabId')
        ),
      _ => (l.actionCard, () => context.push('/card')),
    };

    return AkCard(
      padding: const EdgeInsets.all(AkSpace.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(label: label, tone: tone, icon: icon),
          const SizedBox(height: AkSpace.space3),
          Text(l.dueCardTitle(periodeLabel(period, lang)), style: AkText.title),
          if (payment != null) ...[
            const SizedBox(height: AkSpace.space1),
            Text(formatAmount(payment.montant, lang),
                style: AkText.body.copyWith(color: context.ak.inkSoft)),
          ],
          const SizedBox(height: AkSpace.space4),
          AkButton(label: action, onPressed: onTap),
        ],
      ),
    );
  }
}
