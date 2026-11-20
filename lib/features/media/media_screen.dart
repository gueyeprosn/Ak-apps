import 'package:flutter/material.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/assets/ak_assets.dart';
import '../../core/theme/ak_immersive.dart';
import '../../l10n/app_localizations.dart';
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
      l.galleryPhoto6
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.galleryTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AkLayout.contentMax),
            child: ListView.separated(
              padding: akPagePadding,
              itemCount: AkAssets.gallery.length + 1,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AkSpace.space4),
              itemBuilder: (context, index) {
                if (index == AkAssets.gallery.length) {
                  return OfficialPageButton(
                      page: OfficialPage.media, label: l.mediaOpen);
                }
                return AkNewsCard(
                    asset: AkAssets.gallery[index], caption: labels[index]);
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte éditoriale pour une photographie publiée dans la galerie officielle.
class AkNewsCard extends StatelessWidget {
  const AkNewsCard({super.key, required this.asset, required this.caption});

  final String asset;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final preview = AspectRatio(
      aspectRatio: 16 / 9,
      child: Image.asset(asset,
          cacheWidth: 960, fit: BoxFit.cover, excludeFromSemantics: true),
    );
    return AkCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => AkImageViewer.open(
            context,
            AkImageViewer(
              image: AssetImage(asset),
              title: caption,
              heroTag: asset,
            )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HeroMode(
              enabled: !MediaQuery.disableAnimationsOf(context),
              child: Hero(tag: asset, child: preview),
            ),
            Padding(
              padding: const EdgeInsets.all(AkSpace.space4),
              child: Text(caption, style: AkText.bodyStrong),
            ),
          ],
        ),
      ),
    );
  }
}
