import 'package:flutter/material.dart';

/// Identité mobile fixe Khidmah Immersive, y compris au-dessus des photographies.
abstract final class AKColors {
  // Palette principale (Maquette 1 & 2)
  static const deep = Color(0xFF064C3B); // Vert émeraude profond
  static const primary = Color(0xFF064C3B);
  static const primaryMedium = Color(0xFF0B6647);
  static const action = Color(0xFF087A58);
  static const success = Color(0xFF087A58);
  static const successLight = Color(0xFFE8F5E9);

  // Or & accents
  static const gold = Color(0xFFD6A84D); // Or satiné
  static const goldSatin = Color(0xFFC99B47);
  static const goldSecondary = Color(0xFFDAAF37);
  static const goldLight = Color(0xFFE8CE83);
  static const goldDark = Color(0xFF9C7B2E);
  static const goldGlow = Color(0xFFE9BC60);

  // Surfaces & textes
  static const ivory = Color(0xFFF8F6F0); // Fond ivoire
  static const ivoryLight = Color(0xFFF8F5ED);
  static const white = Color(0xFFFFFFFF);
  static const charcoal = Color(0xFF172620); // Charbon texte
  static const charcoalAlt = Color(0xFF1F2937);

  // Sémantique & utilitaires
  static const alert = Color(0xFFE53E3E);
  static const link = Color(0xFF2563EB);

  // Dégradés signature
  static const LinearGradient emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A5844), Color(0xFF063B2C), Color(0xFF04281E)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF3D58C), Color(0xFFD6A84D), Color(0xFFB88A32)],
  );
}

abstract final class AkLayout {
  static const compact = 360.0;
  static const tablet = 600.0;
  static const contentMax = 720.0;
}
