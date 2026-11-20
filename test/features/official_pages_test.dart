import 'package:ahloulkhidmah_mobile/app/router/app_router.dart';
import 'package:ahloulkhidmah_mobile/shared/widgets/official_page_button.dart';
import 'package:flutter/material.dart' show BottomSheet, Navigator;
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_adapter.dart';
import '../support/pump_app.dart';

void main() {
  testWidgets('médiathèque, boutique et assistance remettent uniquement des liens officiels', (tester) async {
    final opened = <Uri>[];
    await pumpApp(
      tester,
      extraOverrides: [
        officialPageLauncherProvider.overrideWithValue((uri) async {
          opened.add(uri);
          return true;
        }),
      ],
      routes: {
        'GET /api/mobile/v1/config': (_) => FakeReply(200, configJson()),
        'GET /api/store/products': (_) => const FakeReply(200, {
              'products': [
                {'name': 'Sac de démonstration', 'price': 4000},
              ],
            }),
      },
    );

    await tester.tap(find.text('Voir la médiathèque'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barkelu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sac de démonstration'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ouvrir la boutique').hitTestable());
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(BottomSheet))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accueil'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Code PIN oublié ?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contacter l’équipe sur WhatsApp'));
    await tester.pumpAndSettle();

    expect(opened.map((uri) => uri.toString()), [
      'https://www.ahloulkhidmah.org/mediatheque',
      'https://www.ahloulkhidmah.org/boutique',
      'https://wa.me/221752282828',
    ]);
  });

  testWidgets('routes membres absentes : accès web pour la carte, l’historique et les cotisations',
      (tester) async {
    final opened = <Uri>[];
    final app = await pumpApp(
      tester,
      tokens: session,
      extraOverrides: [
        officialPageLauncherProvider.overrideWithValue((uri) async {
          opened.add(uri);
          return true;
        }),
      ],
      routes: {
        'GET /api/mobile/v1/config': (_) => FakeReply(200, configJson()),
        'GET /api/mobile/v1/me': (_) => FakeReply(200, {'member': memberJson()}),
        'GET /api/mobile/v1/me/card': (_) => const FakeReply(404, '<html>Not found</html>'),
        'GET /api/mobile/v1/payments/due': (_) => const FakeReply(404, '<html>Not found</html>'),
      },
    );
    final router = app.container.read(routerProvider);
    await tester.tap(find.text('Ma carte membre'));
    await tester.pumpAndSettle();
    expect(find.textContaining('La carte n’est pas disponible'), findsOneWidget);
    await tester.tap(find.text('Ouvrir mon espace sur le site'));
    await tester.pumpAndSettle();

    router.go('/t/cotisations');
    await tester.pumpAndSettle();
    expect(find.text('Aucun versement'), findsOneWidget);
    await tester.tap(find.text('Voir l’historique complet sur le site'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Payer ma cotisation'));
    await tester.pumpAndSettle();
    expect(find.text('Paiement indisponible'), findsOneWidget);
    expect(find.text('Vous êtes hors ligne'), findsNothing);
    await tester.tap(find.text('Ouvrir mon espace sur le site'));
    await tester.pumpAndSettle();

    expect(opened.map((uri) => uri.toString()), [
      'https://www.ahloulkhidmah.org/mon-espace',
      'https://www.ahloulkhidmah.org/mon-espace/historique',
      'https://www.ahloulkhidmah.org/mon-espace',
    ]);
    expect(app.adapter.count('POST /api/mobile/v1/payments/cotisation'), 0);
  });
}
