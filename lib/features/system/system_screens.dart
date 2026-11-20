import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/assets/ak_assets.dart';
import '../../core/providers.dart';
import '../../core/theme/ak_immersive.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/ak_widgets.dart';

/// Écran de lancement de l’application.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _finish();
      } else {
        _controller.forward();
      }
    });
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    ref.read(splashDoneProvider.notifier).complete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final logoDiameter =
        (MediaQuery.sizeOf(context).shortestSide * .34).clamp(88.0, 156.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: akSystemUiStyle(Brightness.dark),
      child: Scaffold(
        backgroundColor: AKColors.deep,
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AKColors.emeraldGradient),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final decodeWidth = (constraints.maxWidth *
                      MediaQuery.devicePixelRatioOf(context))
                  .clamp(360, 1280)
                  .round();
              return Stack(
                fit: StackFit.expand,
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      widthFactor: 1,
                      heightFactor: .52,
                      child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.white,
                            Colors.white,
                            Colors.transparent,
                          ],
                          stops: [0, .35, .78, 1],
                        ).createShader(bounds),
                        child: Image.asset(
                          AkAssets.toubaVision,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, .15),
                          cacheWidth: decodeWidth,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [.58, 1],
                        colors: [Colors.transparent, AKColors.deep],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: SingleChildScrollView(
                      padding: akPagePadding,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (constraints.maxHeight -
                                  MediaQuery.paddingOf(context).vertical -
                                  akPagePadding.vertical)
                              .clamp(0.0, double.infinity),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            const SizedBox(height: AkSpace.space2),
                            AnimatedBuilder(
                              animation: _controller,
                              child: Column(
                                children: [
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AKColors.gold.withValues(
                                            alpha: .20,
                                          ),
                                          blurRadius: AkSpace.space8,
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      AkAssets.logoOfficiel,
                                      width: logoDiameter,
                                      height: logoDiameter,
                                      fit: BoxFit.contain,
                                      excludeFromSemantics: true,
                                    ),
                                  ),
                                  const SizedBox(height: AkSpace.space4),
                                  Text(
                                    'Ahloul Khidmah',
                                    textAlign: TextAlign.center,
                                    style: AkText.headline.copyWith(
                                      color: AKColors.ivory,
                                    ),
                                  ),
                                  Text(
                                    'أهل الخدمة',
                                    textAlign: TextAlign.center,
                                    textDirection: TextDirection.rtl,
                                    style: AkText.title.copyWith(
                                      color: AKColors.goldLight,
                                    ),
                                  ),
                                  const SizedBox(height: AkSpace.space2),
                                  Text(
                                    l.heroSubtitle,
                                    textAlign: TextAlign.center,
                                    style: AkText.bodySm.copyWith(
                                      color: AKColors.ivory,
                                    ),
                                  ),
                                ],
                              ),
                              builder: (context, child) {
                                if (reduceMotion) return child!;
                                final reveal = Curves.easeOutCubic.transform(
                                  (_controller.value / .45).clamp(0.0, 1.0),
                                );
                                return Opacity(
                                  opacity: reveal,
                                  child: Transform.scale(
                                    scale: .94 + reveal * .06,
                                    child: child,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: AkSpace.space8),
                            Semantics(
                              liveRegion: true,
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: AkSpace.space2,
                                children: [
                                  ExcludeSemantics(
                                    child: SizedBox.square(
                                      dimension: 18,
                                      child: reduceMotion
                                          ? const Icon(
                                              Icons.hourglass_empty,
                                              color: AKColors.goldLight,
                                              size: 18,
                                            )
                                          : const CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AKColors.goldLight,
                                            ),
                                    ),
                                  ),
                                  Text(
                                    l.loading,
                                    style: AkText.bodySm.copyWith(
                                      color: AKColors.ivory,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
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
