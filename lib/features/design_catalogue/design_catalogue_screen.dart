import 'package:flutter/material.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/animations/ak_motion.dart';
import '../../core/assets/ak_assets.dart';
import '../../core/theme/ak_immersive.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/ak_animated_progress.dart';
import '../../shared/widgets/ak_immersive_header.dart';
import '../../shared/widgets/ak_loading_skeleton.dart';
import '../../shared/widgets/ak_service_tile.dart';
import '../../shared/widgets/ak_widgets.dart';

/// Échantillons d'interface disponibles en build debug.
class DesignCatalogueScreen extends StatefulWidget {
  const DesignCatalogueScreen({super.key});

  @override
  State<DesignCatalogueScreen> createState() => _DesignCatalogueScreenState();
}

class _DesignCatalogueScreenState extends State<DesignCatalogueScreen> {
  var _progress = .25;

  @override
  Widget build(BuildContext context) {
    final p = context.ak;
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Khidmah Immersive')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AkLayout.contentMax),
            child: ListView(
              padding: akPagePadding,
              children: [
                AkImmersiveHeader(
                    asset: AkAssets.toubaHero, title: l.heroTitle),
                const SizedBox(height: AkSpace.space4),
                Wrap(
                  spacing: AkSpace.space3,
                  runSpacing: AkSpace.space3,
                  children: [
                    for (final color in [
                      p.primary,
                      p.gold,
                      p.surface,
                      p.ink,
                      p.danger
                    ])
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          border: Border.all(color: p.borderControl),
                          borderRadius:
                              BorderRadius.circular(AkRadius.radiusMd),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AkSpace.space4),
                for (final kind in AkButtonKind.values) ...[
                  AkButton(
                    label: kind.name,
                    kind: kind,
                    onPressed: () =>
                        setState(() => _progress = _progress > .5 ? .25 : .75),
                  ),
                  const SizedBox(height: AkSpace.space2),
                ],
                const AkButton(label: 'disabled', onPressed: null),
                const SizedBox(height: AkSpace.space2),
                AkAnimatedProgress(value: _progress, label: l.loading),
                const SizedBox(height: AkSpace.space4),
                AkCard(
                    padding: EdgeInsets.zero,
                    child: AkServiceTile(
                      icon: Icons.layers_outlined,
                      label: 'Bottom sheet',
                      onTap: () => showAkBottomSheet<void>(
                        context: context,
                        builder: (_) => AkEmptyState(
                          icon: Icons.photo_library_outlined,
                          title: l.galleryTitle,
                          body: l.galleryPhoto0,
                        ),
                      ),
                    )),
                const SizedBox(height: AkSpace.space4),
                StatusChip(
                    label: l.statusUpToDate,
                    tone: AkTone.success,
                    icon: Icons.check_circle_outline),
                const SizedBox(height: AkSpace.space3),
                AkBanner(
                    tone: AkTone.danger,
                    icon: Icons.error_outline,
                    text: l.genericError),
                const SizedBox(height: AkSpace.space3),
                AkLoadingSkeleton(label: l.loading, count: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
