import 'package:flutter/material.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/animations/ak_motion.dart';
import '../../core/theme/ak_immersive.dart';

/// A full-width photo with a legible foreground and a directional gold edge.
class AkPhotoHero extends StatelessWidget {
  const AkPhotoHero({
    super.key,
    required this.asset,
    required this.child,
    this.alignment = Alignment.center,
    this.minHeight = 224,
    this.topPadding = 92,
  });

  final String asset;
  final Widget child;
  final Alignment alignment;
  final double minHeight;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final surface = context.ak.surface;
    return LayoutBuilder(
      builder: (context, constraints) {
        final decodeWidth =
            (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                .clamp(360, 1440)
                .round();
        final image = Image.asset(
          asset,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          alignment: alignment,
          cacheWidth: decodeWidth,
          excludeFromSemantics: true,
          frameBuilder: (context, image, frame, synchronouslyLoaded) =>
              synchronouslyLoaded || frame != null
                  ? image
                  : const ColoredBox(color: AKColors.primaryMedium),
        );
        return Stack(
          clipBehavior: Clip.hardEdge,
          alignment: AlignmentDirectional.bottomStart,
          children: [
            Positioned.fill(
              child: MediaQuery.disableAnimationsOf(context)
                  ? image
                  : TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.045, end: 1),
                      duration: const Duration(milliseconds: 720),
                      curve: AKMotion.ease,
                      child: image,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                    ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, .18, .42, .66, 1],
                    colors: [
                      AKColors.deep,
                      Color(0x0804281E),
                      Color(0x2204281E),
                      Color(0xD504281E),
                      Color(0xFF04281E),
                    ],
                  ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: SizedBox(
                width: double.infinity,
                child: Align(
                  alignment: AlignmentDirectional.bottomStart,
                  heightFactor: 1,
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      AkSpace.space4,
                      topPadding,
                      AkSpace.space4,
                      AkSpace.space10,
                    ),
                    child: DecoratedBox(
                      // The scrim follows the text as it grows at large sizes.
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AkRadius.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF04281E).withValues(alpha: .32),
                            blurRadius: 32,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 34,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _GoldEdge(surface, direction),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GoldEdge extends CustomPainter {
  const _GoldEdge(this.surface, this.direction);

  final Color surface;
  final TextDirection direction;

  Path _edge(Size size, double rise) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(0, h - 12 - rise)
      ..cubicTo(w * .32, h + 5 - rise, w * .67, h - 15 - rise, w, 6 - rise)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (direction == TextDirection.rtl) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    canvas.drawPath(
      _edge(size, 5),
      Paint()..shader = AKColors.goldGradient.createShader(Offset.zero & size),
    );
    canvas.drawPath(_edge(size, 0), Paint()..color = surface);
  }

  @override
  bool shouldRepaint(_GoldEdge old) =>
      old.surface != surface || old.direction != direction;
}
