import 'package:ahloulkhidmah_mobile/core/animations/ak_motion.dart';
import 'package:ahloulkhidmah_mobile/core/providers.dart';
import 'package:ahloulkhidmah_mobile/features/barkelu/barkelu_screen.dart';
import 'package:ahloulkhidmah_mobile/features/home/home_screen.dart';
import 'package:ahloulkhidmah_mobile/features/media/media_screen.dart';
import 'package:ahloulkhidmah_mobile/shared/widgets/ak_photo_hero.dart';
import 'package:ahloulkhidmah_mobile/shared/widgets/ak_loading_skeleton.dart';
import 'package:ahloulkhidmah_mobile/shared/widgets/ak_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_adapter.dart';
import '../support/pump_app.dart';

class _LoadingAuth extends AuthController {
  @override
  Future<void> restore() async {}
}

void main() {
  Map<String, FakeHandler> routes({bool barkelu = true}) => {
        'GET /api/mobile/v1/config': (_) => FakeReply(
              200,
              configJson(features: {'barkelu': barkelu, 'payments': true}),
            ),
        'GET /api/mobile/v1/me': (_) =>
            FakeReply(200, {'member': memberJson()}),
        'GET /api/store/categories': (_) =>
            const FakeReply(200, {'categories': []}),
        'GET /api/store/products': (_) =>
            const FakeReply(200, {'products': []}),
      };

  testWidgets('les six raccourcis gardent leurs cibles dans la grille 3 × 2',
      (tester) async {
    await pumpApp(tester, routes: routes(), tokens: session);
    final tiles = find.byType(AKServiceCard);
    expect(tiles, findsNWidgets(6));
    final first = tester.getTopLeft(tiles.at(0));
    final third = tester.getTopLeft(tiles.at(2));
    final fourth = tester.getTopLeft(tiles.at(3));
    expect(third.dx, greaterThan(first.dx));
    expect(third.dy, first.dy);
    expect(fourth.dx, first.dx);
    expect(fourth.dy, greaterThan(first.dy));

    await tester.tap(tiles.at(2));
    await tester.pumpAndSettle();
    expect(find.byType(BarkeluScreen), findsOneWidget);
    await tester.tap(findTab('Accueil'));
    await tester.pumpAndSettle();
    await tester.tap(tiles.last);
    await tester.pumpAndSettle();
    expect(find.byType(MediaScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('l’accueil RTL sombre à 200 % respecte le mouvement réduit',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpApp(
      tester,
      routes: routes(barkelu: false),
      tokens: session,
      prefs: {'pref.lang': 'ar', 'pref.theme': 'dark'},
      width: 320,
      textScale: 2,
    );

    final home = find.byType(HomeScreen);
    final hero = find.byType(AkPhotoHero);
    expect(Directionality.of(tester.element(home)), TextDirection.rtl);
    expect(find.byType(AKServiceCard), findsNWidgets(5));
    expect(
      find.descendant(
          of: hero, matching: find.byType(TweenAnimationBuilder<double>)),
      findsNothing,
    );
    final first = find.byType(AKServiceCard).at(0);
    final second = find.byType(AKServiceCard).at(1);
    expect(
        tester.getTopLeft(first).dx, greaterThan(tester.getTopLeft(second).dx));

    final community = find.byType(AKNewsCard);
    await tester.ensureVisible(community);
    await tester.pumpAndSettle();
    expect(community.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1500, 720);
    await tester.pumpAndSettle();
    await tester.ensureVisible(community);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'le squelette évite d’afficher les actions visiteur au chargement',
      (tester) async {
    await pumpApp(
      tester,
      routes: routes(),
      extraOverrides: [authControllerProvider.overrideWith(_LoadingAuth.new)],
    );
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(AkLoadingSkeleton), findsOneWidget);
    expect(find.byKey(const Key('home-login')), findsNothing);
    expect(find.byType(AKServiceCard), findsNothing);
  });

  testWidgets('un raccourci répond au toucher puis retrouve sa taille',
      (tester) async {
    await pumpApp(tester, routes: routes());
    final tile = find.byType(AKServiceCard).first;
    await tester.ensureVisible(tile);
    final scale =
        find.descendant(of: tile, matching: find.byType(AnimatedScale));
    final gesture = await tester.startGesture(tester.getCenter(tile));
    await tester.pump();
    await tester.pump(AKMotion.press);
    expect(tester.widget<AnimatedScale>(scale).scale, AKMotion.pressedScale);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(scale).scale, 1);
  });
}
