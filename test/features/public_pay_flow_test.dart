import 'dart:async';

import 'package:ahloulkhidmah_mobile/app/router/app_router.dart';
import 'package:ahloulkhidmah_mobile/core/format.dart';
import 'package:ahloulkhidmah_mobile/features/public_pay/public_pay_controller.dart';
import 'package:flutter/widgets.dart' show EditableText, Key, Offset, Scrollable;
import 'package:flutter_test/flutter_test.dart';

import '../support/pay_server.dart' show hostedUrl, waveUrl;
import '../support/pump_app.dart';
import '../support/public_server.dart';

const _fastPoll = PublicPollConfig(interval: Duration.zero, maxAttempts: 3, rateLimitedWait: Duration.zero);
final _overrides = [publicPollConfigProvider.overrideWithValue(_fastPoll)];

Future<Pumped> open(WidgetTester tester, PublicServer s, {bool loggedIn = false}) =>
    pumpApp(tester, routes: s.routes(), tokens: loggedIn ? session : null, extraOverrides: _overrides);

/// Les listes sont paresseuses : un champ hors écran n'est pas construit. On
/// fait défiler vers le haut puis vers le bas jusqu'à le trouver.
Future<Finder> reveal(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  final list = find.byType(Scrollable).first;
  for (final dy in [600.0, -600.0]) {
    for (var i = 0; i < 12 && f.evaluate().isEmpty; i++) {
      await tester.drag(list, Offset(0, dy));
      await tester.pump();
    }
    if (f.evaluate().isNotEmpty) break;
  }
  expect(f, findsOneWidget, reason: 'champ introuvable : $key');
  await tester.ensureVisible(f);
  await tester.pump();
  return f;
}

Future<void> tapKey(WidgetTester tester, String key, {bool settle = true}) async {
  final f = await reveal(tester, key);
  await tester.tap(f);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // Attente animée (spinner) : pas de « settle » possible.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }
}

Future<void> typeKey(WidgetTester tester, String key, String text) async {
  final f = await reveal(tester, key);
  await tester.enterText(f, text);
  await tester.pumpAndSettle();
}

String fieldText(WidgetTester tester, String key) =>
    tester.widget<EditableText>(find.descendant(of: find.byKey(Key(key)), matching: find.byType(EditableText))).controller.text;

Future<void> openJoin(WidgetTester tester, Pumped p) async {
  await tapKey(tester, 'home-join');
}

Future<void> fillJoin(WidgetTester tester, {String tel = '77 123 45 67', String amount = 'amount-14000'}) async {
  await typeKey(tester, 'join-prenoms', 'Awa');
  await typeKey(tester, 'join-nom', 'Diop');
  await typeKey(tester, 'join-tel', tel);
  await typeKey(tester, 'join-region', 'Sénégal');
  await tapKey(tester, amount);
}

