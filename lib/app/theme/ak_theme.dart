import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/ak_immersive.dart';
import 'ak_tokens.dart';

/// Expose la palette complète de la charte (au-delà du `ColorScheme`).
@immutable
class AkTheme extends ThemeExtension<AkTheme> {
  const AkTheme(this.palette);
  final AkPalette palette;

  @override
  AkTheme copyWith({AkPalette? palette}) => AkTheme(palette ?? this.palette);

  @override
  AkTheme lerp(ThemeExtension<AkTheme>? other, double t) =>
      other is AkTheme ? (t < 0.5 ? this : other) : this;
}

extension AkContext on BuildContext {
  AkPalette get ak => Theme.of(this).extension<AkTheme>()!.palette;
}

/// Styles typographiques de la charte (tokens `type.groups`).
abstract final class AkText {
  static TextStyle _t(String family, double size, double line, FontWeight w) =>
      TextStyle(
        fontFamily: family,
        fontFamilyFallback: AkFonts.fallback,
        fontVariations: [FontVariation.weight(w.value.toDouble())],
        fontSize: size,
        height: line / size,
        fontWeight: w,
      );

  static final display = _t(AkFonts.display, 36, 44, FontWeight.w700);
  static final headline = _t(AkFonts.display, 28, 36, FontWeight.w700);
  static final titleLg = _t(AkFonts.display, 22, 30, FontWeight.w700);
  static final title = _t(AkFonts.sans, 18, 26, FontWeight.w700);
  static final body = _t(AkFonts.sans, 16, 24, FontWeight.w400);
  static final bodyStrong = _t(AkFonts.sans, 16, 24, FontWeight.w600);
  static final bodySm = _t(AkFonts.sans, 14, 20, FontWeight.w400);
  static final label = _t(AkFonts.sans, 14, 20, FontWeight.w600);
  static final button = _t(AkFonts.sans, 16, 24, FontWeight.w700);
  static final caption = _t(AkFonts.sans, 12, 16, FontWeight.w500);
  static final amount = _t(AkFonts.sans, 28, 36, FontWeight.w700)
      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}

SystemUiOverlayStyle akSystemUiStyle(Brightness brightness) {
  final icons =
      brightness == Brightness.dark ? Brightness.light : Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: brightness,
    statusBarIconBrightness: icons,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: icons,
  );
}

ThemeData buildAkTheme(Brightness brightness) {
  final p = brightness == Brightness.light ? AkPalette.light : AkPalette.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: p.primary,
    onPrimary: p.onPrimary,
    secondary: p.gold,
    onSecondary: p.onGold,
    error: p.danger,
    onError: p.surface,
    surface: p.surface,
    onSurface: p.ink,
    onSurfaceVariant: p.inkSoft,
    outline: p.borderControl,
    outlineVariant: p.border,
    surfaceContainerHighest: p.surfaceSunken,
    primaryContainer: p.surfaceTint,
    onPrimaryContainer: p.primary,
  );
  final textTheme = TextTheme(
    displaySmall: AkText.display,
    headlineMedium: AkText.headline,
    titleLarge: AkText.titleLg,
    titleMedium: AkText.title,
    bodyLarge: AkText.body,
    bodyMedium: AkText.body,
    bodySmall: AkText.bodySm,
    labelLarge: AkText.button,
    labelMedium: AkText.label,
    labelSmall: AkText.caption,
  ).apply(bodyColor: p.ink, displayColor: p.ink);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.surface,
    canvasColor: p.surface,
    fontFamily: AkFonts.sans,
    fontFamilyFallback: AkFonts.fallback,
    textTheme: textTheme,
    dividerColor: p.border,
    appBarTheme: AppBarTheme(
      systemOverlayStyle: akSystemUiStyle(brightness),
      backgroundColor: p.surface,
      foregroundColor: p.ink,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: AkText.title.copyWith(color: p.ink),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AKColors.deep,
      indicatorColor: AKColors.gold,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => AkText.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? AKColors.goldLight
              : AKColors.ivory,
        ),
      ),
    ),
    extensions: [AkTheme(p)],
    focusColor: p.focusRing,
  );
}
