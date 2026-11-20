import 'dart:async';
import 'dart:typed_data';

import 'package:ahloulkhidmah_mobile/app/router/app_router.dart';
import 'package:ahloulkhidmah_mobile/core/providers.dart';
import 'package:ahloulkhidmah_mobile/core/storage/card_cache.dart';
import 'package:ahloulkhidmah_mobile/features/card/card_controller.dart';
import 'package:flutter/widgets.dart' show Key;
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_adapter.dart';
import '../support/pump_app.dart';
import '../support/tiny_image.dart';

class FakeSharer implements CardSharer {
  final shared = <Uint8List>[];
  bool fail = false;

  @override
  Future<void> share(Uint8List png) async {
    if (fail) throw StateError('partage impossible');
    shared.add(png);
  }
}

/// Faux serveur : sert la carte, mémorise les requêtes.
class CardServer {
  String etag = '"card-v1"';
  int status = 200;
  bool down = false;
  Completer<void>? gate;
  final queries = <String?>[];
  final ifNoneMatch = <String?>[];

  Map<String, FakeHandler> routes() => {
        'GET /api/mobile/v1/config': (o) => FakeReply(200, configJson(), {'etag': '"c"'}),
        'GET /api/store/products': (o) => const FakeReply(200, {'products': []}),
        'GET /api/mobile/v1/me': (o) => FakeReply(200, {'member': memberJson()}),
        'POST /api/mobile/v1/auth/logout': (o) => const FakeReply(200, {'ok': true}),
        'GET /api/mobile/v1/me/card': (o) async {
          queries.add(o.queryParameters['size'] as String?);
          final inm = o.headers['If-None-Match'] as String?;
          ifNoneMatch.add(inm);
          if (down) throw networkDownError(o);
          if (gate != null) await gate!.future;
          if (status == 409) {
            return const FakeReply(409, {'error': {'code': 'card_unavailable', 'message': 'x'}});
          }
          if (inm != null && inm == etag && o.queryParameters['size'] == 'display') {
            return FakeReply(304, const {}, {'etag': etag});
          }
          return FakeReply(200, tinyPng, {'etag': etag});
        },
      };
}

Future<({Pumped p, CardServer s, MemoryCardCache cache, FakeSharer sharer})> open(
  WidgetTester tester, {
  CardServer? server,
  MemoryCardCache? cache,
  bool loggedIn = true,
  bool openScreen = true,
}) async {
  final s = server ?? CardServer();
  final c = cache ?? MemoryCardCache();
  final sh = FakeSharer();
  final p = await pumpApp(
    tester,
    routes: s.routes(),
    tokens: loggedIn ? session : null,
    cardCache: c,
    extraOverrides: [cardSharerProvider.overrideWithValue(sh)],
  );
  if (openScreen) {
    await tester.tap(find.text('Ma carte membre'));
    await tester.pumpAndSettle();
  }
  return (p: p, s: s, cache: c, sharer: sh);
}

