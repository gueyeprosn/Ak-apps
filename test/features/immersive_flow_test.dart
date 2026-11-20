import 'package:ahloulkhidmah_mobile/core/animations/ak_motion.dart';
import 'package:ahloulkhidmah_mobile/core/providers.dart';
import 'package:ahloulkhidmah_mobile/features/home/home_screen.dart';
import 'package:ahloulkhidmah_mobile/features/onboarding/onboarding_screen.dart';
import 'package:ahloulkhidmah_mobile/l10n/app_localizations.dart';
import 'package:ahloulkhidmah_mobile/shared/widgets/ak_image_viewer.dart';
import 'package:ahloulkhidmah_mobile/shared/widgets/ak_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_adapter.dart';
import '../support/pump_app.dart';

void main() {
  final configRoute = {
    'GET /api/mobile/v1/config': (_) => FakeReply(200, configJson())
  };

  testWidgets('la découverte persiste le choix de langue et la fin du parcours',
      (tester) async {
    final app = await pumpApp(tester,
        routes: configRoute, prefs: {'pref.onboarding.complete': false});
    final screen = find.byType(OnboardingScreen);
    expect(screen, findsOneWidget);

    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();
    final context = tester.element(screen);
    final l = AppLocalizations.of(context);
    expect(Directionality.of(context), TextDirection.rtl);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text(l.onboardingNext));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text(l.onboardingStart));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    final prefs = app.container.read(sharedPrefsProvider);
    expect(prefs.getString('pref.lang'), 'ar');
    expect(prefs.getBool('pref.onboarding.complete'), true);
  });

  testWidgets(
      'onboarding compact en paysage, arabe à 200 % et mouvement réduit',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await pumpApp(tester, routes: configRoute, prefs: {
      'pref.onboarding.complete': false,
      'pref.lang': 'ar',
      'pref.theme': 'dark',
    });
    tester.view.physicalSize = const Size(800, 640);
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(OnboardingScreen));
    final skip = find.text(AppLocalizations.of(context).onboardingSkip);
    await tester.scrollUntilVisible(skip, 180);
    expect(tester.takeException(), isNull);
    await tester.tap(skip);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la galerie ouvre une photo officielle et revient à la liste',
      (tester) async {
    await pumpApp(tester, routes: configRoute);
    final gallery = find.text('Explorer les photos');
    await tester.scrollUntilVisible(gallery, 160);
    await tester.tap(gallery);
    await tester.pumpAndSettle();
    final caption = find.text('Grande Mosquée de Touba — vue drone');
    await tester.tap(caption);
    await tester.pumpAndSettle();
    expect(find.byType(AkImageViewer), findsOneWidget);
    await tester.tap(find.byType(BackButton).hitTestable());
    await tester.pumpAndSettle();
    expect(caption, findsOneWidget);
    expect(find.byType(AkImageViewer), findsNothing);
  });

  testWidgets(
      'Barkelu transmet les filtres au serveur et affiche les variantes reçues',
      (tester) async {
    await pumpApp(tester, routes: {
      ...configRoute,
      'GET /api/store/categories': (_) => const FakeReply(200, {
            'categories': [
              {'slug': 'textile', 'name': 'Textile'}
            ],
          }),
      'GET /api/store/products': (request) => FakeReply(200, {
            'products': [
              if (request.queryParameters['q'] == 'sac' &&
                  request.queryParameters['categorie'] == 'textile')
                {'slug': 'sac', 'name': 'Sac en toile', 'price': 4000},
            ],
          }),
      'GET /api/store/products/sac': (_) => const FakeReply(200, {
            'product': {
              'slug': 'sac',
              'name': 'Sac en toile',
              'price': 4000,
              'variants': [
                {'label': 'Toile verte', 'price': 4500}
              ],
            },
          }),
    });
    await tester.tap(find.text('Barkelu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Textile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'sac');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sac en toile'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Toile verte'), findsOneWidget);
  });

  testWidgets(
      'les boutons utilisent une pression de 97 % puis reprennent leur taille',
      (tester) async {
    await pumpApp(tester, routes: configRoute);
    final button = find.widgetWithText(AkButton, 'Adhérer');
    final scale =
        find.descendant(of: button, matching: find.byType(AnimatedScale));
    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump();
    await tester.pump(AKMotion.press);
    expect(tester.widget<AnimatedScale>(scale).scale, AKMotion.pressedScale);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(scale).scale, 1);
  });
}
