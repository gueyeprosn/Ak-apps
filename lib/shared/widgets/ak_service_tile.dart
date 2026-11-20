import 'package:flutter/material.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/animations/ak_motion.dart';

class AkServiceTile extends StatelessWidget {
  const AkServiceTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => AkAnimatedButton(
        builder: (controller) => ListTile(
          statesController: controller,
          leading: Icon(icon, color: context.ak.primary),
          title: Text(label, style: AkText.bodyStrong),
          subtitle: subtitle == null ? null : Text(subtitle!),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          minTileHeight: AkSize.sizeTouch,
          onTap: onTap,
        ),
      );
}
