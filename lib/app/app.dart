import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../features/notifications/presentation/push_interaction.dart';
import '../l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'theme/ak_theme.dart';

class AhloulApp extends ConsumerWidget {
  const AhloulApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final lang = ref.watch(languagePrefProvider);
    final themeMode = ref.watch(themePrefProvider);

    return MaterialApp.router(
      title: 'Ahloul Khidmah',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      scaffoldMessengerKey: rootMessengerKey,
      theme: buildAkTheme(Brightness.light),
      darkTheme: buildAkTheme(Brightness.dark),
      themeMode: themeMode,
      themeAnimationDuration: WidgetsBinding.instance.platformDispatcher
              .accessibilityFeatures.disableAnimations
          ? Duration.zero
          : kThemeAnimationDuration,
      // `null` : suit la langue du téléphone (français par défaut si non gérée).
      locale: lang == null ? null : Locale(lang),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (device, supported) {
        if (device != null && device.languageCode == 'ar')
          return const Locale('ar');
        return const Locale('fr');
      },
      builder: (context, child) {
        // Texte jusqu'à 200 % (réglage système) sans rupture de mise en page.
        final scale =
            MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 2.0);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: akSystemUiStyle(Theme.of(context).brightness),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: scale),
            child: PushInteraction(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
    );
  }
}

/// Langue effective, utile aux tests.
ui.Locale effectiveLocale(String? pref, ui.Locale device) => pref != null
    ? ui.Locale(pref)
    : (device.languageCode == 'ar'
        ? const ui.Locale('ar')
        : const ui.Locale('fr'));
