import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/ak_tokens.dart';
import '../../core/animations/ak_motion.dart';
import '../../core/assets/ak_assets.dart';
import '../../core/providers.dart';
import '../../core/theme/ak_immersive.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/ak_widgets.dart';

/// Écran de démarrage : jamais d'écran blanc pendant le chargement initial.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AKColors.deep,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: akPagePadding,
              child: AkReveal(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Image(
                      image: AssetImage(AkAssets.logo),
                      width: 104,
                      height: 104,
                      semanticLabel: 'Ahloul Khidmah',
                    ),
                    const SizedBox(height: AkSpace.space6),
                    if (!MediaQuery.disableAnimationsOf(context))
                      const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AKColors.gold),
                      ),
                    const SizedBox(height: AkSpace.space3),
                    Semantics(
                      liveRegion: true,
                      child: Text(l.loading,
                          style: const TextStyle(color: AKColors.ivory)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Serveur injoignable au démarrage (et rien en cache pour continuer).
class OfflineScreen extends ConsumerWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: AkErrorState(
          icon: Icons.wifi_off,
          title: l.offlineTitle,
          body: l.offlineBody,
          actionLabel: l.retryButton,
          onAction: () => ref.invalidate(bootstrapProvider),
        ),
      ),
    );
  }
}

/// Maintenance décidée par le serveur (`maintenance.enabled`).
class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cfg = ref.watch(configProvider).value?.config;
    final lang = Localizations.localeOf(context).languageCode;
    final custom = cfg?.maintenanceMessage?.resolve(lang);
    return Scaffold(
      body: SafeArea(
        child: StateView(
          icon: Icons.build_outlined,
          tone: AkTone.warning,
          title: l.maintenanceTitle,
          body: (custom != null && custom.isNotEmpty)
              ? custom
              : l.maintenanceBody,
          actionLabel: l.retryButton,
          onAction: () {
            ref.invalidate(configProvider);
            ref.invalidate(bootstrapProvider);
          },
        ),
      ),
    );
  }
}

/// Version installée < `minAppVersion` : aucun contournement possible.
class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key});

  /// Lien du magasin, fourni à la compilation (`--dart-define=STORE_URL=…`).
  /// Vide tant que l'application n'est pas publiée : le bouton est alors masqué.
  static const storeUrl = String.fromEnvironment('STORE_URL');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: StateView(
          icon: Icons.system_update_alt,
          title: l.updateRequiredTitle,
          body: l.updateRequiredBody,
          actionLabel: storeUrl.isEmpty ? null : l.updateButton,
          onAction: storeUrl.isEmpty
              ? null
              : () => launchUrl(Uri.parse(storeUrl),
                  mode: LaunchMode.externalApplication),
        ),
      ),
    );
  }
}

/// Rubrique inconnue de cette version : repli, jamais une erreur.
class UnknownScreenView extends StatelessWidget {
  const UnknownScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return StateView(
      icon: Icons.upgrade,
      title: l.unknownScreenTitle,
      body: l.unknownScreenBody,
    );
  }
}

/// Rubrique réservée aux membres, ouverte par un visiteur.
class LoginRequiredView extends StatelessWidget {
  const LoginRequiredView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return StateView(
      icon: Icons.lock_outline,
      title: l.loginRequiredTitle,
      body: l.loginRequiredBody,
      actionLabel: l.loginButton,
      onAction: () => context.push('/login'),
    );
  }
}
