// Captures du parcours de paiement (application réelle, faux serveur) :
//
//   flutter test --update-goldens tool/screenshots/pay_screens_test.dart
import 'dart:async';
import 'dart:io';

import 'package:ahloulkhidmah_mobile/app/app.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Key;
import 'package:flutter_test/flutter_test.dart';

import '../../test/support/pay_server.dart';
import '../../test/support/pump_app.dart';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    final bytes = await File(f).readAsBytes();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

Future<void> _shot(WidgetTester t, String name) async {
  // Laisse le temps de décoder les images (logos) avant la capture.
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

Future<void> _openByText(WidgetTester t, PayServer s, String label,
    {Map<String, Object> prefs = const {}}) async {
  await pumpApp(t, routes: s.routes(), tokens: session, prefs: prefs);
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
  await t.pumpAndSettle();
  await t.tap(find.text(label));
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

  testWidgets('P1 choix des mois', (t) async {
    final s = PayServer();
    await _openByText(t, s, 'Payer ma cotisation');
    await t.tap(find.byKey(const Key('months-plus')));
    await t.pumpAndSettle();
    await _shot(t, 'p1-choix-mois');
  });

  testWidgets('P2 moyen de paiement', (t) async {
    final s = PayServer();
    await _openByText(t, s, 'Payer ma cotisation');
    await t.tap(find.text('Continuer'));
    await t.pumpAndSettle();
    await _shot(t, 'p2-moyen');
  });

  testWidgets('P3 attente', (t) async {
    final s = PayServer()..gate = Completer<void>();
    await _openByText(t, s, 'Payer ma cotisation');
    await t.tap(find.text('Continuer'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('pay-button')));
    await _frames(t);
    await _shot(t, 'p3-attente');
    s.gate!.complete();
    await t.pumpAndSettle();
  });

  testWidgets('P4 confirmé', (t) async {
    final s = PayServer();
    await _openByText(t, s, 'Payer ma cotisation');
    await t.tap(find.byKey(const Key('months-plus')));
    await t.pumpAndSettle();
    await t.tap(find.text('Continuer'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('pay-button')));
    await t.pumpAndSettle();
    await _shot(t, 'p4-confirme');
  });

  testWidgets('P5 échec', (t) async {
    final s = PayServer(statuses: ['failed']);
    await _openByText(t, s, 'Payer ma cotisation');
    await t.tap(find.text('Continuer'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('pay-button')));
    await t.pumpAndSettle();
    await _shot(t, 'p5-echec');
  });

  testWidgets('P6 délai dépassé', (t) async {
    final s = PayServer(statuses: ['pending']);
    await _openByText(t, s, 'Payer ma cotisation');
    await t.tap(find.text('Continuer'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('pay-button')));
    await t.pumpAndSettle();
    await _shot(t, 'p6-delai');
  });

  testWidgets('P7 choix des mois en arabe', (t) async {
    final s = PayServer();
    await _openByText(t, s, 'ادفع اشتراكي', prefs: {'pref.lang': 'ar'});
    await t.tap(find.byKey(const Key('months-plus')));
    await t.pumpAndSettle();
    await _shot(t, 'p7-choix-mois-ar');
  });

  testWidgets('P8 moyen de paiement sombre, erreur PayDunya', (t) async {
    final s = PayServer(createStatus: 503);
    await _openByText(t, s, 'Payer ma cotisation', prefs: {'pref.theme': 'dark'});
    await t.tap(find.text('Continuer'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('pay-button')));
    await t.pumpAndSettle();
    await _shot(t, 'p8-moyen-sombre-erreur');
  });
}
