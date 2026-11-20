import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/animations/ak_motion.dart';
import '../../core/assets/ak_assets.dart';
import '../../core/providers.dart';
import '../../core/theme/ak_immersive.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/ak_photo_hero.dart';
import '../../shared/widgets/ak_widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _scroll = ScrollController();
  var _step = 0;
  var _saving = false;
  var _error = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _move(int step) {
    setState(() => _step = step);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _finish({bool openLogin = false}) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = false;
    });
    try {
      await ref.read(onboardingPrefProvider.notifier).complete();
      if (openLogin && mounted) context.go('/login');
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final steps = [
      (AkAssets.gallery[2], l.onboardingCommunity, l.onboardingCommunityBody),
      (AkAssets.toubaHero, l.onboardingMission, l.onboardingMissionBody),
      (AkAssets.toubaVision, l.onboardingServices, l.onboardingServicesBody),
    ];
    final (asset, title, subtitle) = steps[_step];
    final last = _step == steps.length - 1;
    final compact = MediaQuery.sizeOf(context).height < 480;
    final p = context.ak;
    return Scaffold(
      body: Column(
        children: [
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: akSystemUiStyle(Brightness.dark),
            child: ColoredBox(
              color: AKColors.deep,
              child: SafeArea(
                bottom: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: AkLayout.tablet),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AkSpace.space4,
                        vertical: AkSpace.space2,
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AkSpace.space2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Image(
                            image: AssetImage(AkAssets.logoOfficiel),
                            width: AkSize.sizeTouch,
                            height: AkSize.sizeTouch,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          ),
                          for (final (code, label) in [
                            ('fr', 'Français'),
                            ('ar', 'العربية'),
                          ])
                            ChoiceChip(
                              label: Text(label),
                              labelStyle: AkText.label.copyWith(
                                color: !_saving && lang == code
                                    ? AKColors.deep
                                    : AKColors.ivory,
                              ),
                              backgroundColor: AKColors.deep,
                              selectedColor: AKColors.goldLight,
                              disabledColor: AKColors.deep,
                              showCheckmark: false,
                              side: const BorderSide(color: AKColors.goldLight),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.padded,
                              selected: lang == code,
                              onSelected: _saving
                                  ? null
                                  : (_) => ref
                                      .read(languagePrefProvider.notifier)
                                      .set(code),
                            ),
                          if (compact)
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: AKColors.goldLight,
                                minimumSize: const Size(
                                  AkSize.sizeTouch,
                                  AkSize.sizeTouch,
                                ),
                              ),
                              onPressed: _saving ? null : _finish,
                              child: Text(l.onboardingSkip),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AkLayout.tablet),
                child: ListView(
                  controller: _scroll,
                  padding: EdgeInsets.only(
                    bottom:
                        AkSpace.space6 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    AkReveal(
                      key: ValueKey(asset),
                      slide: false,
                      child: LayoutBuilder(
                        builder: (context, constraints) => SizedBox(
                          height:
                              (constraints.maxWidth * .7).clamp(224.0, 320.0),
                          child: AkPhotoHero(
                            asset: asset,
                            child: const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AkSpace.space6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AkReveal(
                            key: ValueKey(_step),
                            child: Column(
                              children: [
                                const SizedBox(height: AkSpace.space2),
                                Semantics(
                                  header: true,
                                  child: Text(
                                    title,
                                    style: AkText.headline,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: AkSpace.space2),
                                Text(
                                  subtitle,
                                  style: AkText.body.copyWith(color: p.inkSoft),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AkSpace.space5),
                          Semantics(
                            liveRegion: true,
                            label: l.onboardingStep(_step + 1, steps.length),
                            child: ExcludeSemantics(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (var i = 0; i < steps.length; i++)
                                    AnimatedContainer(
                                      duration: AKMotion.duration(
                                        context,
                                        AKMotion.press,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: AkSpace.space1,
                                      ),
                                      width: i == _step
                                          ? AkSpace.space5
                                          : AkSpace.space2,
                                      height: AkSpace.space2,
                                      decoration: BoxDecoration(
                                        color: i == _step
                                            ? p.primary
                                            : p.borderControl,
                                        borderRadius: BorderRadius.circular(
                                          AkRadius.radiusPill,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AkSpace.space5),
                          if (_error) ...[
                            AkBanner(
                              tone: AkTone.danger,
                              icon: Icons.error_outline,
                              text: l.genericError,
                            ),
                            const SizedBox(height: AkSpace.space3),
                          ],
                          AkPrimaryButton(
                            label: last ? l.onboardingStart : l.onboardingNext,
                            icon: Icons.arrow_forward,
                            onPressed: last ? _finish : () => _move(_step + 1),
                            loading: _saving,
                          ),
                          const SizedBox(height: AkSpace.space2),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: AkSpace.space2,
                            children: [
                              if (_step > 0)
                                AkButton(
                                  label: l.onboardingBack,
                                  kind: AkButtonKind.text,
                                  expand: false,
                                  onPressed:
                                      _saving ? null : () => _move(_step - 1),
                                ),
                              if (!compact)
                                AkButton(
                                  label: l.onboardingSkip,
                                  kind: AkButtonKind.text,
                                  expand: false,
                                  onPressed: _saving ? null : _finish,
                                ),
                              AkButton(
                                label: l.loginButton,
                                kind: AkButtonKind.text,
                                expand: false,
                                onPressed: _saving
                                    ? null
                                    : () => _finish(openLogin: true),
                              ),
                            ],
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
      ),
    );
  }
}
