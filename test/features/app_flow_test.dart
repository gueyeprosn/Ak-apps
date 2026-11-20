import 'dart:ui' show Size;

import 'package:ahloulkhidmah_mobile/app/app.dart';
import 'package:ahloulkhidmah_mobile/core/api/api_client.dart';
import 'package:ahloulkhidmah_mobile/core/auth/token_store.dart';
import 'package:ahloulkhidmah_mobile/core/providers.dart';
import 'package:ahloulkhidmah_mobile/core/storage/card_cache.dart';
import 'package:flutter/widgets.dart' show Directionality, Key, Scrollable, TextDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart' show Icons, Scaffold, TextField;
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_adapter.dart';
import '../support/harness.dart';

class AppCtx {
  AppCtx(this.adapter, this.store, this.container);
  final FakeAdapter adapter;
  final MemoryTokenStore store;
  final ProviderContainer container;
}

Future<AppCtx> pumpApp(
  WidgetTester tester, {
  required Map<String, FakeHandler> routes,
  AuthTokens? tokens,
  Map<String, Object> prefs = const {},
  String version = '1.0.0',
  double width = 400,
  double textScale = 1,
}) async {
  SharedPreferences.setMockInitialValues({
    'pref.onboarding.complete': true,
    ...prefs,
  });
  final sp = await SharedPreferences.getInstance();
  final adapter = FakeAdapter(routes);
  final store = MemoryTokenStore(tokens);
  tester.view.physicalSize = Size(width * 2, 1600);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(sp),
        clientInfoProvider.overrideWithValue(ClientInfo(platform: 'android', appVersion: version)),
        tokenStoreProvider.overrideWithValue(store),
        httpAdapterProvider.overrideWithValue(adapter),
        appEnvProvider.overrideWithValue(testEnv),
        // Jamais le vrai stockage de fichiers dans les tests (plugin de plateforme).
        cardCacheProvider.overrideWithValue(MemoryCardCache()),
      ],
      child: const AhloulApp(),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(tester.element(find.byType(AhloulApp)));
  return AppCtx(adapter, store, container);
}

Map<String, FakeHandler> baseRoutes({Map<String, dynamic>? config}) => {
      'GET /api/mobile/v1/config': (o) => FakeReply(200, config ?? configJson(), {'etag': '"cfg-3"'}),
      'GET /api/store/products': (o) =>
          const FakeReply(200, {'products': [], 'total': 0, 'page': 1, 'pageSize': 20}),
    };

const _session = AuthTokens(accessToken: 'a', refreshToken: 'r');

Map<String, dynamic> _paid(String periode, String label) =>
    {'periode': periode, 'periodeLabel': label, 'montant': 1400, 'statut': 'paye', 'canal': 'paydunya'};

