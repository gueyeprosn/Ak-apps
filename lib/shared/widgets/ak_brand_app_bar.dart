import 'package:flutter/material.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/theme/ak_immersive.dart';

/// Barre de titre émeraude avec le bouton Retour natif et une hauteur
/// adaptée aux titres sur deux lignes lorsque le texte est agrandi.
class AkBrandAppBar extends AppBar {
  AkBrandAppBar({
    required BuildContext context,
    required String title,
    bool centerTitle = true,
    List<Widget>? actions,
    super.automaticallyImplyLeading,
  }) : super(
          title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
          titleTextStyle: AkText.title.copyWith(color: AKColors.ivory),
          centerTitle: centerTitle,
          actions: actions,
          toolbarHeight: MediaQuery.textScalerOf(context).scale(18) >= 27
              ? AkSpace.space12 * 2
              : kToolbarHeight,
          backgroundColor: AKColors.deep,
          foregroundColor: AKColors.ivory,
          iconTheme: const IconThemeData(color: AKColors.ivory),
          actionsIconTheme: const IconThemeData(color: AKColors.ivory),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: akSystemUiStyle(Brightness.dark),
        );
}
