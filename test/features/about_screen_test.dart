import 'package:ahloulkhidmah_mobile/features/about/about_screen.dart';
import 'package:ahloulkhidmah_mobile/shared/widgets/official_page_button.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_adapter.dart';
import '../support/pump_app.dart';

void main() {
  final routes = {
    'GET /api/mobile/v1/config': (_) => FakeReply(200, configJson()),
  };

  testWidgets('accueil public, présentation et coordonnées officielles',
      (tester) async {
    final opened = <Uri>[];
    await pumpApp(tester, routes: routes, extraOverrides: [
      officialPageLauncherProvider.overrideWithValue((uri) async {
        opened.add(uri);
        return true;
      }),
    ]);

    await tester.tap(find.byTooltip('Contacter sur WhatsApp'));
    await tester.tap(find.byTooltip('Qui sommes-nous ?'));
    await tester.pumpAndSettle();
    expect(find.byType(AboutScreen), findsOneWidget);
    expect(find.text('Servir ensemble'), findsOneWidget);

    final email = find.text('contact@ahloulkhidmah.org').hitTestable();
    await tester.scrollUntilVisible(email, 180);
    await tester.pumpAndSettle();
    await tester.tap(email);
    final whatsAppNumber = find.text('+221 75 228 28 28').hitTestable();
    expect(whatsAppNumber, findsOneWidget);
    await tester.tap(whatsAppNumber);
    final aboutLink = find.text('Lire la présentation officielle').hitTestable();
    await tester.scrollUntilVisible(aboutLink, 120);
    await tester.pumpAndSettle();
    await tester.tap(aboutLink);
    expect(opened.map((uri) => uri.toString()), [
      'https://wa.me/221752282828',
      'mailto:contact@ahloulkhidmah.org',
      'https://wa.me/221752282828',
      'https://www.ahloulkhidmah.org/qui-sommes-nous',
    ]);
  });

  testWidgets('contacts lisibles en arabe sombre à 320 dp avec texte à 200 %',
      (tester) async {
    await pumpApp(
      tester,
      routes: routes,
      width: 320,
      textScale: 2,
      prefs: {'pref.lang': 'ar', 'pref.theme': 'dark'},
    );
    await tester.tap(find.byTooltip('من نحن؟'));
    await tester.pumpAndSettle();
    final screen = find.byType(AboutScreen);
    expect(Directionality.of(tester.element(screen)), TextDirection.rtl);
    final number = find.text('+221 75 228 28 28');
    await tester.scrollUntilVisible(number, 210);
    expect(tester.widget<Text>(number).textDirection, TextDirection.ltr);
    expect(find.byTooltip('تواصل عبر واتساب'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
