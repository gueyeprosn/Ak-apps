import 'dart:async';

import 'package:ahloulkhidmah_mobile/app/router/app_router.dart';
import 'package:ahloulkhidmah_mobile/core/format.dart';
import 'package:flutter/widgets.dart' show Key, Text;
import 'package:flutter_test/flutter_test.dart';

import '../support/pay_server.dart';
import '../support/pump_app.dart';

Future<Pumped> openPay(WidgetTester tester, PayServer server) async {
  final p = await pumpApp(tester, routes: server.routes(), tokens: session);
  await tester.tap(find.text('Payer ma cotisation'));
  await tester.pumpAndSettle();
  return p;
}

Future<void> chooseTwoMonthsAndContinue(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('months-plus')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continuer'));
  await tester.pumpAndSettle();
}

void main() {
  final total2 = formatAmount(2800, 'fr');

  group('choix des mois', () {
    testWidgets('mois dus du plus récent au plus ancien ; 1 mois retenu par défaut', (tester) async {
      await openPay(tester, PayServer());
      expect(find.text(periodeLabel(ym(0), 'fr')), findsOneWidget);
      expect(find.text('Mois en cours'), findsOneWidget);
      expect(find.text('En retard'), findsNWidgets(2));
      expect(tester.widget<Text>(find.byKey(const Key('months-value'))).data, '1');
      expect(find.text(formatAmount(1400, 'fr')), findsWidgets);
    });

    testWidgets('le total suit le nombre de mois choisi, borné par les mois dus', (tester) async {
      await openPay(tester, PayServer(periods: [ym(1), ym(0)]));
      await tester.tap(find.byKey(const Key('months-plus')));
      await tester.pumpAndSettle();
      expect(find.text(total2), findsWidgets);
      await tester.tap(find.byKey(const Key('months-plus'))); // déjà au maximum (2 mois dus)
      await tester.pumpAndSettle();
      expect(find.text(total2), findsWidgets);
      await tester.tap(find.byKey(const Key('months-minus')));
      await tester.pumpAndSettle();
      expect(find.text(formatAmount(1400, 'fr')), findsWidgets);
    });

    testWidgets('rien à payer : « Vous êtes à jour », aucune création', (tester) async {
      final s = PayServer(periods: []);
      await openPay(tester, s);
      expect(find.text('Vous êtes à jour'), findsOneWidget);
      expect(s.created, 0);
    });

    testWidgets('paiement désactivé côté serveur : état « indisponible », aucune création', (tester) async {
      final s = PayServer(enabled: false);
      await openPay(tester, s);
      expect(find.text('Paiement indisponible'), findsOneWidget);
      expect(s.created, 0);
    });

    testWidgets('visiteur : /pay renvoie vers la connexion', (tester) async {
      final s = PayServer();
      final p = await pumpApp(tester, routes: s.routes());
      p.container.read(routerProvider).go('/pay');
      await tester.pumpAndSettle();
      expect(find.text('Espace membre'), findsOneWidget);
      expect(s.created, 0);
    });
  });

  testWidgets('récapitulatif du paiement à 320 dp et texte à 200 %', (tester) async {
    final server = PayServer();
    final app = await pumpApp(tester, routes: server.routes(), tokens: session, width: 320, textScale: 2);
    app.container.read(routerProvider).push('/pay');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Moyen de paiement'), findsOneWidget);
    expect(find.text(periodeLabel(ym(0), 'fr')), findsOneWidget);
    expect(find.text(formatAmount(1400, 'fr')), findsOneWidget);
    expect(find.text('Payer avec Wave').hitTestable(), findsOneWidget);
    expect(server.created, 0);
  });

  group('paiement Wave', () {
    testWidgets('parcours complet : création → SoftPay → ouverture → attente → confirmation du serveur',
        (tester) async {
      final s = PayServer();
      final p = await openPay(tester, s);
      await chooseTwoMonthsAndContinue(tester);

      expect(find.text('Moyen de paiement'), findsOneWidget);
      expect(find.text('Payer avec Wave'), findsOneWidget);
      await tester.tap(find.byKey(const Key('pay-button')));
      await tester.pumpAndSettle();

      expect(s.createdBodies.single, {'monthsCount': 2},
          reason: 'le client envoie un nombre de mois, JAMAIS un montant');
      expect((s.softpayBodies.single as Map)['method'], 'wave');
      expect((s.softpayBodies.single as Map)['phone'], '+221770000001',
          reason: 'numéro du compte pré-rempli');
      expect(p.opener.opened.single.toString(), waveUrl);
      expect(s.polled, 3, reason: 'deux « pending » puis « completed »');

      expect(find.text('Paiement confirmé'), findsOneWidget);
      expect(find.textContaining(total2), findsWidgets, reason: 'montant du serveur');
      expect(p.adapter.count('GET /api/mobile/v1/me'), greaterThanOrEqualTo(2),
          reason: 'le profil est relu depuis le serveur');
    });

    testWidgets('pendant l\'attente : « Pas encore payé » est affiché, jamais de succès', (tester) async {
      final s = PayServer()..gate = Completer<void>();
      await openPay(tester, s);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay-button')));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('En attente de confirmation'), findsOneWidget);
      expect(find.text('Pas encore payé'), findsOneWidget);
      expect(find.text('Paiement confirmé'), findsNothing);
      s.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Paiement confirmé'), findsOneWidget);
    });

    testWidgets('délai dépassé (toujours « pending ») : écran « pas encore reçue », pas de succès',
        (tester) async {
      final s = PayServer(statuses: ['pending']);
      await openPay(tester, s);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay-button')));
      await tester.pumpAndSettle();
      expect(find.text('Confirmation pas encore reçue'), findsOneWidget);
      expect(find.text('Paiement confirmé'), findsNothing);
    });

    testWidgets('réseau coupé pendant tout le suivi : jamais « confirmé » sur la foi du téléphone',
        (tester) async {
      final s = PayServer()..statusDown = true;
      await openPay(tester, s);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay-button')));
      await tester.pumpAndSettle();
      expect(find.text('Paiement confirmé'), findsNothing);
      expect(find.text('Confirmation pas encore reçue'), findsOneWidget);
    });

    testWidgets('« Vérifier maintenant » après le délai : confirmation si le serveur l\'a reçue',
        (tester) async {
      final s = PayServer(statuses: ['pending', 'pending', 'pending', 'completed']);
      await openPay(tester, s);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay-button')));
      await tester.pumpAndSettle();
      expect(find.text('Confirmation pas encore reçue'), findsOneWidget);
      await tester.tap(find.byKey(const Key('check-now')));
      await tester.pumpAndSettle();
      expect(find.text('Paiement confirmé'), findsOneWidget);
    });

    testWidgets('paiement annulé ou refusé : échec explicite ; réessayer crée un NOUVEAU paiement',
        (tester) async {
      final s = PayServer(statuses: ['failed']);
      await openPay(tester, s);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay-button')));
      await tester.pumpAndSettle();
      expect(find.text('Paiement non abouti'), findsOneWidget);

      s.statuses = ['completed'];
      s.polled = 0;
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay-button')));
      await tester.pumpAndSettle();
      expect(s.created, 2, reason: 'une facture annulée ne se réutilise pas');
      expect(find.text('Paiement confirmé'), findsOneWidget);
    });

    testWidgets('changer de moyen sans changer les mois RÉUTILISE le paiement (pas de facture en double)',
        (tester) async {
      final s = PayServer()..gate = Completer<void>();
      final p = await openPay(tester, s);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay-button')));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('En attente de confirmation'), findsOneWidget);
      expect(s.created, 1);

      await tester.tap(find.byKey(const Key('change-method')));
      await tester.pump();
      await tester.pump();
      expect(find.text('Moyen de paiement'), findsOneWidget);
      await tester.tap(find.byKey(const Key('method-orange')));
      await tester.pump();
      s.softpayBody = {'mode': 'softpay', 'omUrl': 'https://orangemoneysn.page.link/x'};
      await tester.tap(find.byKey(const Key('pay-button')));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(s.created, 1, reason: 'même nombre de mois : la facture existante est réutilisée');
      expect(s.softpayBodies.length, 2);
      expect((s.softpayBodies.last as Map)['method'], 'orange');
      expect(p.opener.opened.length, 2);
      s.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('modifier le nombre de mois après avoir créé un paiement : nouvelle facture', (tester) async {
      final s = PayServer(statuses: ['pending']);
      await openPay(tester, s);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      s.softpayBody = {'mode': 'softpay', 'url': 'https://evil.example/x'}; // refusée → reste sur « moyen »
      await tester.tap(find.byKey(const Key('pay-button')));
      await tester.pumpAndSettle();
      expect(s.created, 1);
      await tester.tap(find.text('Modifier le nombre de mois'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('months-plus')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      s.softpayBody = {'mode': 'softpay', 'url': waveUrl};
      await tester.tap(find.byKey(const Key('pay-button')));
      await tester.pumpAndSettle();
      expect(s.created, 2, reason: 'le montant a changé : une nouvelle facture est créée');
      expect(s.createdBodies.last, {'monthsCount': 2});
    });
  });

  group('autres moyens et protections', () {
    testWidgets('carte bancaire : page hébergée ouverte, aucun appel SoftPay', (tester) async {
      final s = PayServer();
      final p = await openPay(tester, s);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('method-card')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pay-phone')), findsNothing, reason: 'pas de numéro pour la carte');
      await tester.tap(find.byKey(const Key('pay-button')));
      await tester.pumpAndSettle();
      expect(s.softpayBodies, isEmpty);
      expect(p.opener.opened.single.toString(), hostedUrl);
    });

    testWidgets('SoftPay indisponible : repli sur la page de paiement classique', (tester) async {
      final s = PayServer()..softpayBody = {'mode': 'hosted', 'url': hostedUrl};
      final p = await openPay(tester, s);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay-button')));
      await tester.pumpAndSettle();
      expect(p.opener.opened.single.toString(), hostedUrl);
    });

    testWidgets('Orange Money : lien Orange ouvert', (tester) async {
      final s = PayServer()..softpayBody = {'mode': 'softpay', 'omUrl': 'https://orangemoneysn.page.link/x'};
      final p = await openPay(tester, s);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('method-orange')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay-button')));
      await tester.pumpAndSettle();
      expect((s.softpayBodies.single as Map)['method'], 'orange');
      expect(p.opener.opened.single.host, 'orangemoneysn.page.link');
    });

    testWidgets('URL de paiement hors liste blanche : jamais ouverte', (tester) async {
      final s = PayServer()..softpayBody = {'mode': 'softpay', 'url': 'https://evil.example/pay'};
      final p = await openPay(tester, s);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay-button')));
      await tester.pumpAndSettle();
      expect(p.opener.opened, isEmpty);
      expect(find.textContaining('Impossible d\'ouvrir'), findsOneWidget);
      expect(find.text('Paiement confirmé'), findsNothing);
    });

    testWidgets('le système refuse d\'ouvrir le lien : message, aucune attente fantôme', (tester) async {
      final s = PayServer();
      final p = await openPay(tester, s);
      p.opener.result = false;
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay-button')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Impossible d\'ouvrir'), findsOneWidget);
      expect(s.polled, 0);
    });

    testWidgets('PayDunya indisponible à la création : message clair, pas d\'attente', (tester) async {
      final s = PayServer(createStatus: 503);
      await openPay(tester, s);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay-button')));
      await tester.pumpAndSettle();
      expect(find.text('Le paiement en ligne n\'est pas disponible pour le moment. Réessayez plus tard.'),
          findsOneWidget);
      expect(find.text('En attente de confirmation'), findsNothing);
      expect(s.polled, 0);
    });

    testWidgets('numéro incomplet : refusé avant tout appel au serveur', (tester) async {
      final s = PayServer();
      await openPay(tester, s);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('pay-phone')), '77');
      await tester.tap(find.byKey(const Key('pay-button')));
      await tester.pumpAndSettle();
      expect(find.text('Saisissez le numéro à débiter.'), findsOneWidget);
      expect(s.created, 0, reason: 'aucune facture créée pour un numéro invalide');
    });
  });

  group('arabe (RTL)', () {
    testWidgets('le parcours s\'affiche en arabe avec mois et montants localisés', (tester) async {
      final s = PayServer();
      await pumpApp(tester, routes: s.routes(), tokens: session, prefs: {'pref.lang': 'ar'});
      await tester.tap(find.text('ادفع اشتراكي'));
      await tester.pumpAndSettle();
      expect(find.text('دفع الاشتراك'), findsOneWidget);
      expect(find.text(periodeLabel(ym(0), 'ar')), findsOneWidget);
      expect(find.text(formatAmount(1400, 'ar')), findsWidgets);
    });
  });
}
