import 'package:flutter/material.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';

/// Choix unique présenté en tuile (montant, destination…). Même apparence que
/// les moyens de paiement : l'état sélectionné ne repose jamais sur la seule
/// couleur (bordure épaisse + pastille pleine) et la tuile est annoncée comme
/// bouton sélectionné par les lecteurs d'écran.
class AkChoiceTile extends StatelessWidget {
  const AkChoiceTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.ak;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      label: subtitle == null ? title : '$title, $subtitle',
      child: InkWell(
        borderRadius: BorderRadius.circular(AkRadius.radiusMd),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: AkSpace.space4, vertical: AkSpace.space3),
          decoration: BoxDecoration(
            color: selected ? p.surfaceTint : p.surfaceRaised,
            borderRadius: BorderRadius.circular(AkRadius.radiusMd),
            border: Border.all(color: selected ? p.primary : p.borderControl, width: selected ? 2 : 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AkText.bodyStrong),
                    if (subtitle != null) Text(subtitle!, style: AkText.bodySm.copyWith(color: p.inkSoft)),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? p.onPrimary : p.surfaceRaised,
                  border: Border.all(color: selected ? p.primary : p.borderControl, width: selected ? 7 : 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
