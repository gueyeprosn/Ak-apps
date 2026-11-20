// Captures de l'adhésion et du don (application réelle, faux serveur) :
//
//   flutter test --update-goldens tool/screenshots/join_screens_test.dart
import 'dart:async';
import 'dart:io';

import 'package:ahloulkhidmah_mobile/app/app.dart';
import 'package:ahloulkhidmah_mobile/app/router/app_router.dart';
import 'package:ahloulkhidmah_mobile/features/public_pay/public_pay_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Key, Offset, Scrollable;
import 'package:flutter_test/flutter_test.dart';

import '../../test/support/pump_app.dart';
import '../../test/support/public_server.dart';

const _poll = PublicPollConfig(interval: Duration.zero, maxAttempts: 3, rateLimitedWait: Duration.zero);

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    final bytes = await File(f).readAsBytes();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

Future<void> _shot(WidgetTester t, String name) async {
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
  await t.pump();
  await expectLater(find.byType(AhloulApp),
      matchesGoldenFile('${Platform.environment['AK_SCREENSHOT_DIR'] ?? 'out'}/$name.png'));
}

Future<void> _frames(WidgetTester t, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 60));
  }
}

Future<Pumped> _open(WidgetTester t, PublicServer s, String route,
    {Map<String, Object> prefs = const {}}) async {
  final p = await pumpApp(
    t,
    routes: s.routes(),
    prefs: prefs,
    extraOverrides: [publicPollConfigProvider.overrideWithValue(_poll)],
  );
  p.container.read(routerProvider).go(route);
  await t.pumpAndSettle();
  return p;
}

Future<void> _type(WidgetTester t, String key, String text) async {
  await t.enterText(find.byKey(Key(key)), text);
  await t.pumpAndSettle();
}

Future<void> _tap(WidgetTester t, String key) async {
  final f = find.byKey(Key(key));
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> _fillJoin(WidgetTester t, {String amount = 'amount-14000'}) async {
  await _type(t, 'join-prenoms', 'Awa');
  await _type(t, 'join-nom', 'Diop');
  await _type(t, 'join-tel', '77 123 45 67');
  await _type(t, 'join-region', 'Sénégal');
  await _tap(t, amount);
}

Future<void> _scrollDown(WidgetTester t) async {
  await t.drag(find.byType(Scrollable).first, const Offset(0, -700));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    const f = 'assets/fonts';
    await _loadFont('Plus Jakarta Sans', ['$f/PlusJakartaSans.ttf']);
    await _loadFont('Noto Sans Arabic', ['$f/NotoSansArabic.ttf']);
    await _loadFont('MaterialIcons', [
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ]);
  });

  testWidgets('J1 accueil visiteur', (t) async {
    final s = PublicServer();
    await pumpApp(t, routes: s.routes());
    await _shot(t, 'j1-accueil-visiteur');
  });

  testWidgets('J2 adhésion : formulaire', (t) async {
    await _open(t, PublicServer(), '/join');
    await _shot(t, 'j2-adhesion-formulaire');
  });

  testWidgets('J3 adhésion : erreurs de saisie', (t) async {
    await _open(t, PublicServer(), '/join');
    await _type(t, 'join-prenoms', 'A');
    await _type(t, 'join-tel', '791234567');
    await t.tap(find.byKey(const Key('join-submit')));
    await t.pumpAndSettle();
    await _shot(t, 'j3-adhesion-erreurs');
  });

  testWidgets('J4 adhésion : montant et numéro déjà inscrit', (t) async {
    final s = PublicServer(createStatus: 409, createError: {'error': 'x'});
    await _open(t, s, '/join');
    await _fillJoin(t);
    await _scrollDown(t);
    await t.tap(find.byKey(const Key('join-submit')));
    await t.pumpAndSettle();
    await _shot(t, 'j4-adhesion-doublon');
  });

  testWidgets('J5 adhésion : moyen de paiement', (t) async {
    await _open(t, PublicServer(), '/join');
    await _fillJoin(t, amount: 'amount-1400');
    await t.tap(find.byKey(const Key('join-submit')));
    await t.pumpAndSettle();
    await _shot(t, 'j5-adhesion-moyen');
  });

  testWidgets('J6 adhésion : attente', (t) async {
    final s = PublicServer()..gate = Completer<void>();
    await _open(t, s, '/join');
    await _fillJoin(t);
    await t.tap(find.byKey(const Key('join-submit')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('pay-button')));
    await _frames(t);
    await _shot(t, 'j6-adhesion-attente');
    s.gate!.complete();
    await t.pumpAndSettle();
  });

  testWidgets('J7 adhésion : confirmée', (t) async {
    await _open(t, PublicServer(), '/join');
    await _fillJoin(t);
    await t.tap(find.byKey(const Key('join-submit')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('pay-button')));
    await t.pumpAndSettle();
    await _shot(t, 'j7-adhesion-confirmee');
  });

  testWidgets('J8 adhésion en arabe', (t) async {
    await _open(t, PublicServer(), '/join', prefs: {'pref.lang': 'ar'});
    await _shot(t, 'j8-adhesion-ar');
  });

  testWidgets('J9 adhésion en arabe : montant et message', (t) async {
    await _open(t, PublicServer(), '/join', prefs: {'pref.lang': 'ar'});
    await _scrollDown(t);
    await _shot(t, 'j9-adhesion-ar-bas');
  });

  testWidgets('J10 don : formulaire', (t) async {
    await _open(t, PublicServer(), '/give');
    await _shot(t, 'j10-don-formulaire');
  });

  testWidgets('J11 don : identité', (t) async {
    await _open(t, PublicServer(), '/give');
    await _scrollDown(t);
    await _scrollDown(t);
    await _shot(t, 'j11-don-identite');
  });

  testWidgets('J12 don anonyme sombre', (t) async {
    await _open(t, PublicServer(), '/give', prefs: {'pref.theme': 'dark'});
    await _tap(t, 'donate-anonymous');
    await _scrollDown(t);
    await _scrollDown(t);
    await _shot(t, 'j12-don-anonyme-sombre');
  });

  testWidgets('J13 don en arabe', (t) async {
    await _open(t, PublicServer(), '/give', prefs: {'pref.lang': 'ar'});
    await _shot(t, 'j13-don-ar');
  });

  testWidgets('J14 don confirmé', (t) async {
    final s = PublicServer(confirmedAmount: 10000);
    await _open(t, s, '/give');
    await _tap(t, 'donate-anonymous');
    await t.tap(find.byKey(const Key('donate-submit')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('pay-button')));
    await t.pumpAndSettle();
    await _shot(t, 'j14-don-confirme');
  });

  testWidgets('J15 secours Wave du site', (t) async {
    final s =
        PublicServer(wavePhone: {'number': '+221 75 525 00 02', 'amount': 1400, 'reference': 'AK-2026-1'});
    await _open(t, s, '/join');
    await _fillJoin(t, amount: 'amount-1400');
    await t.tap(find.byKey(const Key('join-submit')));
    await t.pumpAndSettle();
    await _shot(t, 'j15-secours-wave');
  });

  testWidgets('J16 sélecteur de pays', (t) async {
    await _open(t, PublicServer(), '/join');
    await t.tap(find.byKey(const Key('dial-picker')));
    await t.pumpAndSettle();
    await _shot(t, 'j16-selecteur-pays');
  });
}
