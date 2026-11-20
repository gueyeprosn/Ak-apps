// Captures d'écran de l'application RÉELLE (widgets Flutter, polices de la
// charte, données simulées). Sert à vérifier visuellement l'interface sans
// émulateur :
//
//   flutter test --update-goldens tool/screenshots/screens_test.dart
//
// Les images sont écrites dans tool/screenshots/out/.
import 'dart:io';

import 'package:ahloulkhidmah_mobile/app/app.dart';
import 'package:ahloulkhidmah_mobile/core/api/api_client.dart';
import 'package:ahloulkhidmah_mobile/core/auth/token_store.dart';
import 'package:ahloulkhidmah_mobile/core/providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Image, Key, precacheImage;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart' show Icons, TextField;
import 'package:shared_preferences/shared_preferences.dart';

import '../../test/support/fake_adapter.dart';
import '../../test/support/harness.dart';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    final bytes = await File(f).readAsBytes();
    loader.addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
  }
  await loader.load();
}

Map<String, dynamic> _paid(String p, String label) =>
    {'periode': p, 'periodeLabel': label, 'montant': 1400, 'statut': 'paye', 'canal': 'paydunya'};

Future<void> _pump(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  bool member = false,
  List<Map<String, dynamic>> versements = const [],
  double textScale = 1.0,
}) async {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({
    'pref.onboarding.complete': true,
    ...prefs,
  });
  final sp = await SharedPreferences.getInstance();
  final routes = <String, FakeHandler>{
    'GET /api/mobile/v1/config': (o) => FakeReply(200, configJson(), {'etag': '"c"'}),
    'GET /api/store/products': (o) => const FakeReply(200, {'products': []}),
    'POST /api/mobile/v1/auth/login': (o) => const FakeReply(200, {
          'status': 'pin_setup_required',
          'setupToken': 'demo-setup-token',
        }),
    'GET /api/mobile/v1/me': (o) => FakeReply(200, {'member': memberJson(versements: versements)}),
  };
  tester.view.physicalSize = const Size(800, 1720);
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(sp),
        clientInfoProvider.overrideWithValue(const ClientInfo(platform: 'android', appVersion: '1.0.0')),
        tokenStoreProvider.overrideWithValue(
          MemoryTokenStore(member ? const AuthTokens(accessToken: 'a', refreshToken: 'r') : null),
        ),
        httpAdapterProvider.overrideWithValue(FakeAdapter(routes)),
        appEnvProvider.overrideWithValue(testEnv),
      ],
      child: const AhloulApp(),
    ),
  );
  // Laisse le temps de décoder les images (logo) avant la capture.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pumpAndSettle();
}

Future<void> _shot(WidgetTester tester, String name) async {
  final images = find.byType(Image).evaluate().toList();
  await tester.runAsync(() => Future.wait([
    for (final element in images)
      precacheImage((element.widget as Image).image, element),
  ]));
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(AhloulApp),
    matchesGoldenFile('${Platform.environment['AK_SCREENSHOT_DIR'] ?? 'out'}/$name.png'),
  );
}

void main() {
  setUpAll(() async {
    const f = 'assets/fonts';
    await _loadFont('Cairo', [
      '$f/Cairo-Regular.ttf',
      '$f/Cairo-Medium.ttf',
      '$f/Cairo-SemiBold.ttf',
      '$f/Cairo-Bold.ttf',
    ]);
    await _loadFont('Amiri', ['$f/Amiri-Regular.ttf', '$f/Amiri-Bold.ttf']);
    await _loadFont('MaterialIcons', [
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ]);
  });

  final now = DateTime.now();
  final thisMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  final versements = [
    _paid(thisMonth, 'novembre 2026'),
    _paid('2026-10', 'octobre 2026'),
    _paid('2026-09', 'septembre 2026')
  ];

  testWidgets('00 onboarding officiel français', (t) async {
    await _pump(t, prefs: {'pref.onboarding.complete': false});
    await _shot(t, '00-onboarding-fr');
  });

  testWidgets('00 onboarding arabe sombre', (t) async {
    await _pump(t, prefs: {
      'pref.onboarding.complete': false,
      'pref.lang': 'ar',
      'pref.theme': 'dark',
    });
    await _shot(t, '00-onboarding-ar-sombre');
  });

  testWidgets('01 accueil visiteur', (t) async {
    await _pump(t);
    await _shot(t, '01-accueil-visiteur-fr');
  });
  testWidgets('02 connexion', (t) async {
    await _pump(t);
    await t.tap(find.text('Se connecter'));
    await t.pumpAndSettle();
    await _shot(t, '02-connexion-fr');
  });
  testWidgets('03 connexion premier accès', (t) async {
    await _pump(t);
    await t.tap(find.text('Se connecter'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('toggle-first')));
    await t.pumpAndSettle();
    await _shot(t, '03-connexion-premier-acces-fr');
  });
  testWidgets('11 création du PIN', (t) async {
    await _pump(t);
    await t.tap(find.text('Se connecter'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('toggle-first')));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).first, '770000001');
    await t.enterText(find.byKey(const Key('login-suffix')), 'AB12');
    await t.tap(find.text('Continuer'));
    await t.pumpAndSettle();
    await _shot(t, '11-creation-pin');
  });

  testWidgets('04 accueil membre', (t) async {
    await _pump(t, member: true, versements: versements);
    await _shot(t, '04-accueil-membre-fr');
  });
  testWidgets('05 accueil membre arabe RTL', (t) async {
    await _pump(t, member: true, versements: versements, prefs: {'pref.lang': 'ar'});
    await _shot(t, '05-accueil-membre-ar');
  });
  testWidgets('06 accueil membre sombre', (t) async {
    await _pump(t, member: true, versements: versements, prefs: {'pref.theme': 'dark'});
    await _shot(t, '06-accueil-membre-sombre');
  });
  testWidgets('07 cotisations', (t) async {
    await _pump(t, member: true, versements: versements);
    await t.tap(find.text('Cotisations'));
    await t.pumpAndSettle();
    await _shot(t, '07-cotisations-fr');
  });
  testWidgets('08 mon compte', (t) async {
    await _pump(t, member: true, versements: versements);
    await t.tap(find.text('Mon compte'));
    await t.pumpAndSettle();
    await _shot(t, '08-compte-fr');
  });
  testWidgets('09 accueil texte agrandi 200 %', (t) async {
    await _pump(t, member: true, versements: versements, textScale: 2.0);
    await _shot(t, '09-accueil-texte-200');
  });
  testWidgets('10 barkelu vide', (t) async {
    await _pump(t);
    await t.tap(find.byIcon(Icons.shopping_bag_outlined));
    await t.pumpAndSettle();
    await _shot(t, '10-barkelu-vide-fr');
  });
}
