import 'dart:async';

import 'package:ahloulkhidmah_mobile/core/auth/token_store.dart';
import 'package:ahloulkhidmah_mobile/core/providers.dart';
import 'package:ahloulkhidmah_mobile/core/storage/card_cache.dart';
import 'package:ahloulkhidmah_mobile/features/notifications/presentation/push_controller.dart';
import 'package:ahloulkhidmah_mobile/features/notifications/domain/push_models.dart';
import 'package:ahloulkhidmah_mobile/features/notifications/domain/push_platform.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_adapter.dart';
import '../../support/harness.dart';

class FakePush implements PushPlatform {
  FakePush({this.granted = true, this.token = 'tok-1234567890'});
  bool granted;
  String? token;
  bool deleted = false;
  final refresh = StreamController<String>.broadcast();
  @override
  bool get isAvailable => true;
  @override
  Future<bool> requestPermission() async => granted;
  @override
  Future<bool> hasPermission() async => granted;
  @override
  Future<void> setAutoInitEnabled(bool enabled) async {}

  @override
  Future<String?> getToken() async => token;
  @override
  Stream<String> get onTokenRefresh => refresh.stream;
  @override
  Stream<PushMessage> get onForeground => const Stream.empty();
  @override
  Stream<PushMessage> get onOpened => const Stream.empty();
  @override
  Future<PushMessage?> initialMessage() async => null;
  @override
  Future<void> deleteToken() async => deleted = true;
}

Future<({ProviderContainer c, FakeAdapter adapter, FakePush push})> setup({
  FakePush? push,
  Map<String, Object>? prefsValues,
  int registerStatus = 200,
}) async {
  SharedPreferences.setMockInitialValues(prefsValues ?? {});
  final prefs = await SharedPreferences.getInstance();
  final p = push ?? FakePush();
  final built = buildClients({
    'GET /api/mobile/v1/me': (_) => FakeReply(200, {'member': memberJson()}),
    'POST /api/mobile/v1/auth/logout': (_) => const FakeReply(200, {'ok': true}),
    'POST /api/mobile/v1/devices': (_) => FakeReply(registerStatus, {'ok': registerStatus == 200}),
    'DELETE /api/mobile/v1/devices': (_) => const FakeReply(200, {'ok': true}),
  }, tokens: const AuthTokens(accessToken: 'a', refreshToken: 'r'));
  final c = ProviderContainer(overrides: [
    tokenStoreProvider.overrideWithValue(built.store),
    cardCacheProvider.overrideWithValue(MemoryCardCache()),
    sharedPrefsProvider.overrideWithValue(prefs),
    clientInfoProvider.overrideWithValue(testInfo),
    pushPlatformProvider.overrideWithValue(p),
    apiClientsProvider.overrideWithValue(built.clients),
  ]);
  addTearDown(p.refresh.close);
  addTearDown(c.dispose);
  await c.read(authControllerProvider.notifier).restore();
  return (c: c, adapter: built.adapter, push: p);
}

