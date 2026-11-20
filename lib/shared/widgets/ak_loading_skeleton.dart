import 'package:flutter/material.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';

/// Réserve les dimensions du contenu et expose un seul état au lecteur d'écran.
class AkLoadingSkeleton extends StatelessWidget {
  const AkLoadingSkeleton(
      {super.key, required this.label, this.count = 3, this.height = 68});

  final String label;
  final int count;
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        liveRegion: true,
        child: Column(
          children: [
            for (var i = 0; i < count; i++)
              Container(
                margin: const EdgeInsets.only(bottom: AkSpace.space3),
                height: height,
                decoration: BoxDecoration(
                  color: context.ak.surfaceSunken,
                  borderRadius: BorderRadius.circular(AkRadius.radiusLg),
                ),
              ),
          ],
        ),
      );
}
