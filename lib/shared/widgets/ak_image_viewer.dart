import 'package:flutter/material.dart';

import '../../core/animations/ak_motion.dart';

/// Utilise le fournisseur original pour préserver les pixels du badge au zoom.
class AkImageViewer extends StatelessWidget {
  const AkImageViewer({
    super.key,
    required this.image,
    required this.title,
    this.heroTag,
    this.aspectRatio,
  });

  final ImageProvider image;
  final String title;
  final Object? heroTag;
  final double? aspectRatio;

  static Future<void> open(BuildContext context, AkImageViewer viewer) =>
      Navigator.of(context).push<void>(
        AkPageTransition<void>(
          context: context,
          pageKey: ObjectKey(viewer),
          child: viewer,
        ).createRoute(context),
      );

  @override
  Widget build(BuildContext context) {
    final tag = heroTag;
    Widget content = Image(
        image: image,
        fit: BoxFit.contain,
        semanticLabel: title,
        filterQuality: FilterQuality.high);
    if (aspectRatio != null) {
      content = AspectRatio(aspectRatio: aspectRatio!, child: content);
    }
    if (tag != null && !MediaQuery.disableAnimationsOf(context)) {
      content = Hero(tag: tag, child: content);
    }
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SizedBox.expand(
          child: InteractiveViewer(maxScale: 4, child: Center(child: content)),
        ),
      ),
    );
  }
}
