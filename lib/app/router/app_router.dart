import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/ak_motion.dart';
import '../../core/config/remote_config.dart';
import '../../core/providers.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/pin_setup_screen.dart';
import '../../features/card/card_screen.dart';
import '../../features/design_catalogue/design_catalogue_screen.dart';
import '../../features/media/media_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/payment/pay_screen.dart';
import '../../features/public_pay/adhesion_screen.dart';
import '../../features/public_pay/donation_screen.dart';
import '../../features/shell/tab_shell.dart';
import '../../features/system/system_screens.dart';

const _gateRoutes = {'/splash', '/offline', '/maintenance', '/update-required'};

/// Décide où se trouve l'utilisateur d'après l'état global : chargement,
/// hors ligne, maintenance, version trop ancienne, puis navigation normale.
String? computeRedirect(Ref ref, String location) {
  final boot = ref.read(bootstrapProvider);
  if (boot.isLoading) return location == '/splash' ? null : '/splash';
  if (boot.hasError) return location == '/offline' ? null : '/offline';

  final cfg = ref.read(configProvider).value?.config ?? MobileConfig.embedded;
  if (cfg.maintenanceEnabled) {
    return location == '/maintenance' ? null : '/maintenance';
  }
  if (compareVersions(ref.read(installedVersionProvider), cfg.minAppVersion) <
      0) {
    return location == '/update-required' ? null : '/update-required';
  }

  final firstTab = cfg.visibleTabs.isEmpty ? 'home' : cfg.visibleTabs.first.id;
  final auth = ref.read(authControllerProvider);
  if (_gateRoutes.contains(location)) {
    if (auth is AuthLoggedOut && !ref.read(onboardingPrefProvider)) {
      return '/onboarding';
    }
    return '/t/$firstTab';
  }
  if (location == '/onboarding' &&
      (auth is AuthLoggedIn || ref.read(onboardingPrefProvider))) {
    return '/t/$firstTab';
  }
  if (location == '/login' && auth is AuthLoggedIn) return '/t/$firstTab';
  if (location == '/pin-setup' && ref.read(pinSetupSessionProvider) == null) {
    return '/login';
  }
  // Le paiement exige une session membre.
  if ((location == '/pay' || location == '/card') && auth is! AuthLoggedIn) {
    return '/login';
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  void bump(Object? a, Object? b) => refresh.value++;
  ref.listen(authControllerProvider, bump);
  ref.listen(bootstrapProvider, bump);
  ref.listen(configProvider, bump);
  ref.listen(onboardingPrefProvider, bump);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) => computeRedirect(ref, state.matchedLocation),
    routes: [
      if (kDebugMode)
        GoRoute(
          path: '/design-catalogue',
          pageBuilder: (context, state) => AkPageTransition<void>(
            context: context,
            pageKey: state.pageKey,
            child: const DesignCatalogueScreen(),
          ),
        ),
      GoRoute(
          path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(
          path: '/offline', builder: (context, state) => const OfflineScreen()),
      GoRoute(
          path: '/maintenance',
          builder: (context, state) => const MaintenanceScreen()),
      GoRoute(
          path: '/update-required',
          builder: (context, state) => const UpdateRequiredScreen()),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => AkPageTransition<void>(
          context: context,
          pageKey: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/media',
        pageBuilder: (context, state) => AkPageTransition<void>(
          context: context,
          pageKey: state.pageKey,
          child: const MediaScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => AkPageTransition<void>(
          context: context,
          pageKey: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/pin-setup',
        pageBuilder: (context, state) => AkPageTransition<void>(
          context: context,
          pageKey: state.pageKey,
          child: const PinSetupScreen(),
        ),
      ),
      GoRoute(
        path: '/pay',
        pageBuilder: (context, state) => AkPageTransition<void>(
          context: context,
          pageKey: state.pageKey,
          child: const PayScreen(),
        ),
      ),
      GoRoute(
        path: '/card',
        pageBuilder: (context, state) => AkPageTransition<void>(
          context: context,
          pageKey: state.pageKey,
          child: const CardScreen(),
        ),
      ),
      // Publics : on peut adhérer ou donner sans compte.
      GoRoute(
        path: '/join',
        pageBuilder: (context, state) => AkPageTransition<void>(
          context: context,
          pageKey: state.pageKey,
          child: const AdhesionScreen(),
        ),
      ),
      GoRoute(
        path: '/give',
        pageBuilder: (context, state) => AkPageTransition<void>(
          context: context,
          pageKey: state.pageKey,
          child: const DonationScreen(),
        ),
      ),
      GoRoute(
        path: '/t/:id',
        builder: (_, state) =>
            TabShell(tabId: state.pathParameters['id'] ?? 'home'),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
