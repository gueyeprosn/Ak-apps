import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/ak_theme.dart';
import '../../core/animations/ak_motion.dart';
import '../../core/config/remote_config.dart';
import '../../core/providers.dart';
import '../../core/security/web_allowlist.dart';
import '../../shared/widgets/ak_widgets.dart';
import '../account/account_screen.dart';
import '../barkelu/barkelu_screen.dart';
import '../cotisations/cotisations_screen.dart';
import '../home/home_screen.dart';
import '../system/system_screens.dart';

/// Écrans natifs connus de **cette version** de l'application. Une rubrique
/// dont le `screen` n'est pas ici mène à l'écran de repli : le serveur peut
/// annoncer des rubriques plus récentes sans casser une ancienne version.
final Map<String, Widget Function()> nativeScreens = {
  'home': () => const HomeScreen(),
  'cotisations': () => const CotisationsScreen(),
  'barkelu': () => const BarkeluScreen(),
  'account': () => const AccountScreen(),
};

IconData _iconFor(String? name) => switch (name) {
      'home' => Icons.home_outlined,
      'wallet' => Icons.account_balance_wallet_outlined,
      'shop' => Icons.shopping_bag_outlined,
      'person' => Icons.person_outline,
      _ => Icons.circle_outlined,
    };

IconData _selectedIconFor(String? name) => switch (name) {
      'home' => Icons.home,
      'wallet' => Icons.account_balance_wallet,
      'shop' => Icons.shopping_bag,
      'person' => Icons.person,
      _ => Icons.circle,
    };

/// Coque de navigation : la barre d'onglets est **décrite par la configuration
/// distante** (rubriques, libellés FR/AR, drapeaux), jamais codée en dur.
class TabShell extends ConsumerWidget {
  const TabShell({super.key, required this.tabId});
  final String tabId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg =
        ref.watch(configProvider).value?.config ?? MobileConfig.embedded;
    final tabs = cfg.visibleTabs;
    if (tabs.isEmpty)
      return const Scaffold(body: SafeArea(child: UnknownScreenView()));
    final lang = Localizations.localeOf(context).languageCode;
    var index = tabs.indexWhere((t) => t.id == tabId);
    if (index < 0) index = 0;
    final tab = tabs[index];
    return Scaffold(
      body: AkReveal(
          key: ValueKey(tab.id), child: _TabContent(tab: tab, cfg: cfg)),
      bottomNavigationBar: tabs.length < 2
          ? null
          : AkBottomNavigation(
              selectedIndex: index,
              onSelected: (i) => context.go('/t/${tabs[i].id}'),
              destinations: [
                for (final t in tabs)
                  NavigationDestination(
                    icon: Icon(_iconFor(t.icon), color: context.ak.inkSoft),
                    selectedIcon: Icon(_selectedIconFor(t.icon),
                        color: context.ak.primary),
                    label: t.label.resolve(lang),
                  ),
              ],
            ),
    );
  }
}

class AkBottomNavigation extends StatelessWidget {
  const AkBottomNavigation(
      {super.key,
      required this.selectedIndex,
      required this.onSelected,
      required this.destinations});

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.ak.border)),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          height: MediaQuery.textScalerOf(context).scale(12) >= 20 ? 88 : 68,
          animationDuration: AKMotion.duration(context, AKMotion.press),
          onDestinationSelected: onSelected,
          destinations: destinations,
        ),
      );
}

class _TabContent extends ConsumerWidget {
  const _TabContent({required this.tab, required this.cfg});
  final TabConfig tab;
  final MobileConfig cfg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (tab.requiresAuth && auth is! AuthLoggedIn)
      return const SafeArea(child: LoginRequiredView());

    switch (tab.type) {
      case TabType.native:
        final build = nativeScreens[tab.screen];
        return build == null
            ? const SafeArea(child: UnknownScreenView())
            : build();
      case TabType.webview:
      case TabType.external:
        // WebView sécurisée : étape suivante. En attendant, la page s'ouvre
        // dans le navigateur, **uniquement** si l'URL est autorisée.
        if (!isAllowedWebUrl(tab.url, cfg.webAllowlist)) {
          return const SafeArea(child: UnknownScreenView());
        }
        return SafeArea(
          child: StateView(
            icon: Icons.open_in_new,
            title:
                tab.label.resolve(Localizations.localeOf(context).languageCode),
            body: Uri.parse(tab.url!).host,
            actionLabel:
                tab.label.resolve(Localizations.localeOf(context).languageCode),
            onAction: () => launchUrl(Uri.parse(tab.url!),
                mode: LaunchMode.externalApplication),
          ),
        );
      case TabType.unknown:
        return const SafeArea(child: UnknownScreenView());
    }
  }
}
