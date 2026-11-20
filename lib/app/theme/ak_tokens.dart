// Tokens de la charte Khidmah Immersive.
import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart';

import '../../core/theme/ak_immersive.dart';

@immutable
class AkPalette {
  const AkPalette({
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.surfaceTint,
    required this.ink,
    required this.inkSoft,
    required this.border,
    required this.borderControl,
    required this.primary,
    required this.primaryPressed,
    required this.onPrimary,
    required this.gold,
    required this.goldLight,
    required this.goldDark,
    required this.onGold,
    required this.focusRing,
    required this.link,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.danger,
    required this.dangerBg,
    required this.info,
    required this.infoBg,
    required this.scrim,
  });
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color surfaceTint;
  final Color ink;
  final Color inkSoft;
  final Color border;
  final Color borderControl;
  final Color primary;
  final Color primaryPressed;
  final Color onPrimary;
  final Color gold;
  final Color goldLight;
  final Color goldDark;
  final Color onGold;
  final Color focusRing;
  final Color link;
  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;
  final Color danger;
  final Color dangerBg;
  final Color info;
  final Color infoBg;
  final Color scrim;

  static const light = AkPalette(
    surface: AKColors.ivory,
    surfaceRaised: AKColors.white,
    surfaceSunken: Color(0xFFF3EEE0),
    surfaceTint: Color(0xFFE7F0EA),
    ink: AKColors.charcoal,
    inkSoft: Color(0xFF4B4A3E),
    border: Color(0xFFE6DCC0),
    borderControl: Color(0xFF857B58),
    primary: AKColors.action,
    primaryPressed: AKColors.deep,
    onPrimary: AKColors.ivory,
    gold: AKColors.gold,
    goldLight: Color(0xFFE8CE83),
    goldDark: Color(0xFF9C7B2E),
    onGold: AKColors.deep,
    focusRing: AKColors.action,
    link: AKColors.action,
    success: Color(0xFF1B6B3A),
    successBg: Color(0xFFE3F2E8),
    warning: Color(0xFF8A5300),
    warningBg: Color(0xFFFFF1D6),
    danger: Color(0xFFB42318),
    dangerBg: Color(0xFFFDE8E6),
    info: Color(0xFF1B5E8A),
    infoBg: Color(0xFFE3F0F9),
    scrim: Color(0x990B3A25),
  );
  static const dark = AkPalette(
    surface: Color(0xFF0D1410),
    surfaceRaised: Color(0xFF141D18),
    surfaceSunken: Color(0xFF101712),
    surfaceTint: Color(0xFF1A2A21),
    ink: Color(0xFFF2EEE2),
    inkSoft: Color(0xFFB9B5A3),
    border: Color(0xFF2A3A31),
    borderControl: Color(0xFF7A8F82),
    primary: Color(0xFF8FD3AA),
    primaryPressed: Color(0xFF6DBB8B),
    onPrimary: Color(0xFF0A1F14),
    gold: Color(0xFFE8CE83),
    goldLight: Color(0xFFF3E3AB),
    goldDark: AKColors.gold,
    onGold: AKColors.deep,
    focusRing: Color(0xFFE8CE83),
    link: Color(0xFF8FD3AA),
    success: Color(0xFF7FD6A0),
    successBg: Color(0xFF16301F),
    warning: Color(0xFFF0B660),
    warningBg: Color(0xFF33260F),
    danger: Color(0xFFFF9A8E),
    dangerBg: Color(0xFF3A1A17),
    info: Color(0xFF8CC8EE),
    infoBg: Color(0xFF14293A),
    scrim: Color(0xB3000000),
  );
}

abstract final class AkSpace {
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
}

abstract final class AkRadius {
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusPill = 999;
}

abstract final class AkSize {
  static const double sizeTouch = 48;
  static const double sizeIcon = 24;
  static const double sizePin = 56;
}

abstract final class AkFonts {
  static const sans = 'Plus Jakarta Sans';
  static const display = sans;
  static const arabic = 'Noto Sans Arabic';
  static const fallback = [arabic];
}
