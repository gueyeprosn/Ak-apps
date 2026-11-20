import 'dart:convert';

import 'package:ahloulkhidmah_mobile/core/api/api_error.dart';
import 'package:ahloulkhidmah_mobile/core/auth/auth_repository.dart';
import 'package:ahloulkhidmah_mobile/core/auth/token_store.dart';
import 'package:ahloulkhidmah_mobile/core/config/config_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_adapter.dart';
import '../support/harness.dart';

const _old = AuthTokens(accessToken: 'old', refreshToken: 'r1');

void main() {
  group('renouvellement automatique du jeton', () {
    test('401 → renouvellement → la requête est rejouée avec le nouveau jeton', () async {
      final h = buildClients({
        'GET /api/mobile/v1/me': (o) => o.headers['Authorization'] == 'Bearer new'
            ? FakeReply(200, {'member': memberJson()})
            : const FakeReply(401, {'error': {'code': 'unauthorized', 'message': 'x'}}),
        'POST /api/mobile/v1/auth/refresh': (o) => const FakeReply(200, {'accessToken': 'new', 'refreshToken': 'r2'}),
      }, tokens: _old);

      final res = await h.clients.authed.get<Map<String, dynamic>>('/api/mobile/v1/me');
      expect(res.statusCode, 200);
      expect(h.adapter.count('POST /api/mobile/v1/auth/refresh'), 1);
      final stored = await h.store.read();
      expect(stored!.accessToken, 'new');
      expect(stored.refreshToken, 'r2', reason: 'le jeton de renouvellement est rotatif');
    });

    test('trois requêtes simultanées en 401 → UN SEUL renouvellement', () async {
      final h = buildClients({
        'GET /api/mobile/v1/me': (o) => o.headers['Authorization'] == 'Bearer new'
            ? FakeReply(200, {'member': memberJson()})
            : const FakeReply(401, {'error': {'code': 'unauthorized', 'message': 'x'}}),
        'POST /api/mobile/v1/auth/refresh': (o) async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return const FakeReply(200, {'accessToken': 'new', 'refreshToken': 'r2'});
        },
      }, tokens: _old);

      final results = await Future.wait([
        h.clients.authed.get<dynamic>('/api/mobile/v1/me'),
        h.clients.authed.get<dynamic>('/api/mobile/v1/me'),
        h.clients.authed.get<dynamic>('/api/mobile/v1/me'),
      ]);
      expect(results.map((r) => r.statusCode), [200, 200, 200]);
      expect(h.adapter.count('POST /api/mobile/v1/auth/refresh'), 1,
          reason: 'deux renouvellements avec le même jeton révoqueraient la session');
    });

    test('renouvellement refusé → session terminée, jetons effacés, événement émis', () async {
      final h = buildClients({
        'GET /api/mobile/v1/me': (o) => const FakeReply(401, {'error': {'code': 'unauthorized', 'message': 'x'}}),
        'POST /api/mobile/v1/auth/refresh': (o) => const FakeReply(401, {'error': {'code': 'invalid_refresh', 'message': 'x'}}),
      }, tokens: _old);
      var expired = 0;
      h.events.expired.listen((_) => expired++);

      await expectLater(
        h.clients.authed.get<dynamic>('/api/mobile/v1/me'),
        throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 401)),
      );
      await Future<void>.delayed(Duration.zero);
      expect(await h.store.read(), isNull);
      expect(expired, 1);
    });

    test('panne réseau pendant le renouvellement → la session N\'EST PAS perdue', () async {
      final h = buildClients({
        'GET /api/mobile/v1/me': (o) => const FakeReply(401, {'error': {'code': 'unauthorized', 'message': 'x'}}),
        'POST /api/mobile/v1/auth/refresh': networkDown(),
      }, tokens: _old);
      var expired = 0;
      h.events.expired.listen((_) => expired++);

      await expectLater(
        h.clients.authed.get<dynamic>('/api/mobile/v1/me'),
        throwsA(isA<DioException>().having((e) => e.type, 'type', DioExceptionType.connectionError)),
      );
      expect(await h.store.read(), isNotNull, reason: 'une panne réseau ne déconnecte jamais');
      expect(expired, 0);
    });

    test('pas de boucle : un 401 persistant après renouvellement n\'est rejoué qu\'une fois', () async {
      final h = buildClients({
        'GET /api/mobile/v1/me': (o) => const FakeReply(401, {'error': {'code': 'unauthorized', 'message': 'x'}}),
        'POST /api/mobile/v1/auth/refresh': (o) => const FakeReply(200, {'accessToken': 'new', 'refreshToken': 'r2'}),
      }, tokens: _old);

      await expectLater(h.clients.authed.get<dynamic>('/api/mobile/v1/me'), throwsA(isA<DioException>()));
      expect(h.adapter.count('GET /api/mobile/v1/me'), 2);
      expect(h.adapter.count('POST /api/mobile/v1/auth/refresh'), 1);
    });

    test('les requêtes sans authentification ne portent jamais le jeton', () async {
      final h = buildClients({
        'GET /api/mobile/v1/config': (o) => FakeReply(200, configJson()),
      }, tokens: _old);
      await h.clients.plain.get<dynamic>('/api/mobile/v1/config');
      expect(h.adapter.requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('chaque requête annonce plateforme et version', () async {
      final h = buildClients({'GET /api/mobile/v1/config': (o) => FakeReply(200, configJson())});
      await h.clients.plain.get<dynamic>('/api/mobile/v1/config');
      final headers = h.adapter.requests.single.headers;
      expect(headers['X-Platform'], 'android');
      expect(headers['X-App-Version'], '1.0.0');
    });
  });

  group('erreurs sur requête en octets (images)', () {
    test('le code d\'erreur JSON du serveur est conservé', () async {
      final h = buildClients({
        'GET /img': (o) => const FakeReply(409, {'error': {'code': 'card_unavailable', 'message': 'indisponible'}}),
      });
      try {
        await h.clients.plain.get<List<int>>('/img', options: Options(responseType: ResponseType.bytes));
        fail('aurait dû échouer');
      } on DioException catch (e) {
        final api = e.toApiException();
        expect(api.code, 'card_unavailable');
        expect(api.status, 409);
      }
    });

    test('un corps non JSON ne plante pas : erreur « unknown »', () async {
      final h = buildClients({'GET /img': (o) => const FakeReply(500, 'pas du json')});
      try {
        await h.clients.plain.get<List<int>>('/img', options: Options(responseType: ResponseType.bytes));
        fail('aurait dû échouer');
      } on DioException catch (e) {
        expect(e.toApiException().code, 'unknown');
      }
    });
  });

  group('AuthRepository', () {
    test('connexion par PIN : ouvre la session et range les jetons', () async {
      final h = buildClients({
        'POST /api/mobile/v1/auth/login': (o) => FakeReply(200, {
              'status': 'ok', 'accessToken': 'a1', 'refreshToken': 'r1', 'expiresIn': 900, 'member': memberJson(),
            }),
      });
      final repo = AuthRepository(h.clients, h.store, testInfo);
      final result = await repo.login(tel: '+221770000001', code: '1234');
      expect(result, isA<LoginSuccess>());
      expect((await h.store.read())!.accessToken, 'a1');
      final sent = h.adapter.requests.single.data as Map;
      expect(sent['tel'], '+221770000001');
      expect(sent['suffix'], '1234', reason: 'le contrat serveur nomme ce champ `suffix`');
      expect(sent['device'], {'platform': 'android', 'appVersion': '1.0.0'});
    });

    test('premier accès : AUCUNE session, seulement un jeton de création de PIN', () async {
      final h = buildClients({
        'POST /api/mobile/v1/auth/login': (o) => const FakeReply(200, {'status': 'pin_setup_required', 'setupToken': 'setup-1'}),
      });
      final repo = AuthRepository(h.clients, h.store, testInfo);
      final result = await repo.login(tel: '+221770000002', code: 'AB12');
      expect(result, isA<PinSetupRequired>());
      expect((result as PinSetupRequired).setupToken, 'setup-1');
      expect(await h.store.read(), isNull, reason: 'le suffixe du badge n\'ouvre jamais de session');
    });

    test('création du PIN : jeton à usage unique en en-tête, session ouverte ensuite', () async {
      final h = buildClients({
        'POST /api/mobile/v1/auth/pin-setup': (o) => FakeReply(200, {
              'status': 'ok', 'accessToken': 'a2', 'refreshToken': 'r2', 'expiresIn': 900, 'member': memberJson(),
            }),
      });
      final repo = AuthRepository(h.clients, h.store, testInfo);
      final member = await repo.setupPin(setupToken: 'setup-1', pin: '2468', pinConfirm: '2468');
      expect(member.name, 'Awa Diop');
      expect(h.adapter.requests.single.headers['Authorization'], 'Bearer setup-1');
      expect((await h.store.read())!.refreshToken, 'r2');
    });

    test('mauvais identifiants : erreur normalisée, aucun jeton stocké', () async {
      final h = buildClients({
        'POST /api/mobile/v1/auth/login': (o) => const FakeReply(403, {'error': {'code': 'invalid_credentials', 'message': 'Identifiants incorrects.'}}),
      });
      final repo = AuthRepository(h.clients, h.store, testInfo);
      await expectLater(
        repo.login(tel: '+221700000000', code: '0000'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'invalid_credentials')),
      );
      expect(await h.store.read(), isNull);
    });

    test('429 : durée d\'attente lue dans Retry-After', () async {
      final h = buildClients({
        'POST /api/mobile/v1/auth/login': (o) => const FakeReply(
              429, {'error': {'code': 'rate_limited', 'message': 'x'}}, {'retry-after': '720'}),
      });
      final repo = AuthRepository(h.clients, h.store, testInfo);
      await expectLater(
        repo.login(tel: '+221770000001', code: '1111'),
        throwsA(isA<ApiException>()
            .having((e) => e.isRateLimited, 'rateLimited', isTrue)
            .having((e) => e.retryAfter, 'retryAfter', const Duration(seconds: 720))),
      );
    });

    test('déconnexion hors ligne : les jetons locaux sont effacés quand même', () async {
      final h = buildClients({'POST /api/mobile/v1/auth/logout': networkDown()}, tokens: _old);
      final repo = AuthRepository(h.clients, h.store, testInfo);
      await repo.logout();
      expect(await h.store.read(), isNull);
    });

    test('déconnexion en ligne : le serveur reçoit le jeton de renouvellement', () async {
      final h = buildClients({'POST /api/mobile/v1/auth/logout': (o) => const FakeReply(200, {'ok': true})}, tokens: _old);
      await AuthRepository(h.clients, h.store, testInfo).logout();
      expect((h.adapter.requests.single.data as Map)['refreshToken'], 'r1');
      expect(await h.store.read(), isNull);
    });
  });

  group('ConfigRepository', () {
    Future<ConfigRepository> repo(Map<String, FakeHandler> routes, [Map<String, Object> prefs = const {}]) async {
      SharedPreferences.setMockInitialValues(prefs);
      final h = buildClients(routes);
      return ConfigRepository(h.clients.plain, await SharedPreferences.getInstance());
    }

    test('200 : configuration du réseau, mise en cache avec son ETag', () async {
      final r = await repo({'GET /api/mobile/v1/config': (o) => FakeReply(200, configJson(version: 7), {'etag': '"cfg-7"'})});
      final load = await r.load();
      expect(load.source, ConfigSource.network);
      expect(load.config.version, 7);
    });

    test('304 : le cache est renvoyé (validation par ETag)', () async {
      final routes = <String, FakeHandler>{};
      SharedPreferences.setMockInitialValues({'cfg.v1.json': jsonEncode(configJson(version: 7)), 'cfg.v1.etag': '"cfg-7"'});
      final h = buildClients(routes);
      routes['GET /api/mobile/v1/config'] = (o) {
        expect(o.headers['If-None-Match'], '"cfg-7"');
        return const FakeReply(304);
      };
      final load = await ConfigRepository(h.clients.plain, await SharedPreferences.getInstance()).load();
      expect(load.source, ConfigSource.cache);
      expect(load.config.version, 7);
    });

    test('hors ligne avec cache : dernière configuration valide', () async {
      final r = await repo({'GET /api/mobile/v1/config': networkDown()}, {'cfg.v1.json': jsonEncode(configJson(version: 5))});
      final load = await r.load();
      expect(load.source, ConfigSource.cache);
      expect(load.config.version, 5);
    });

    test('hors ligne sans cache : configuration embarquée, jamais d\'erreur', () async {
      final r = await repo({'GET /api/mobile/v1/config': networkDown()});
      final load = await r.load();
      expect(load.source, ConfigSource.embedded);
      expect(load.config.visibleTabs, isNotEmpty);
    });

    test('configuration reçue invalide : on garde la dernière valide', () async {
      final r = await repo(
        {'GET /api/mobile/v1/config': (o) => const FakeReply(200, {'tabs': []})},
        {'cfg.v1.json': jsonEncode(configJson(version: 5))},
      );
      final load = await r.load();
      expect(load.source, ConfigSource.cache);
      expect(load.config.version, 5);
    });

    test('cache corrompu : ignoré sans planter', () async {
      final r = await repo({'GET /api/mobile/v1/config': networkDown()}, {'cfg.v1.json': '{pas du json'});
      expect((await r.load()).source, ConfigSource.embedded);
    });

    test('erreur serveur 500 : repli sur le cache', () async {
      final r = await repo(
        {'GET /api/mobile/v1/config': (o) => const FakeReply(500, {'error': 'boom'})},
        {'cfg.v1.json': jsonEncode(configJson(version: 5))},
      );
      expect((await r.load()).source, ConfigSource.cache);
    });
  });
}