void main() {
  group('démarrage et configuration distante', () {
    testWidgets('visiteur : accueil, barre d\'onglets décrite par le serveur', (tester) async {
      await pumpApp(tester, routes: baseRoutes());
      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Barkelu'), findsWidgets);
      expect(find.text('Mon compte'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget, reason: 'un visiteur voit l\'accès à la connexion');
      expect(find.textContaining('Salam'), findsNothing);
    });

    testWidgets('maintenance : message du serveur, aucune navigation', (tester) async {
      await pumpApp(tester, routes: baseRoutes(config: configJson(maintenance: true)));
      expect(find.text('Maintenance en cours'), findsOneWidget);
      expect(find.text('Retour à 18 h.'), findsOneWidget);
      expect(find.text('Accueil'), findsNothing);
    });

    testWidgets('version trop ancienne : mise à jour obligatoire', (tester) async {
      await pumpApp(tester, routes: baseRoutes(config: configJson(minApp: '2.0.0')));
      expect(find.text('Mise à jour nécessaire'), findsOneWidget);
      expect(find.text('Accueil'), findsNothing);
    });

    testWidgets('version égale à la version minimale : accès normal', (tester) async {
      await pumpApp(tester, routes: baseRoutes(config: configJson(minApp: '1.0.0')));
      expect(find.text('Mise à jour nécessaire'), findsNothing);
      expect(find.text('Accueil'), findsOneWidget);
    });

    testWidgets('drapeau désactivé côté serveur : la rubrique disparaît sans republier l\'application',
        (tester) async {
      await pumpApp(tester, routes: baseRoutes(config: configJson(features: {'barkelu': false})));
      expect(find.text('Barkelu'), findsNothing);
      expect(find.text('Accueil'), findsOneWidget);
    });

    testWidgets('rubrique inconnue de cette version : écran de repli, pas d\'erreur', (tester) async {
      await pumpApp(tester,
          routes: baseRoutes(
              config: configJson(tabs: [
            {
              'id': 'home',
              'label': {'fr': 'Accueil'},
              'type': 'native',
              'screen': 'home',
              'icon': 'home'
            },
            {
              'id': 'nouveau',
              'label': {'fr': 'Nouveauté'},
              'type': 'native',
              'screen': 'hologramme',
              'icon': 'star'
            },
          ])));
      await tester.tap(find.text('Nouveauté'));
      await tester.pumpAndSettle();
      expect(find.text('Cette rubrique nécessite une mise à jour'), findsOneWidget);
    });

    testWidgets('serveur injoignable au premier lancement : configuration embarquée, application utilisable',
        (tester) async {
      await pumpApp(tester,
          routes: {'GET /api/mobile/v1/config': networkDown(), 'GET /api/store/products': networkDown()});
      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Cotisations'), findsOneWidget);
    });

    testWidgets('lien de rubrique en WebView : refusé hors liste blanche', (tester) async {
      await pumpApp(tester,
          routes: baseRoutes(
              config: configJson(tabs: [
            {
              'id': 'home',
              'label': {'fr': 'Accueil'},
              'type': 'native',
              'screen': 'home',
              'icon': 'home'
            },
            {
              'id': 'evil',
              'label': {'fr': 'Piège'},
              'type': 'webview',
              'url': 'https://evil.example/x',
              'icon': 'star'
            },
          ])));
      await tester.tap(find.text('Piège'));
      await tester.pumpAndSettle();
      expect(find.text('Cette rubrique nécessite une mise à jour'), findsOneWidget);
      expect(find.text('evil.example'), findsNothing);
    });
  });

  group('connexion', () {
    Future<void> goToLogin(WidgetTester tester) async {
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();
      expect(find.text('Espace membre'), findsOneWidget);
      expect(find.text('+221'), findsOneWidget, reason: 'le préfixe pays est visible même champ vide');
    }

    testWidgets('connexion par PIN : arrive sur l\'accueil connecté', (tester) async {
      final ctx = await pumpApp(tester, routes: {
        ...baseRoutes(),
        'POST /api/mobile/v1/auth/login': (o) => FakeReply(200, {
              'status': 'ok',
              'accessToken': 'a',
              'refreshToken': 'r',
              'expiresIn': 900,
              'member': memberJson(versements: [_paid('2026-11', 'novembre 2026')]),
            }),
      });
      await goToLogin(tester);
      await tester.enterText(find.byType(TextField).first, '77 000 00 01');
      await tester.enterText(find.byKey(const Key('login-pin')), '1234');
      await tester.pumpAndSettle();

      expect(find.text('Salam, Awa'), findsOneWidget);
      final sent = ctx.adapter.requests.firstWhere((r) => r.path.endsWith('/auth/login')).data as Map;
      expect(sent['tel'], '+22177 000 00 01', reason: 'indicatif +221 ajouté si absent');
      expect(sent['suffix'], '1234');
      expect(await ctx.store.read(), isNotNull);
    });

    testWidgets('premier accès : création du PIN, puis accueil connecté', (tester) async {
      final ctx = await pumpApp(tester, routes: {
        ...baseRoutes(),
        'POST /api/mobile/v1/auth/login': (o) =>
            const FakeReply(200, {'status': 'pin_setup_required', 'setupToken': 'setup-9'}),
        'POST /api/mobile/v1/auth/pin-setup': (o) => FakeReply(200, {
              'status': 'ok',
              'accessToken': 'a',
              'refreshToken': 'r',
              'expiresIn': 900,
              'member': memberJson(),
            }),
      });
      await goToLogin(tester);
      await tester.enterText(find.byType(TextField).first, '770000002');
      await tester.tap(find.byKey(const Key('toggle-first')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('login-suffix')), '5x2z');
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      final sent = ctx.adapter.requests.firstWhere((r) => r.path.endsWith('/auth/login')).data as Map;
      expect(sent['suffix'], '5X2Z', reason: 'le suffixe du badge est envoyé en majuscules, lettres admises');
      expect(find.text('Créez votre code PIN'), findsOneWidget);
      expect(await ctx.store.read(), isNull, reason: 'aucune session avant la création du PIN');

      await tester.enterText(find.byKey(const Key('setup-pin')), '2468');
      await tester.enterText(find.byKey(const Key('setup-confirm')), '2468');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer et continuer'));
      await tester.pumpAndSettle();

      expect(find.text('Salam, Awa'), findsOneWidget);
      final setup = ctx.adapter.requests.firstWhere((r) => r.path.endsWith('/pin-setup'));
      expect(setup.headers['Authorization'], 'Bearer setup-9');
      expect(await ctx.store.read(), isNotNull);
    });

    testWidgets('deux PIN différents : refusé côté application, aucune requête envoyée', (tester) async {
      final ctx = await pumpApp(tester, routes: {
        ...baseRoutes(),
        'POST /api/mobile/v1/auth/login': (o) =>
            const FakeReply(200, {'status': 'pin_setup_required', 'setupToken': 's'}),
      });
      await goToLogin(tester);
      await tester.enterText(find.byType(TextField).first, '770000002');
      await tester.tap(find.byKey(const Key('toggle-first')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('login-suffix')), 'AB12');
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('setup-pin')), '2468');
      await tester.enterText(find.byKey(const Key('setup-confirm')), '1357');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer et continuer'));
      await tester.pumpAndSettle();
      expect(find.text('Les deux codes ne correspondent pas.'), findsOneWidget);
      expect(ctx.adapter.requests.any((r) => r.path.endsWith('/pin-setup')), isFalse);
    });

    testWidgets('mauvais identifiants : message générique, aucun détail sur le compte', (tester) async {
      await pumpApp(tester, routes: {
        ...baseRoutes(),
        'POST /api/mobile/v1/auth/login': (o) => const FakeReply(403, {
              'error': {'code': 'invalid_credentials', 'message': 'x'}
            }),
      });
      await goToLogin(tester);
      await tester.enterText(find.byType(TextField).first, '770000009');
      await tester.enterText(find.byKey(const Key('login-pin')), '0000');
      await tester.pumpAndSettle();
      expect(find.textContaining('Identifiants incorrects'), findsOneWidget);
      expect(find.text('Espace membre'), findsOneWidget, reason: 'reste sur la connexion');
    });

    testWidgets('trop de tentatives : durée d\'attente affichée en minutes', (tester) async {
      await pumpApp(tester, routes: {
        ...baseRoutes(),
        'POST /api/mobile/v1/auth/login': (o) => const FakeReply(429, {
              'error': {'code': 'rate_limited', 'message': 'x'}
            }, {
              'retry-after': '720'
            }),
      });
      await goToLogin(tester);
      await tester.enterText(find.byType(TextField).first, '770000009');
      await tester.enterText(find.byKey(const Key('login-pin')), '1234');
      await tester.pumpAndSettle();
      expect(find.text('Trop de tentatives. Réessayez dans 12 min.'), findsOneWidget);
    });

    testWidgets('réseau coupé pendant la connexion : message réseau, pas de plantage', (tester) async {
      await pumpApp(tester, routes: {...baseRoutes(), 'POST /api/mobile/v1/auth/login': networkDown()});
      await goToLogin(tester);
      await tester.enterText(find.byType(TextField).first, '770000009');
      await tester.enterText(find.byKey(const Key('login-pin')), '1234');
      await tester.pumpAndSettle();
      expect(find.textContaining('Connexion impossible'), findsOneWidget);
      expect(tester.widget<TextField>(find.byKey(const Key('login-pin'))).controller!.text, '1234');
      expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text, '770000009');
    });

    testWidgets('numéro trop court : rejeté sans appel réseau', (tester) async {
      final ctx = await pumpApp(tester, routes: baseRoutes());
      await goToLogin(tester);
      await tester.enterText(find.byType(TextField).first, '123');
      await tester.enterText(find.byKey(const Key('login-pin')), '1234');
      await tester.pumpAndSettle();
      expect(find.textContaining('Identifiants incorrects'), findsOneWidget);
      expect(ctx.adapter.requests.any((r) => r.path.endsWith('/auth/login')), isFalse);
    });
  });

  group('session et rubriques membre', () {
    Map<String, FakeHandler> memberRoutes({List<Map<String, dynamic>> versements = const []}) => {
          ...baseRoutes(),
          'GET /api/mobile/v1/me': (o) => FakeReply(200, {'member': memberJson(versements: versements)}),
          'POST /api/mobile/v1/auth/logout': (o) => const FakeReply(200, {'ok': true}),
        };

    testWidgets('session reprise au lancement : accueil connecté sans ressaisie', (tester) async {
      await pumpApp(tester, routes: memberRoutes(), tokens: _session);
      expect(find.text('Salam, Awa'), findsOneWidget);
    });

    testWidgets('visiteur sur une rubrique membre : invitation à se connecter', (tester) async {
      await pumpApp(tester, routes: baseRoutes());
      await tester.tap(find.text('Mon compte'));
      await tester.pumpAndSettle();
      expect(find.text('Connexion requise'), findsOneWidget);
    });

    testWidgets('serveur injoignable avec une session : écran hors ligne puis reprise', (tester) async {
      var online = false;
      await pumpApp(tester, tokens: _session, routes: {
        ...baseRoutes(),
        'GET /api/mobile/v1/me': (o) =>
            online ? FakeReply(200, {'member': memberJson()}) : (throw networkDownError(o)),
      });
      expect(find.text('Vous êtes hors ligne'), findsOneWidget);
      online = true;
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(find.text('Salam, Awa'), findsOneWidget);
    });

    testWidgets('statut de cotisation du mois : « À jour » si payé', (tester) async {
      final now = DateTime.now();
      final periode = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      await pumpApp(tester, routes: memberRoutes(versements: [_paid(periode, 'ce mois')]), tokens: _session);
      expect(find.text('À jour'), findsOneWidget);
    });

    testWidgets('statut de cotisation du mois : « À régler » si aucun versement', (tester) async {
      await pumpApp(tester, routes: memberRoutes(), tokens: _session);
      expect(find.text('À régler'), findsOneWidget);
    });

    testWidgets('historique des versements, montants formatés', (tester) async {
      await pumpApp(tester,
          routes: memberRoutes(versements: [_paid('2026-10', 'octobre 2026')]), tokens: _session);
      await tester.tap(find.text('Cotisations'));
      await tester.pumpAndSettle();
      expect(find.text('octobre 2026'), findsOneWidget);
      expect(find.text('1 400 FCFA'), findsOneWidget);
      expect(find.text('Payé'), findsOneWidget);
    });

    testWidgets('historique vide : état « Aucun versement »', (tester) async {
      await pumpApp(tester, routes: memberRoutes(), tokens: _session);
      await tester.tap(find.text('Cotisations'));
      await tester.pumpAndSettle();
      expect(find.text('Aucun versement'), findsOneWidget);
    });

    testWidgets('déconnexion : jetons effacés, retour visiteur', (tester) async {
      final ctx = await pumpApp(tester, routes: memberRoutes(), tokens: _session);
      await tester.tap(find.text('Mon compte'));
      await tester.pumpAndSettle();
      expect(find.text('Awa Diop'), findsOneWidget);
      final logout = find.byKey(const Key('logout'));
      await tester.scrollUntilVisible(logout, 200);
      await tester.tap(logout);
      await tester.pumpAndSettle();
      expect(await ctx.store.read(), isNull);
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('session révoquée côté serveur en cours d\'usage : retour visiteur', (tester) async {
      final ctx = await pumpApp(tester, routes: memberRoutes(), tokens: _session);
      expect(find.text('Salam, Awa'), findsOneWidget);
      ctx.container.read(sessionEventsProvider).notifyExpired();
      await tester.pumpAndSettle();
      expect(find.text('Salam, Awa'), findsNothing);
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('Barkelu : boutique vide = « Bientôt disponible » (état réel actuel)', (tester) async {
      await pumpApp(tester, routes: baseRoutes());
      await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Bientôt disponible'), findsOneWidget);
    });

    testWidgets('Barkelu : liste les produits publiés avec leur prix', (tester) async {
      await pumpApp(tester, routes: {
        ...baseRoutes(),
        'GET /api/store/products': (o) => const FakeReply(200, {
              'products': [
                {'name': 'Tote Bag', 'price': 4000}
              ],
              'total': 1
            }),
      });
      await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Tote Bag'), findsOneWidget);
      expect(find.text('4 000 FCFA'), findsOneWidget);
    });
  });

  testWidgets('accueil, connexion et téléphone LTR à 320 dp et 200 % en arabe sombre', (tester) async {
    await pumpApp(
      tester,
      routes: baseRoutes(),
      prefs: {'pref.lang': 'ar', 'pref.theme': 'dark'},
      width: 320,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('home-join')), findsOneWidget);
    final login = find.byKey(const Key('home-login'));
    await tester.scrollUntilVisible(login, 180, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(login.hitTestable());
    await tester.pumpAndSettle();
    final phone = tester.widget<TextField>(find.byType(TextField).first);
    expect(phone.textDirection, TextDirection.ltr);
    expect(tester.takeException(), isNull);
  });

  group('langue arabe (RTL) et préférences', () {
    testWidgets('arabe choisi : sens de lecture inversé et libellés arabes de la config', (tester) async {
      await pumpApp(tester, routes: baseRoutes(), prefs: {'pref.lang': 'ar'});
      expect(find.text('الرئيسية'), findsOneWidget);
      final dir = Directionality.of(tester.element(find.byType(Scaffold).first));
      expect(dir, TextDirection.rtl);
    });

    testWidgets('français par défaut : sens de lecture normal', (tester) async {
      await pumpApp(tester, routes: baseRoutes());
      final dir = Directionality.of(tester.element(find.byType(Scaffold).first));
      expect(dir, TextDirection.ltr);
    });

    testWidgets('changer de langue dans Mon compte : appliqué et mémorisé', (tester) async {
      final ctx = await pumpApp(tester, tokens: _session, routes: {
        ...baseRoutes(),
        'GET /api/mobile/v1/me': (o) => FakeReply(200, {'member': memberJson()}),
      });
      await tester.tap(find.text('Mon compte'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();
      expect(find.text('حسابي'), findsWidgets);
      expect(ctx.container.read(languagePrefProvider), 'ar');
      expect((await SharedPreferences.getInstance()).getString('pref.lang'), 'ar');
    });
  });
}
