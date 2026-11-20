import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/providers.dart';
import '../../core/security/web_allowlist.dart';
import '../../core/theme/ak_immersive.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/ak_service_tile.dart';
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
    final origin = Uri.parse(ref.watch(appEnvProvider).apiBaseUrl);
    final photoUrl = Uri.tryParse(member.photoUrl ?? '');
    final resolvedPhoto =
        photoUrl == null ? null : origin.resolveUri(photoUrl).toString();
    final photo = member.photoUrl?.isNotEmpty == true &&
            isAllowedWebUrl(resolvedPhoto, [origin.host])
        ? ResizeImage(NetworkImage(resolvedPhoto!),
            width: 192, allowUpscaling: false)
        : null;
    final lang = ref.watch(languagePrefProvider);
    final theme = ref.watch(themePrefProvider);
    final version = ref.watch(installedVersionProvider);
    final stacked = MediaQuery.textScalerOf(context).scale(14) >= 21;
    final direction = stacked ? Axis.vertical : Axis.horizontal;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AkLayout.contentMax),
          child: ListView(
            padding: akPagePadding,
            children: [
              AkHeading(title: l.accountTitle),
              const SizedBox(height: AkSpace.space4),
              AkCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: p.surfaceTint,
                      foregroundImage: photo,
                      onForegroundImageError: photo == null
                          ? null
                          : (error, stackTrace) {
                              // Les initiales restent visibles si la photo ne peut pas être chargée.
                            },
                      child: ExcludeSemantics(
                        child: Text(member.initials,
                            style: AkText.title.copyWith(color: p.primary)),
                      ),
                    ),
                    const SizedBox(width: AkSpace.space4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member.name, style: AkText.title),
                          const SizedBox(height: AkSpace.space1),
                          if (member.isActive)
                            StatusChip(
                                label: l.memberActive,
                                tone: AkTone.success,
                                icon: Icons.check_circle_outline),
                          if (member.memberNumber != null)
                            Text('N° ${member.memberNumber}',
                                style:
                                    AkText.bodySm.copyWith(color: p.inkSoft)),
                          if (member.tel.isNotEmpty)
                            Text(member.tel,
                                textDirection: TextDirection.ltr,
                                style:
                                    AkText.bodySm.copyWith(color: p.inkSoft)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AkSpace.space3),
              AkCard(
                padding: EdgeInsets.zero,
                child: AkServiceTile(
                  icon: Icons.badge_outlined,
                  label: l.actionCard,
                  onTap: () => context.push('/card'),
                ),
              ),
              const SizedBox(height: AkSpace.space6),
              Text(l.languageLabel,
                  style: AkText.label.copyWith(color: p.inkSoft)),
              const SizedBox(height: AkSpace.space2),
              SegmentedButton<String>(
                key: const Key('lang-selector'),
                direction: direction,
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: p.surfaceTint,
                  selectedForegroundColor: p.primary,
                  foregroundColor: p.ink,
                  side: BorderSide(color: p.borderControl),
                  textStyle: AkText.label,
                  minimumSize: const Size(0, AkSize.sizeTouch),
                ),
                segments: [
                  ButtonSegment(value: 'system', label: Text(l.langSystem)),
                  const ButtonSegment(value: 'fr', label: Text('Français')),
                  const ButtonSegment(value: 'ar', label: Text('العربية')),
                ],
                selected: {lang ?? 'system'},
                onSelectionChanged: (s) {
                  final v = s.first;
                  ref
                      .read(languagePrefProvider.notifier)
                      .set(v == 'system' ? null : v);
                },
              ),
              const SizedBox(height: AkSpace.space5),
              Text(l.appearanceLabel,
                  style: AkText.label.copyWith(color: p.inkSoft)),
              const SizedBox(height: AkSpace.space2),
              SegmentedButton<ThemeMode>(
                key: const Key('theme-selector'),
                direction: direction,
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: p.surfaceTint,
                  selectedForegroundColor: p.primary,
                  foregroundColor: p.ink,
                  side: BorderSide(color: p.borderControl),
                  textStyle: AkText.label,
                  minimumSize: const Size(0, AkSize.sizeTouch),
                ),
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
              if (ref.watch(pushPlatformProvider).isAvailable) ...[
                const SizedBox(height: AkSpace.space5),
                const PushSettings(),
              ],
              const SizedBox(height: AkSpace.space5),
              AkHeading(title: l.accountAccessHeading, section: true),
              const SizedBox(height: AkSpace.space2),
              Text(l.accountWebHint,
                  style: AkText.bodySm.copyWith(color: p.inkSoft)),
              const SizedBox(height: AkSpace.space2),
              OfficialPageButton(
                  page: OfficialPage.account, label: l.accountOpenWeb),
              const SizedBox(height: AkSpace.space2),
              OfficialPageButton(
                  page: OfficialPage.history,
                  label: l.historyOpenWeb,
                  icon: Icons.history),
              const SizedBox(height: AkSpace.space2),
              OfficialPageButton(
                  page: OfficialPage.support,
                  label: l.accountContactSupport,
                  icon: Icons.support_agent),
              const SizedBox(height: AkSpace.space5),
              AkButton(
                key: const Key('logout'),
                label: l.logoutButton,
                kind: AkButtonKind.outline,
                icon: Icons.logout,
                onPressed: () async {
                  final pushToken =
                      ref.read(pushControllerProvider.notifier).deviceToken;
                  await ref
                      .read(authControllerProvider.notifier)
                      .logout(pushToken: pushToken);
                  if (context.mounted) context.go('/t/home');
                },
              ),
              const SizedBox(height: AkSpace.space4),
              Center(
                  child: Text(l.versionLabel(version),
                      style: AkText.caption.copyWith(color: p.inkSoft))),
            ],
          ),
        ),
      ),
    );
  }
}
