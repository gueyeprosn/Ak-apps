import 'package:ahloulkhidmah_mobile/app/router/app_router.dart';
import 'package:ahloulkhidmah_mobile/core/auth/token_store.dart';
import 'package:ahloulkhidmah_mobile/features/notifications/presentation/push_controller.dart';
import 'package:flutter/widgets.dart' show Key, Scrollable;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_adapter.dart';
import '../../support/pump_app.dart';
import 'push_test.dart' show FakePush;

const _tokens = AuthTokens(accessToken: 'a', refreshToken: 'r');

Map<String, FakeHandler> _routes() => {
      'GET /api/mobile/v1/config': (o) => FakeReply(200, configJson(), {'etag': '"c"'}),
      'GET /api/store/products': (o) => const FakeReply(200, {'products': []}),
      'GET /api/mobile/v1/me': (o) => FakeReply(200, {'member': memberJson()}),
      'POST /api/mobile/v1/auth/logout': (o) => const FakeReply(200, {'ok': true}),
      'POST /api/mobile/v1/devices': (o) => const FakeReply(200, {'ok': true}),
      'DELETE /api/mobile/v1/devices': (o) => const FakeReply(200, {'ok': true}),
    };

Future<void> _openAccount(WidgetTester tester, Pumped ctx) async {
  ctx.container.read(routerProvider).go('/t/account');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Firebase non configuré : aucun réglage de notifications dans Mon compte', (tester) async {
    final ctx = await pumpApp(tester, routes: _routes(), tokens: _tokens);
    await _openAccount(tester, ctx);
    expect(find.text('Mon compte'), findsWidgets);
    expect(find.byKey(const Key('push-toggle')), findsNothing);
  });

  testWidgets('Firebase configuré : le membre active puis désactive les notifications', (tester) async {
    final push = FakePush();
    final ctx = await pumpApp(
      tester,
      routes: _routes(),
      tokens: _tokens,
      extraOverrides: [pushPlatformProvider.overrideWithValue(push)],
    );
    await _openAccount(tester, ctx);
    expect(find.byKey(const Key('push-toggle')), findsOneWidget);
    expect(ctx.container.read(pushControllerProvider), PushStatus.off);

    await tester.ensureVisible(find.byKey(const Key('push-toggle')));
    await tester.tap(find.byKey(const Key('push-toggle')));
    await tester.pumpAndSettle();
    expect(ctx.container.read(pushControllerProvider), PushStatus.on);
    expect(ctx.adapter.count('POST /api/mobile/v1/devices'), greaterThanOrEqualTo(1));

    await tester.ensureVisible(find.byKey(const Key('push-toggle')));
    await tester.tap(find.byKey(const Key('push-toggle')));
    await tester.pumpAndSettle();
    // La désactivation attend le réseau (faux) : laisser les futures se terminer.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(ctx.container.read(pushControllerProvider), PushStatus.off);
    expect(ctx.adapter.count('DELETE /api/mobile/v1/devices'), 1);
  });

  testWidgets('autorisation refusée en arabe sombre à 320 dp avec texte à 200 %', (tester) async {
    final ctx = await pumpApp(
      tester,
      routes: _routes(),
      tokens: _tokens,
      prefs: {'pref.lang': 'ar', 'pref.theme': 'dark'},
      width: 320,
      textScale: 2,
      extraOverrides: [pushPlatformProvider.overrideWithValue(FakePush(granted: false))],
    );
    await _openAccount(tester, ctx);
    final toggle = find.byKey(const Key('push-toggle'));
    await tester.scrollUntilVisible(toggle, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('push-toggle')));
    await tester.pumpAndSettle();
    expect(find.textContaining('الإشعارات مرفوضة'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(ctx.adapter.count('POST /api/mobile/v1/devices'), 0);
  });
}
