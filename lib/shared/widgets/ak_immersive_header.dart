import 'package:flutter/material.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/theme/ak_immersive.dart';

/// Cadrage photo indépendant de la hauteur du texte, y compris à 200 %.
class AkImmersiveHeader extends StatelessWidget {
  const AkImmersiveHeader({
    super.key,
    required this.asset,
    required this.title,
    this.subtitle,
    this.child,
    this.photoHeight = 176,
  });

  final String asset;
  final String title;
  final String? subtitle;
  final Widget? child;
  final double photoHeight;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AkRadius.radiusXl),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final decodeWidth =
                (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                    .clamp(360, 1440)
                    .round();
            return ColoredBox(
              color: AKColors.deep,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: photoHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          asset,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -.22),
                          cacheWidth: decodeWidth,
                          excludeFromSemantics: true,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [.38, 1],
                              colors: [Colors.transparent, AKColors.deep],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      constraints.maxWidth < AkLayout.compact
                          ? AkSpace.space4
                          : AkSpace.space6,
                      0,
                      constraints.maxWidth < AkLayout.compact
                          ? AkSpace.space4
                          : AkSpace.space6,
                      AkSpace.space6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(title,
                              style: AkText.headline
                                  .copyWith(color: AKColors.ivory)),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AkSpace.space2),
                          Text(subtitle!,
                              style: AkText.bodySm
                                  .copyWith(color: AKColors.ivory)),
                        ],
                        if (child != null) ...[
                          const SizedBox(height: AkSpace.space4),
                          child!,
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}