void main() {
  group('safePushRoute', () {
    test('accepte uniquement des chemins internes connus', () {
      expect(safePushRoute('/card'), '/card');
      expect(safePushRoute('/pay'), '/pay');
      expect(safePushRoute('/t/home'), '/t/home');
      expect(safePushRoute('/t/cotisations'), '/t/cotisations');
    });
    test('refuse URL, schéma, chemin inconnu ou type inattendu', () {
      for (final bad in [
        'https://evil.example',
        '//evil.example',
        'javascript:alert(1)',
        '/admin',
        '/t/',
        '/t/../pay',
        '/t/UPPER',
        '',
        null,
        42,
      ]) {
        expect(safePushRoute(bad), isNull, reason: '$bad');
      }
    });
  });

  group('PushController', () {
    test('sans Firebase configuré : indisponible, aucun appel réseau', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final built = buildClients({});
      final c = ProviderContainer(overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        clientInfoProvider.overrideWithValue(testInfo),
        apiClientsProvider.overrideWithValue(built.clients),
      ]);
      addTearDown(c.dispose);
      expect(c.read(pushControllerProvider), PushStatus.unavailable);
      expect(await c.read(pushControllerProvider.notifier).enable(), isFalse);
      expect(built.adapter.requests, isEmpty);
    });

    test('activer : demande l\'autorisation, enregistre le jeton (android) et mémorise le choix', () async {
      final s = await setup();
      expect(s.c.read(pushControllerProvider), PushStatus.off);
      expect(await s.c.read(pushControllerProvider.notifier).enable(), isTrue);
      expect(s.c.read(pushControllerProvider), PushStatus.on);
      expect(s.adapter.count('POST /api/mobile/v1/devices'), 1);
      final registration = s.adapter.requests.singleWhere((request) => request.path.endsWith('/devices'));
      final body = registration.data as Map;
      expect(registration.headers['Authorization'], 'Bearer a');
      expect(body['token'], 'tok-1234567890');
      expect(body['platform'], 'android');
      expect(body['appVersion'], '1.0.0');
      expect(['fr', 'ar'], contains(body['locale']));
      expect(s.c.read(sharedPrefsProvider).getBool('pref.push'), isTrue);
    });

    test('autorisation refusée : état « refusé », rien n\'est envoyé', () async {
      final s = await setup(push: FakePush(granted: false));
      expect(await s.c.read(pushControllerProvider.notifier).enable(), isFalse);
      expect(s.c.read(pushControllerProvider), PushStatus.denied);
      expect(s.adapter.count('POST /api/mobile/v1/devices'), 0);
      expect(s.c.read(sharedPrefsProvider).getBool('pref.push'), isNull);
    });

    test('pas de jeton (simulateur iOS, APNs absent) : reste désactivé', () async {
      final s = await setup(push: FakePush(token: null));
      expect(await s.c.read(pushControllerProvider.notifier).enable(), isFalse);
      expect(s.c.read(pushControllerProvider), PushStatus.off);
      expect(s.adapter.count('POST /api/mobile/v1/devices'), 0);
    });

    test('inscription refusée par le serveur : notifications désactivées', () async {
      final s = await setup(registerStatus: 500);
      expect(await s.c.read(pushControllerProvider.notifier).enable(), isFalse);
      expect(s.c.read(pushControllerProvider), PushStatus.off);
      expect(s.c.read(sharedPrefsProvider).getBool('pref.push'), isNull);
      expect(s.push.deleted, isTrue);
    });

    test('fermeture de session : révoque l’appareil associé', () async {
      final s = await setup(prefsValues: {'pref.push': true});
      final push = s.c.read(pushControllerProvider.notifier);
      expect(await push.resume(), isTrue);
      await s.c.read(authControllerProvider.notifier).logout(pushToken: push.deviceToken);
      final logout = s.adapter.requests.singleWhere((request) => request.path.endsWith('/logout'));
      expect((logout.data as Map)['pushToken'], 'tok-1234567890');
      await push.resume(); // Attend la révocation déjà mise en file.
      expect(s.c.read(pushControllerProvider), PushStatus.off);
      expect(s.adapter.count('DELETE /api/mobile/v1/devices'), 1);
      expect(s.push.deleted, isTrue);
    });

    test('désactiver : supprime le jeton côté serveur et sur l\'appareil', () async {
      final s = await setup(prefsValues: {'pref.push': true});
      await s.c.read(pushControllerProvider.notifier).disable();
      expect(s.c.read(pushControllerProvider), PushStatus.off);
      expect(s.adapter.count('DELETE /api/mobile/v1/devices'), 1);
      expect(s.push.deleted, isTrue);
      expect(s.c.read(sharedPrefsProvider).getBool('pref.push'), isNull);
    });

    test('jeton renouvelé : le nouveau est enregistré', () async {
      final s = await setup(prefsValues: {'pref.push': true});
      await s.c.read(pushControllerProvider.notifier).resume();
      final before = s.adapter.count('POST /api/mobile/v1/devices');
      s.push.refresh.add('tok-NOUVEAU-123456');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(s.adapter.count('POST /api/mobile/v1/devices'), before + 1);
      final post = s.adapter.requests.lastWhere((request) => request.method == 'POST');
      expect((post.data as Map)['token'], 'tok-NOUVEAU-123456');
    });
  });
}
