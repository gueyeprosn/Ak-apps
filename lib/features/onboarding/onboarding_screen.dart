import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/ak_tokens.dart';
import '../../core/animations/ak_motion.dart';
import '../../core/assets/ak_assets.dart';
import '../../core/providers.dart';
import '../../core/theme/ak_immersive.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/ak_animated_progress.dart';
import '../../shared/widgets/ak_immersive_header.dart';
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

  Future<void> _finish() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = false;
    });
    try {
      await ref.read(onboardingPrefProvider.notifier).complete();
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
      (AkAssets.toubaHero, l.onboardingMission, l.onboardingMissionBody),
      (AkAssets.gallery[2], l.onboardingCommunity, l.onboardingCommunityBody),
      (AkAssets.toubaVision, l.onboardingServices, l.onboardingServicesBody),
    ];
    final (asset, title, subtitle) = steps[_step];
    final last = _step == steps.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AkLayout.tablet),
            child: ListView(
              controller: _scroll,
              padding: akPagePadding,
              children: [
                Wrap(
                  spacing: AkSpace.space2,
                  runSpacing: AkSpace.space1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Image(
                        image: AssetImage(AkAssets.logo),
                        width: 48,
                        height: 48),
                    ChoiceChip(
                      label: const Text('Français'),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      selected: lang == 'fr',
                      onSelected: _saving
                          ? null
                          : (_) =>
                              ref.read(languagePrefProvider.notifier).set('fr'),
                    ),
                    ChoiceChip(
                      label: const Text('العربية'),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      selected: lang == 'ar',
                      onSelected: _saving
                          ? null
                          : (_) =>
                              ref.read(languagePrefProvider.notifier).set('ar'),
                    ),
                  ],
                ),
                const SizedBox(height: AkSpace.space4),
                AkReveal(
                  key: ValueKey(_step),
                  child: AkImmersiveHeader(
                      asset: asset,
                      title: title,
                      subtitle: subtitle,
                      photoHeight: 228),
                ),
                const SizedBox(height: AkSpace.space4),
                AkAnimatedProgress(
                  value: (_step + 1) / steps.length,
                  label: l.onboardingStep(_step + 1, steps.length),
                ),
                const SizedBox(height: AkSpace.space2),
                Semantics(
                  liveRegion: true,
                  child: Text(l.onboardingStep(_step + 1, steps.length),
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: AkSpace.space3),
                if (_error) ...[
                  AkBanner(
                      tone: AkTone.danger,
                      icon: Icons.error_outline,
                      text: l.genericError),
                  const SizedBox(height: AkSpace.space3),
                ],
                AkPrimaryButton(
                  label: last ? l.onboardingStart : l.onboardingNext,
                  onPressed: last ? _finish : () => _move(_step + 1),
                  loading: _saving,
                ),
                const SizedBox(height: AkSpace.space2),
                Wrap(
                  spacing: AkSpace.space2,
                  children: [
                    if (_step > 0)
                      AkButton(
                          label: l.onboardingBack,
                          kind: AkButtonKind.text,
                          expand: false,
                          onPressed: _saving ? null : () => _move(_step - 1)),
                    AkButton(
                        label: l.onboardingSkip,
                        kind: AkButtonKind.text,
                        expand: false,
                        onPressed: _saving ? null : _finish),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
