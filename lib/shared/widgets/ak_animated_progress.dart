import 'package:flutter/material.dart';

import '../../core/animations/ak_motion.dart';

/// Affiche une progression mesurée dans [0, 1] avec un libellé accessible.
class AkAnimatedProgress extends StatelessWidget {
  const AkAnimatedProgress(
      {super.key, required this.value, required this.label});

  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0.0, 1.0).toDouble();
    Widget bar(double progress) => LinearProgressIndicator(
          value: progress,
          semanticsLabel: label,
        );
    if (MediaQuery.disableAnimationsOf(context)) return bar(target);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: target),
      duration: AKMotion.pageIn,
      curve: AKMotion.ease,
      builder: (context, progress, _) => bar(progress),
    );
  }
}