void main() {
  group('adhésion', () {
    testWidgets('parcours complet : formulaire → création → Wave → attente → confirmation du serveur', (tester) async {
      final s = PublicServer(confirmedAmount: 14000);
      final gate = s.gate = Completer<void>();
      final p = await open(tester, s);
      await openJoin(tester, p);
      expect(find.text('Devenir membre'), findsWidgets);

      await fillJoin(tester, amount: 'amount-1400');
      await tapKey(tester, 'join-submit');

      // Corps exact envoyé à POST /api/adhesions (schéma du site).
      expect(s.adhesions, 1);
      expect(s.adhesionBodies.single, {
        'nom': 'Diop',
        'prenoms': 'Awa',
        'tel': '+221771234567',
        'paysRegion': 'Sénégal',
        'montant': '1400',
      });

      // Choix du moyen : le numéro à débiter est pré-rempli (sénégalais).
      expect(find.text('Moyen de paiement'), findsOneWidget);
      expect(fieldText(tester, 'pay-phone'), '771234567');
      await tapKey(tester, 'pay-button', settle: false);
      expect(s.softpayBodies.single, {'paymentId': 'pay-1', 'method': 'wave', 'phone': '+221771234567'});
      expect(p.opener.opened.single.toString(), waveUrl);

      // Attente tenue : le serveur n'a rien confirmé → JAMAIS « Paiement confirmé ».
      expect(find.text('En attente de confirmation'), findsOneWidget);
      expect(find.text('Paiement confirmé'), findsNothing);
      expect(find.text('Pas encore payé'), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Paiement confirmé'), findsOneWidget);
      // Montant du SERVEUR dans le message final (14 000 ≠ 1 400 saisi : la
      // différence prouve que l'écran n'affiche pas la saisie).
      expect(find.textContaining(formatAmount(14000, 'fr')), findsWidgets);
      expect(find.textContaining(formatAmount(1400, 'fr')), findsNothing);
      expect(s.polled, 3, reason: 'pending, pending, puis completed');
      expect(find.byKey(const Key('go-login')), findsOneWidget);
      expect(find.byKey(const Key('receipt')), findsOneWidget);
    });

    testWidgets('saisie invalide : AUCUN appel serveur, erreurs affichées par champ', (tester) async {
      final s = PublicServer();
      final p = await open(tester, s);
      await openJoin(tester, p);
      await tapKey(tester, 'join-submit');
      expect(s.created, 0);
      expect(find.text('Champ obligatoire.'), findsWidgets);

      await typeKey(tester, 'join-prenoms', 'Awa');
      await typeKey(tester, 'join-nom', 'Diop');
      await typeKey(tester, 'join-region', 'France');
      await typeKey(tester, 'join-tel', '791234567');
      await tapKey(tester, 'join-submit');
      expect(s.created, 0);
      expect(find.textContaining('Numéro sénégalais invalide'), findsOneWidget);

      await tapKey(tester, 'amount-autre');
      await typeKey(tester, 'amount-other-field', '50');
      await typeKey(tester, 'join-tel', '771234567');
      await tapKey(tester, 'join-submit');
      expect(s.created, 0);
      expect(find.textContaining('Montant minimum'), findsOneWidget);
    });

    testWidgets('montant « autre » : seuls les chiffres sont envoyés', (tester) async {
      final s = PublicServer();
      final p = await open(tester, s);
      await openJoin(tester, p);
      await fillJoin(tester, amount: 'amount-autre');
      await typeKey(tester, 'amount-other-field', '2 500');
      await tapKey(tester, 'join-submit');
      final body = s.adhesionBodies.single as Map;
      expect(body['montant'], 'autre');
      expect(body['montantAutre'], '2500');
    });

    testWidgets('numéro déjà inscrit (409) : message clair, proposition de se connecter, pas de paiement', (tester) async {
      final s = PublicServer(createStatus: 409, createError: {'error': 'Ce numéro de téléphone est déjà utilisé par un autre adhérent.'});
      final p = await open(tester, s);
      await openJoin(tester, p);
      await fillJoin(tester);
      await tapKey(tester, 'join-submit');
      expect(find.textContaining('déjà inscrit'), findsOneWidget);
      expect(find.byKey(const Key('duplicate-login')), findsOneWidget);
      expect(find.text('Moyen de paiement'), findsNothing);
      expect(s.softpayBodies, isEmpty);
    });

    testWidgets('panne PayDunya (503) : indisponible, rien n\'est payé', (tester) async {
      final s = PublicServer(createStatus: 503, createError: {'error': 'x'});
      final p = await open(tester, s);
      await openJoin(tester, p);
      await fillJoin(tester);
      await tapKey(tester, 'join-submit');
      expect(find.textContaining('pas disponible pour le moment'), findsOneWidget);
      expect(find.text('Paiement confirmé'), findsNothing);
    });

    testWidgets('« Modifier mes informations » conserve la saisie ; même saisie = même paiement', (tester) async {
      final s = PublicServer();
      final p = await open(tester, s);
      await openJoin(tester, p);
      await fillJoin(tester);
      await tapKey(tester, 'join-submit');
      expect(s.adhesions, 1);

      await tapKey(tester, 'edit-info');
      expect(find.text('Moyen de paiement'), findsNothing);
      expect(fieldText(tester, 'join-prenoms'), 'Awa');
      expect(fieldText(tester, 'join-tel'), '77 123 45 67');

      // Saisie identique : le paiement déjà créé est réutilisé (pas de facture en double).
      await tapKey(tester, 'join-submit');
      expect(s.adhesions, 1);
      expect(find.text('Moyen de paiement'), findsOneWidget);

      // Saisie modifiée : un nouveau paiement.
      await tapKey(tester, 'edit-info');
      await typeKey(tester, 'join-nom', 'Fall');
      await tapKey(tester, 'join-submit');
      expect(s.adhesions, 2);
      expect((s.adhesionBodies.last as Map)['nom'], 'Fall');
    });

    testWidgets('carte bancaire : page hébergée ouverte, sans appel SoftPay', (tester) async {
      final s = PublicServer(statuses: ['completed']);
      final p = await open(tester, s);
      await openJoin(tester, p);
      await fillJoin(tester);
      await tapKey(tester, 'join-submit');
      await tapKey(tester, 'method-card');
      await tapKey(tester, 'pay-button');
      expect(p.opener.opened.single.toString(), hostedUrl);
      expect(s.softpayBodies, isEmpty);
      expect(find.text('Paiement confirmé'), findsOneWidget);
    });

    testWidgets('URL de paiement hors liste blanche : jamais ouverte', (tester) async {
      final s = PublicServer(softpayBody: {'ok': true, 'url': 'https://evil.example.com/pay'});
      final p = await open(tester, s);
      await openJoin(tester, p);
      await fillJoin(tester);
      await tapKey(tester, 'join-submit');
      await tapKey(tester, 'pay-button');
      expect(p.opener.opened, isEmpty);
      expect(find.textContaining('Impossible d\'ouvrir'), findsOneWidget);
      expect(find.text('Paiement confirmé'), findsNothing);
    });

    testWidgets('numéro à débiter incomplet : refusé avant tout appel SoftPay', (tester) async {
      final s = PublicServer();
      final p = await open(tester, s);
      await openJoin(tester, p);
      await fillJoin(tester, tel: '61 234 56 78'.replaceAll('61', '77')); // valide pour le formulaire
      await tapKey(tester, 'join-submit');
      await typeKey(tester, 'pay-phone', '12');
      await tapKey(tester, 'pay-button');
      expect(s.softpayBodies, isEmpty);
      expect(p.opener.opened, isEmpty);
    });

    testWidgets('paiement refusé côté serveur : écran d\'échec, jamais de confirmation', (tester) async {
      final s = PublicServer(statuses: ['pending', 'failed']);
      final p = await open(tester, s);
      await openJoin(tester, p);
      await fillJoin(tester);
      await tapKey(tester, 'join-submit');
      await tapKey(tester, 'pay-button');
      expect(find.text('Paiement non abouti'), findsOneWidget);
      expect(find.text('Paiement confirmé'), findsNothing);
      // Réessayer : retour au formulaire, un nouveau paiement sera créé.
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'join-submit');
      expect(s.adhesions, 2);
    });

    testWidgets('délai écoulé : « confirmation pas encore reçue », puis vérification manuelle', (tester) async {
      final s = PublicServer(statuses: ['pending']);
      final p = await open(tester, s);
      await openJoin(tester, p);
      await fillJoin(tester);
      await tapKey(tester, 'join-submit');
      await tapKey(tester, 'pay-button');
      expect(find.text('Confirmation pas encore reçue'), findsOneWidget);
      expect(find.text('Paiement confirmé'), findsNothing);

      s.statuses = ['completed'];
      s.polled = 0;
      await tapKey(tester, 'check-now');
      expect(find.text('Paiement confirmé'), findsOneWidget);
    });

    testWidgets('statut limité (429) : on attend et on continue, sans conclure', (tester) async {
      final s = PublicServer(statuses: ['completed']);
      s.statusReplyCode = 429;
      s.statusHeaders = {'retry-after': '0'};
      final p = await open(tester, s);
      await openJoin(tester, p);
      await fillJoin(tester);
      await tapKey(tester, 'join-submit');
      await tapKey(tester, 'pay-button');
      expect(find.text('Paiement confirmé'), findsNothing);
      expect(find.text('Confirmation pas encore reçue'), findsOneWidget);
    });

    testWidgets('secours Wave du site : instructions, jamais « payé », aucun suivi', (tester) async {
      final s = PublicServer(wavePhone: {'number': '+221 75 525 00 02', 'amount': 1400, 'reference': 'AK-2026-1'});
      final p = await open(tester, s);
      await openJoin(tester, p);
      await fillJoin(tester, amount: 'amount-1400');
      await tapKey(tester, 'join-submit');
      expect(find.text('Adhésion enregistrée, paiement à faire'), findsOneWidget);
      expect(find.textContaining('AK-2026-1'), findsOneWidget);
      expect(find.textContaining('n\'est pas payée'), findsOneWidget);
      expect(find.text('Paiement confirmé'), findsNothing);
      expect(s.polled, 0);
    });

    testWidgets('fonction « paiements » coupée à distance : écran indisponible, aucun appel', (tester) async {
      final s = PublicServer(paymentsFeature: false);
      final p = await open(tester, s);
      await openJoin(tester, p);
      expect(find.text('Paiement indisponible'), findsOneWidget);
      expect(find.byKey(const Key('join-submit')), findsNothing);
      expect(s.created, 0);
    });

    testWidgets('membre connecté : les appels publics ne portent pas son jeton', (tester) async {
      final s = PublicServer();
      final p = await open(tester, s, loggedIn: true);
      p.container.read(routerProvider).go('/join');
      await tester.pumpAndSettle();
      await fillJoin(tester);
      await tapKey(tester, 'join-submit');
      final call = p.adapter.requests.firstWhere((r) => r.path == '/api/adhesions');
      expect(call.headers.containsKey('Authorization'), isFalse);
    });

    testWidgets('accessible sans compte : depuis l\'écran de connexion aussi', (tester) async {
      final s = PublicServer();
      await open(tester, s);
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'login-join');
      expect(find.text('Devenir membre'), findsWidgets);
      expect(find.byKey(const Key('join-submit')), findsOneWidget);
    });
  });

  group('don', () {
    Future<void> openGive(WidgetTester tester, Pumped p) async {
      p.container.read(routerProvider).go('/give');
      await tester.pumpAndSettle();
    }

    testWidgets('don nominatif : corps exact, destination et message, confirmation du serveur', (tester) async {
      final s = PublicServer(confirmedAmount: 25500);
      final p = await open(tester, s);
      await openGive(tester, p);
      await tapKey(tester, 'amount-25000');
      await tapKey(tester, 'campaign-touba');
      await typeKey(tester, 'donate-prenoms', 'Awa');
      await typeKey(tester, 'donate-tel', '77 123 45 67');
      await typeKey(tester, 'donate-message', 'Pour le Magal');
      await tapKey(tester, 'donate-submit');

      expect(s.donationBodies.single, {
        'anonymous': false,
        'montant': '25000',
        'campagne': 'touba',
        'prenoms': 'Awa',
        'tel': '+221771234567',
        'message': 'Pour le Magal',
      });
      await tapKey(tester, 'pay-button');
      expect(find.text('Merci pour votre soutien'), findsOneWidget);
      expect(find.textContaining(formatAmount(25500, 'fr')), findsWidgets);
      expect(find.textContaining(formatAmount(25000, 'fr')), findsNothing);
      expect(find.byKey(const Key('go-login')), findsNothing, reason: 'pas de compte créé par un don');
    });

    testWidgets('don anonyme : aucun champ d\'identité n\'est demandé ni envoyé', (tester) async {
      final s = PublicServer();
      final p = await open(tester, s);
      await openGive(tester, p);
      await typeKey(tester, 'donate-prenoms', 'Awa');
      await typeKey(tester, 'donate-tel', '771234567');
      await tapKey(tester, 'donate-anonymous');
      expect(find.byKey(const Key('donate-prenoms')), findsNothing);
      await tapKey(tester, 'donate-submit');
      expect(s.donationBodies.single, {'anonymous': true, 'montant': '10000', 'campagne': 'general'});
    });

    testWidgets('identité obligatoire hors anonymat ; minimum 500 FCFA pour « autre »', (tester) async {
      final s = PublicServer();
      final p = await open(tester, s);
      await openGive(tester, p);
      await tapKey(tester, 'donate-submit');
      expect(s.created, 0);
      expect(find.text('Champ obligatoire.'), findsWidgets);

      await tapKey(tester, 'donate-anonymous');
      await tapKey(tester, 'amount-autre');
      await typeKey(tester, 'amount-other-field', '499');
      await tapKey(tester, 'donate-submit');
      expect(s.created, 0);
      expect(find.textContaining('Montant minimum'), findsOneWidget);

      await typeKey(tester, 'amount-other-field', '500');
      await tapKey(tester, 'donate-submit');
      expect(s.donations, 1);
      expect((s.donationBodies.single as Map)['montantAutre'], '500');
    });

    testWidgets('courriel invalide refusé avant tout appel', (tester) async {
      final s = PublicServer();
      final p = await open(tester, s);
      await openGive(tester, p);
      await typeKey(tester, 'donate-prenoms', 'Awa');
      await typeKey(tester, 'donate-tel', '771234567');
      await typeKey(tester, 'donate-email', 'pas-un-email');
      await tapKey(tester, 'donate-submit');
      expect(s.created, 0);
      expect(find.text('Email invalide.'), findsOneWidget);
    });

    testWidgets('membre connecté : identité pré-remplie depuis son profil', (tester) async {
      final s = PublicServer();
      final p = await open(tester, s, loggedIn: true);
      p.container.read(routerProvider).go('/give');
      await tester.pumpAndSettle();
      expect(fieldText(tester, 'donate-prenoms'), 'Awa');
      expect(fieldText(tester, 'donate-nom'), 'Diop');
      expect(fieldText(tester, 'donate-tel'), '770000001');
    });

    testWidgets('transparence : l\'information sur la fiche membre est affichée hors anonymat', (tester) async {
      final s = PublicServer();
      final p = await open(tester, s);
      await openGive(tester, p);
      expect(find.textContaining('fiche de membre'), findsOneWidget);
      await tapKey(tester, 'donate-anonymous');
      expect(find.textContaining('fiche de membre'), findsNothing);
    });

    testWidgets('visiteur : le don est accessible depuis l\'accueil', (tester) async {
      final s = PublicServer();
      final p = await open(tester, s);
      await tapKey(tester, 'home-give');
      expect(find.byKey(const Key('donate-submit')), findsOneWidget);
      expect(p.opener.opened, isEmpty);
    });

    testWidgets('membre connecté : l\'action « Contribuer » de l\'accueil ouvre le don', (tester) async {
      final s = PublicServer();
      await open(tester, s, loggedIn: true);
      await tester.tap(find.text('Contribuer'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('donate-submit')), findsOneWidget);
    });
  });
}
