import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/animations/ak_motion.dart';
import '../../core/assets/ak_assets.dart';
import '../../core/auth/member.dart';
import '../../core/config/remote_config.dart';
import '../../core/providers.dart';
import '../../core/security/web_allowlist.dart';
import '../../core/theme/ak_immersive.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/ak_brand_app_bar.dart';
import '../../shared/widgets/ak_photo_hero.dart';
import '../../shared/widgets/ak_widgets.dart';
import '../../shared/widgets/official_page_button.dart';
import '../notifications/presentation/push_controller.dart';
import '../notifications/presentation/push_settings.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.ak;
    final auth = ref.watch(authControllerProvider);
    if (auth is! AuthLoggedIn) return const SizedBox.shrink();
    final member = auth.member;
    final version = ref.watch(installedVersionProvider);
    final tabs =
        (ref.watch(configProvider).value?.config ?? MobileConfig.embedded)
            .visibleTabs;
    final contributions = tabs
        .where(
            (tab) => tab.type == TabType.native && tab.screen == 'cotisations')
        .firstOrNull;
    final shop = tabs
        .where((tab) => tab.type == TabType.native && tab.screen == 'barkelu')
        .firstOrNull;

    return Scaffold(
      appBar: AkBrandAppBar(
        context: context,
        title: l.accountTitle,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AkLayout.contentMax),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: AkPhotoHero(
                    asset: AkAssets.toubaHero,
                    alignment: const Alignment(0, .16),
                    child: _ProfileIdentity(member: member),
                  ),
                ),
                SliverPadding(
                  padding: akPagePadding.copyWith(top: AkSpace.space2),
                  sliver: SliverList.list(
                    children: [
                      AkReveal(
                        stage: 1,
                        stagger: true,
                        child: AkRaisedCard(
                          child: Column(
                            children: [
                              _ProfileMenuItem(
                                icon: Icons.badge_outlined,
                                label: l.actionCard,
                                onTap: () => context.push('/card'),
                              ),
                              if (contributions != null) ...[
                                const Divider(height: 1),
                                _ProfileMenuItem(
                                  icon: Icons.payments_outlined,
                                  label: l.contributionsLabel,
                                  onTap: () =>
                                      context.go('/t/${contributions.id}'),
                                ),
                              ],
                              if (shop != null) ...[
                                const Divider(height: 1),
                                _ProfileMenuItem(
                                  icon: Icons.shopping_bag_outlined,
                                  label: l.actionBarkelu,
                                  onTap: () => context.go('/t/${shop.id}'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (ref.watch(pushPlatformProvider).isAvailable) ...[
                        const SizedBox(height: AkSpace.space4),
                        const PushSettings(),
                      ],
                      const SizedBox(height: AkSpace.space4),
                      const AkReveal(
                        stage: 2,
                        stagger: true,
                        child: _AccountPreferences(),
                      ),
                      const SizedBox(height: AkSpace.space4),
                      AkRaisedCard(
                        child: Padding(
                          padding: const EdgeInsets.all(AkSpace.space4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AkHeading(
                                  title: l.accountAccessHeading, section: true),
                              const SizedBox(height: AkSpace.space1),
                              Text(
                                l.accountWebHint,
                                style: AkText.bodySm.copyWith(color: p.inkSoft),
                              ),
                              const SizedBox(height: AkSpace.space3),
                              OfficialPageButton(
                                page: OfficialPage.account,
                                label: l.accountOpenWeb,
                              ),
                              const SizedBox(height: AkSpace.space2),
                              OfficialPageButton(
                                page: OfficialPage.history,
                                label: l.historyOpenWeb,
                                icon: Icons.history,
                              ),
                              const SizedBox(height: AkSpace.space2),
                              OfficialPageButton(
                                page: OfficialPage.support,
                                label: l.accountContactSupport,
                                icon: Icons.support_agent,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AkSpace.space4),
                      AkAnimatedButton(
                        key: const Key('logout'),
                        builder: (states) => TextButton.icon(
                          statesController: states,
                          icon: const Icon(Icons.logout),
                          label:
                              Text(l.logoutButton, textAlign: TextAlign.center),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, AkSize.sizeTouch),
                            padding: const EdgeInsets.all(AkSpace.space3),
                            foregroundColor: p.danger,
                            backgroundColor: p.dangerBg,
                            textStyle: AkText.button,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AkRadius.radiusMd),
                            ),
                          ),
                          onPressed: () async {
                            final pushToken = ref
                                .read(pushControllerProvider.notifier)
                                .deviceToken;
                            await ref
                                .read(authControllerProvider.notifier)
                                .logout(pushToken: pushToken);
                            if (context.mounted) context.go('/t/home');
                          },
                        ),
                      ),
                      const SizedBox(height: AkSpace.space3),
                      Text(
                        l.versionLabel(version),
                        textAlign: TextAlign.center,
                        style: AkText.caption.copyWith(color: p.inkSoft),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileIdentity extends ConsumerWidget {
  const _ProfileIdentity({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final origin = Uri.parse(ref.watch(appEnvProvider).apiBaseUrl);
    final photoUrl = Uri.tryParse(member.photoUrl ?? '');
    final resolvedPhoto =
        photoUrl == null ? null : origin.resolveUri(photoUrl).toString();
    final photo = member.photoUrl?.isNotEmpty == true &&
            isAllowedWebUrl(resolvedPhoto, [origin.host])
        ? ResizeImage(NetworkImage(resolvedPhoto!),
            width: 192, allowUpscaling: false)
        : null;
    final memberNumber = member.memberNumber?.toString() ?? member.id;

    return Row(
      children: [
        ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AKColors.goldLight, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: CircleAvatar(
                radius: 30,
                foregroundImage: photo,
                onForegroundImageError:
                    photo == null ? null : (error, stack) {},
                backgroundColor: AKColors.deep,
                foregroundColor: AKColors.ivory,
                child: Padding(
                  padding: const EdgeInsets.all(AkSpace.space2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(member.initials, style: AkText.titleLg),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AkSpace.space4),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  member.name,
                  style: AkText.titleLg.copyWith(color: AKColors.ivory),
                ),
              ),
              if (memberNumber.isNotEmpty)
                Text(
                  memberNumber,
                  textDirection: TextDirection.ltr,
                  style: AkText.label.copyWith(color: AKColors.goldLight),
                ),
              if (member.isActive) ...[
                const SizedBox(height: AkSpace.space2),
                StatusChip(
                  label: l.memberActive,
                  tone: AkTone.success,
                  icon: Icons.check_circle_outline,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountPreferences extends ConsumerWidget {
  const _AccountPreferences();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.ak;
    final lang = ref.watch(languagePrefProvider);
    final theme = ref.watch(themePrefProvider);
    final buttonStyle = SegmentedButton.styleFrom(
      selectedBackgroundColor: p.surfaceTint,
      selectedForegroundColor: p.primary,
      foregroundColor: p.ink,
      side: BorderSide(color: p.borderControl),
      textStyle: AkText.label,
      minimumSize: const Size(0, AkSize.sizeTouch),
    );

    return AkRaisedCard(
      child: Padding(
        padding: const EdgeInsets.all(AkSpace.space4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 270 ||
                MediaQuery.textScalerOf(context).scale(14) >= 21;
            final direction = stacked ? Axis.vertical : Axis.horizontal;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AkHeading(title: l.languageLabel, section: true),
                const SizedBox(height: AkSpace.space2),
                SegmentedButton<String>(
                  key: const Key('lang-selector'),
                  direction: direction,
                  showSelectedIcon: false,
                  style: buttonStyle,
                  segments: [
                    ButtonSegment(value: 'system', label: Text(l.langSystem)),
                    const ButtonSegment(value: 'fr', label: Text('Français')),
                    const ButtonSegment(value: 'ar', label: Text('العربية')),
                  ],
                  selected: {lang ?? 'system'},
                  onSelectionChanged: (s) {
                    final value = s.first;
                    ref
                        .read(languagePrefProvider.notifier)
                        .set(value == 'system' ? null : value);
                  },
                ),
                const SizedBox(height: AkSpace.space4),
                AkHeading(title: l.appearanceLabel, section: true),
                const SizedBox(height: AkSpace.space2),
                SegmentedButton<ThemeMode>(
                  key: const Key('theme-selector'),
                  direction: direction,
                  showSelectedIcon: false,
                  style: buttonStyle,
                  segments: [
                    ButtonSegment(
                        value: ThemeMode.system, label: Text(l.themeSystem)),
                    ButtonSegment(
                        value: ThemeMode.light, label: Text(l.themeLight)),
                    ButtonSegment(
                        value: ThemeMode.dark, label: Text(l.themeDark)),
                  ],
                  selected: {theme},
                  onSelectionChanged: (s) =>
                      ref.read(themePrefProvider.notifier).set(s.first),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.ak;
    return AkAnimatedButton(
      builder: (controller) => ListTile(
        statesController: controller,
        minTileHeight: AkSize.sizeTouch + AkSpace.space2,
        leading: DecoratedBox(
          decoration: BoxDecoration(
            color: p.surfaceTint,
            borderRadius: BorderRadius.circular(AkRadius.radiusMd),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AkSpace.space2),
            child: Icon(icon, size: 20, color: p.primary),
          ),
        ),
        title: Text(label, style: AkText.bodyStrong),
        trailing: Icon(Icons.chevron_right, color: p.inkSoft),
        onTap: onTap,
      ),
    );
  }
}
