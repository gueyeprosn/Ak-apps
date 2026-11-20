// Tests d'intégration : le VRAI client Dart contre le VRAI serveur (staging).
//
// Ignorés tant que l'URL n'est pas fournie :
//
//   flutter test test/integration \
//     --dart-define=STAGING_URL=http://127.0.0.1:3001 \
//     --dart-define=STAGING_TEL=+221770000001 --dart-define=STAGING_PIN=1234 \
//     --dart-define=STAGING_TEL_NOPIN=+22177... --dart-define=STAGING_SUFFIX=XXXX
//
// Uniquement contre un serveur de TEST à base anonymisée. Jamais la production.
@TestOn('vm')
library;

import 'dart:math';

import 'package:ahloulkhidmah_mobile/core/api/api_client.dart';
import 'package:ahloulkhidmah_mobile/core/api/api_error.dart';
import 'package:ahloulkhidmah_mobile/core/auth/auth_repository.dart';
import 'package:ahloulkhidmah_mobile/core/auth/token_store.dart';
import 'package:dio/dio.dart' show DioException;
import 'package:ahloulkhidmah_mobile/core/config/config_repository.dart';
import 'package:ahloulkhidmah_mobile/core/config/env.dart';
import 'package:ahloulkhidmah_mobile/features/card/card_controller.dart';
import 'package:ahloulkhidmah_mobile/features/payment/payment_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _url = String.fromEnvironment('STAGING_URL');
const _tel = String.fromEnvironment('STAGING_TEL');
const _pin = String.fromEnvironment('STAGING_PIN');
const _telNoPin = String.fromEnvironment('STAGING_TEL_NOPIN');
const _suffix = String.fromEnvironment('STAGING_SUFFIX');
const _pendingPaymentId = String.fromEnvironment('STAGING_PENDING_PAYMENT');

const _info = ClientInfo(platform: 'android', appVersion: '1.0.0');

({ApiClients clients, MemoryTokenStore store, AuthRepository auth}) _build() {
  final store = MemoryTokenStore();
  final clients = createApiClients(
    env: const AppEnv(name: 'staging', apiBaseUrl: _url, allowInsecureHttp: true),
    store: store,
    events: SessionEvents(),
    info: _info,
  );
  return (clients: clients, store: store, auth: AuthRepository(clients, store, _info));
}