void main() {
  testWidgets('première ouverture : la carte du serveur est affichée et mise en cache', (tester) async {
    final t = await open(tester);
    expect(find.byKey(const Key('card-image')), findsOneWidget);
    expect(find.text('Membre actif'), findsOneWidget);
    expect(t.s.queries, ['display'], reason: 'version légère par défaut (≈ 80 Ko)');
    expect(t.s.ifNoneMatch.single, isNull);
    expect(t.cache.image!.etag, '"card-v1"');
    expect(t.cache.memberId, 'AK-TEST-1');
  });

  testWidgets('ouverture suivante : copie locale + revalidation par ETag, 304 = rien retéléchargé', (tester) async {
    final cache = MemoryCardCache()
      ..memberId = 'AK-TEST-1'
      ..image = CardImage(bytes: tinyPng, savedAt: DateTime(2026, 11, 1), etag: '"card-v1"');
    final t = await open(tester, cache: cache);
    expect(find.byKey(const Key('card-image')), findsOneWidget);
    expect(t.s.ifNoneMatch.single, '"card-v1"');
    expect(find.textContaining('Hors ligne'), findsNothing);
    expect(t.cache.image!.savedAt, DateTime(2026, 11, 1), reason: 'un 304 ne réécrit rien');
  });

  testWidgets('la copie locale s\'affiche AVANT la réponse du serveur', (tester) async {
    final cache = MemoryCardCache()
      ..memberId = 'AK-TEST-1'
      ..image = CardImage(bytes: tinyPng, savedAt: DateTime(2026, 11, 1), etag: '"card-v1"');
    final server = CardServer()..gate = Completer<void>();
    final t = await open(tester, cache: cache, server: server, openScreen: false);
    await tester.tap(find.text('Ma carte membre'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const Key('card-image')), findsOneWidget, reason: 'affichée sans attendre le réseau');
    server.gate!.complete();
    await tester.pumpAndSettle();
    expect(t.s.ifNoneMatch.single, '"card-v1"');
  });

  testWidgets('carte modifiée côté serveur : nouvelle image, nouvel ETag enregistré', (tester) async {
    final cache = MemoryCardCache()
      ..memberId = 'AK-TEST-1'
      ..image = CardImage(bytes: tinyPng, savedAt: DateTime(2026, 11, 1), etag: '"card-old"');
    final t = await open(tester, cache: cache);
    expect(t.cache.image!.etag, '"card-v1"');
    expect(t.cache.image!.savedAt.isAfter(DateTime(2026, 11, 2)), isTrue);
  });

  testWidgets('hors ligne AVEC copie locale : carte affichée + bandeau « version enregistrée »', (tester) async {
    final cache = MemoryCardCache()
      ..memberId = 'AK-TEST-1'
      ..image = CardImage(bytes: tinyPng, savedAt: DateTime(2026, 11, 1), etag: '"card-v1"');
    final server = CardServer()..down = true;
    await open(tester, cache: cache, server: server);
    expect(find.byKey(const Key('card-image')), findsOneWidget);
    expect(find.textContaining('Hors ligne : version enregistrée le'), findsOneWidget);
  });

  testWidgets('hors ligne SANS copie : message clair, puis reprise au retour du réseau', (tester) async {
    final server = CardServer()..down = true;
    await open(tester, server: server);
    expect(find.byKey(const Key('card-image')), findsNothing);
    expect(find.text('Impossible de charger la carte. Vérifiez votre réseau et réessayez.'), findsOneWidget);
    server.down = false;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('card-image')), findsOneWidget);
  });

  testWidgets('carte indisponible (409) : message, et la copie locale est effacée', (tester) async {
    final cache = MemoryCardCache()
      ..memberId = 'AK-TEST-1'
      ..image = CardImage(bytes: tinyPng, savedAt: DateTime(2026, 11, 1), etag: '"card-v1"');
    final server = CardServer()..status = 409;
    final t = await open(tester, cache: cache, server: server);
    expect(find.text('Carte indisponible'), findsOneWidget);
    expect(find.byKey(const Key('card-image')), findsNothing);
    expect(t.cache.image, isNull, reason: 'pas de copie locale d\'une carte qu\'on ne doit plus montrer');
  });

  testWidgets('la copie d\'un AUTRE membre n\'est jamais affichée', (tester) async {
    final cache = MemoryCardCache()
      ..memberId = 'AK-AUTRE'
      ..image = CardImage(bytes: Uint8List.fromList([1, 2, 3]), savedAt: DateTime(2026, 11, 1), etag: '"card-autre"');
    final t = await open(tester, cache: cache);
    expect(t.s.ifNoneMatch.single, isNull, reason: 'aucune revalidation avec l\'ETag d\'un autre compte');
    expect(t.cache.memberId, 'AK-TEST-1');
  });

  testWidgets('partage : la carte est retéléchargée en PLEINE résolution puis envoyée au partage système', (tester) async {
    final t = await open(tester);
    await tester.tap(find.byKey(const Key('share-card')));
    await tester.pumpAndSettle();
    expect(t.s.queries, ['display', 'full']);
    expect(t.sharer.shared.single, tinyPng);
    expect(find.byKey(const Key('share-failed')), findsNothing);
  });

  testWidgets('échec du partage : message, aucun plantage', (tester) async {
    final t = await open(tester);
    t.sharer.fail = true;
    await tester.tap(find.byKey(const Key('share-card')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('share-failed')), findsOneWidget);
    expect(find.byKey(const Key('card-image')), findsOneWidget);
  });

  testWidgets('déconnexion : la copie locale de la carte est effacée', (tester) async {
    final t = await open(tester, openScreen: false);
    await tester.tap(find.text('Ma carte membre'));
    await tester.pumpAndSettle();
    expect(t.cache.image, isNotNull);
    unawaited(t.p.container.read(authControllerProvider.notifier).logout());
    await tester.pumpAndSettle();
    expect(t.cache.image, isNull);
  });

  testWidgets('session révoquée côté serveur : la copie locale est effacée aussi', (tester) async {
    final t = await open(tester);
    expect(t.cache.image, isNotNull);
    t.p.container.read(sessionEventsProvider).notifyExpired();
    await tester.pumpAndSettle();
    expect(t.cache.image, isNull);
  });

  testWidgets('visiteur : /card renvoie vers la connexion', (tester) async {
    final t = await open(tester, loggedIn: false, openScreen: false);
    t.p.container.read(routerProvider).go('/card');
    await tester.pumpAndSettle();
    expect(find.text('Espace membre'), findsOneWidget);
    expect(t.s.queries, isEmpty);
  });

  testWidgets('arabe : titre, aide et sens de lecture', (tester) async {
    final s = CardServer();
    await pumpApp(tester, routes: s.routes(), tokens: session, prefs: {'pref.lang': 'ar'}, extraOverrides: [
      cardSharerProvider.overrideWithValue(FakeSharer()),
    ]);
    await tester.tap(find.text('بطاقة العضوية'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('card-image')), findsOneWidget);
    expect(find.text('اعرضوا رمز QR للتحقق من بطاقتكم.'), findsOneWidget);
  });
}
