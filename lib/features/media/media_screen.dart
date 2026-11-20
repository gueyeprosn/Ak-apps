import 'package:flutter/material.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/animations/ak_motion.dart';
import '../../core/assets/ak_assets.dart';
import '../../core/theme/ak_immersive.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/ak_brand_app_bar.dart';
import '../../shared/widgets/ak_image_viewer.dart';
import '../../shared/widgets/ak_widgets.dart';
import '../../shared/widgets/official_page_button.dart';

class MediaScreen extends StatelessWidget {
  const MediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labels = [
      l.galleryPhoto0,
      l.galleryPhoto1,
      l.galleryPhoto2,
      l.galleryPhoto3,
      l.galleryPhoto4,
      l.galleryPhoto5,
      l.galleryPhoto6,
    ];
    const featuredPhoto = 2;
    final order = [
      featuredPhoto,
      for (var i = 0; i < AkAssets.gallery.length; i++)
        if (i != featuredPhoto) i,
    ];

    return Scaffold(
      appBar: AkBrandAppBar(context: context, title: l.mediaLabel),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AkLayout.contentMax),
            child: ListView.separated(
              padding: akPagePadding,
              itemCount: order.length + 1,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AkSpace.space3),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AkHeading(title: l.galleryTitle, section: true),
                      const SizedBox(height: AkSpace.space2),
                      OfficialPageButton(
                        page: OfficialPage.media,
                        label: l.mediaOpen,
                      ),
                    ],
                  );
                }
                final photo = order[index - 1];
                final card = AkNewsCard(
                  asset: AkAssets.gallery[photo],
                  caption: labels[photo],
                  featured: photo == featuredPhoto,
                );
                return index == 1 ? AkReveal(child: card) : card;
              },
            ),
          ),
        ),
      ),
    );
  }
}

class AkNewsCard extends StatelessWidget {
  const AkNewsCard({
    super.key,
    required this.asset,
    required this.caption,
    this.featured = false,
  });

  final String asset;
  final String caption;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final p = context.ak;
    final compact = MediaQuery.textScalerOf(context).scale(14) >= 21;
    final image = AspectRatio(
      aspectRatio: featured ? 16 / 9 : 4 / 3,
      child: Image.asset(
        asset,
        cacheWidth: featured ? 960 : 320,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        frameBuilder: (context, child, frame, synchronouslyLoaded) =>
            synchronouslyLoaded || frame != null
                ? child
                : ColoredBox(color: p.surfaceSunken),
      ),
    );
    final preview = HeroMode(
      enabled: !MediaQuery.disableAnimationsOf(context),
      child: Hero(tag: asset, child: image),
    );
    final label = Row(
      children: [
        Expanded(child: Text(caption, style: AkText.bodyStrong)),
        const SizedBox(width: AkSpace.space2),
        ExcludeSemantics(
          child: Icon(Icons.chevron_right, color: p.primary),
        ),
      ],
    );

    return AkRaisedCard(
      onTap: () => AkImageViewer.open(
        context,
        AkImageViewer(image: AssetImage(asset), title: caption, heroTag: asset),
      ),
      child: featured
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                preview,
                Padding(
                  padding: const EdgeInsets.all(AkSpace.space4),
                  child: label,
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(AkSpace.space2),
              child: Row(
                children: [
                  SizedBox(
                    width: compact ? 72 : 96,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AkRadius.radiusMd),
                      child: preview,
                    ),
                  ),
                  const SizedBox(width: AkSpace.space3),
                  Expanded(child: label),
                ],
              ),
            ),
    );
  }
}