void main() {
  final skip = _url.isEmpty ? 'STAGING_URL non fourni : test d\'intégration ignoré' : null;

  group('contre le serveur staging', skip: skip, () {
    test('configuration distante : contrat respecté, puis 304 via ETag', () async {
      SharedPreferences.setMockInitialValues({});
      final c = _build().clients;
      final repo = ConfigRepository(c.plain, await SharedPreferences.getInstance());

      final first = await repo.load();
      expect(first.source, ConfigSource.network);
      expect(first.config.visibleTabs, isNotEmpty);
      expect(first.config.tabs.map((t) => t.id), containsAll(['home', 'account']));

      final second = await repo.load();
      expect(second.source, ConfigSource.cache, reason: 'le serveur répond 304 à If-None-Match');
      expect(second.config.version, first.config.version);
    });

    test('connexion par PIN, profil, puis renouvellement automatique d\'un jeton invalide', () async {
      final t = _build();
      final result = await t.auth.login(tel: _tel, code: _pin);
      expect(result, isA<LoginSuccess>());
      final member = (result as LoginSuccess).member;
      expect(member.id, isNotEmpty);
      expect(member.hasPin, isTrue);

      final me = await t.auth.me();
      expect(me.id, member.id);

      // Jeton d'accès corrompu : le client doit se renouveler seul et réussir.
      final tokens = (await t.store.read())!;
      await t.store.write(AuthTokens(accessToken: 'jeton-invalide', refreshToken: tokens.refreshToken));
      final again = await t.auth.me();
      expect(again.id, member.id);
      final renewed = (await t.store.read())!;
      expect(renewed.accessToken, isNot('jeton-invalide'));
      expect(renewed.refreshToken, isNot(tokens.refreshToken), reason: 'jeton de renouvellement rotatif');

      await t.auth.logout();
      expect(await t.store.read(), isNull);
    });

    test('mauvais PIN : refusé avec un code stable, aucun jeton', () async {
      final t = _build();
      await expectLater(
        t.auth.login(tel: _tel, code: '0000'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'invalid_credentials')),
      );
      expect(await t.store.read(), isNull);
    });

    test('numéro inconnu : même réponse qu\'un mauvais PIN (pas d\'énumération)', () async {
      final t = _build();
      final rnd = Random();
      final unknown = '+22177${(1000000 + rnd.nextInt(8999999))}';
      await expectLater(
        t.auth.login(tel: unknown, code: '1234'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'invalid_credentials')
            .having((e) => e.status, 'status', 403)),
      );
    });

    test('premier accès (suffixe du badge) : aucun jeton de session, seulement la création du PIN', () async {
      final t = _build();
      final result = await t.auth.login(tel: _telNoPin, code: _suffix);
      expect(result, isA<PinSetupRequired>());
      expect((result as PinSetupRequired).setupToken, isNotEmpty);
      expect(await t.store.read(), isNull, reason: 'le suffixe n\'ouvre jamais de session mobile');
    }, skip: _telNoPin.isEmpty || _suffix.isEmpty ? 'STAGING_TEL_NOPIN / STAGING_SUFFIX non fournis' : null);

    test('blocage après 5 essais sur un même numéro (429 + Retry-After)', () async {
      final t = _build();
      final unknown = '+22177${(1000000 + Random().nextInt(8999999))}';
      for (var i = 0; i < 5; i++) {
        await expectLater(t.auth.login(tel: unknown, code: '0000'), throwsA(isA<ApiException>()));
      }
      await expectLater(
        t.auth.login(tel: unknown, code: '0000'),
        throwsA(isA<ApiException>()
            .having((e) => e.isRateLimited, 'rateLimited', isTrue)
            .having((e) => e.retryAfter, 'retryAfter', isNotNull)),
      );
    });

    test('profil sans jeton : refusé (401), rien n\'est exposé', () async {
      final t = _build();
      await expectLater(
        t.auth.me(),
        throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'unauthorized', isTrue)),
      );
    });

    test('catalogue Barkelu public : accessible sans session', () async {
      final t = _build();
      final res = await t.clients.plain.get<Map<String, dynamic>>('/api/store/products');
      expect(res.statusCode, 200);
      expect(res.data!['products'], isA<List<dynamic>>());
    });

    group('paiement de cotisation (PayDunya non configuré sur le staging)', () {
      Future<({PaymentRepository pay, ApiClients clients})> loggedIn() async {
        final t = _build();
        await t.auth.login(tel: _tel, code: _pin);
        return (pay: PaymentRepository(t.clients), clients: t.clients);
      }

      test('sans session : refusé (401) sur chacune des 4 routes', () async {
        final c = _build().clients;
        final repo = PaymentRepository(c);
        for (final call in <Future<Object?> Function()>[
          () => repo.due(),
          () => repo.create(1),
          () => repo.startSoftpay('x', PayMethod.wave),
          () => repo.status('x'),
        ]) {
          await expectLater(call(), throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'unauthorized', isTrue)));
        }
      });

      test('mois dus : les plus récents, montant mensuel, paiements désactivés faute de clés', () async {
        final t = await loggedIn();
        final due = await t.pay.due();
        expect(due.unitAmount, greaterThanOrEqualTo(100));
        expect(due.maxMonths, 6);
        expect(due.periods.length, lessThanOrEqualTo(6));
        final periods = due.periods.map((p) => p.periode).toList();
        expect(periods, [...periods]..sort(), reason: 'ordre croissant');
        final now = DateTime.now();
        final current = '${now.year}-${now.month.toString().padLeft(2, '0')}';
        expect(periods.every((p) => p.compareTo(current) <= 0), isTrue, reason: 'jamais de mois à l\'avance');
        expect(due.paymentsEnabled, isFalse, reason: 'le staging n\'a aucune clé PayDunya : c\'est voulu');
      });

      test('création : 503 « payments_unavailable » (aucune clé), jamais une facture fantôme', () async {
        final t = await loggedIn();
        await expectLater(
          t.pay.create(1),
          throwsA(isA<ApiException>().having((e) => e.code, 'code', 'payments_unavailable').having((e) => e.status, 'status', 503)),
        );
      });

      test('nombre de mois invalide : refusé par le serveur (400)', () async {
        final t = await loggedIn();
        await expectLater(
          t.clients.authed.post<dynamic>('/api/mobile/v1/payments/cotisation', data: {'monthsCount': 9999}),
          throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 400)),
        );
      });

      test('paiement inconnu : 404', () async {
        final t = await loggedIn();
        await expectLater(
          t.pay.status('paiement-inexistant'),
          throwsA(isA<ApiException>().having((e) => e.status, 'status', 404)),
        );
      });

      test('statut d\'un paiement du membre resté « pending » : le serveur ne le déclare jamais payé', () async {
        final t = await loggedIn();
        final snap = await t.pay.status(_pendingPaymentId);
        expect(snap.state, PaymentState.pending);
        expect(snap.receiptUrl, isNull);
      }, skip: _pendingPaymentId.isEmpty ? 'STAGING_PENDING_PAYMENT non fourni' : null);
    });

    group('carte membre', () {
      Future<CardRepository> loggedIn() async {
        final t = _build();
        await t.auth.login(tel: _tel, code: _pin);
        return CardRepository(t.clients);
      }

      test('sans session : refusée (401)', () async {
        final repo = CardRepository(_build().clients);
        await expectLater(repo.fetch(), throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'unauthorized', isTrue)));
      });

      test('affichage : WebP léger (< 300 Ko) avec ETag', () async {
        final repo = await loggedIn();
        final res = await repo.fetch();
        final b = res.image!.bytes;
        expect(String.fromCharCodes(b.sublist(0, 4)), 'RIFF');
        expect(String.fromCharCodes(b.sublist(8, 12)), 'WEBP');
        expect(b.length, lessThan(300 * 1024));
        expect(res.image!.etag, matches(RegExp(r'^"card-[0-9a-f]{32}"$')));
      });

      test('revalidation : If-None-Match → 304, rien n\'est retéléchargé', () async {
        final repo = await loggedIn();
        final first = await repo.fetch();
        final again = await repo.fetch(etag: first.image!.etag);
        expect(again.notModified, isTrue);
        expect(again.image, isNull);
      });

      test('partage : PNG d\'origine en pleine résolution', () async {
        final repo = await loggedIn();
        final res = await repo.fetch(full: true);
        expect(res.image!.bytes.sublist(0, 8), [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
        expect(res.image!.bytes.length, greaterThan(500 * 1024));
      });
    });
  });
}
