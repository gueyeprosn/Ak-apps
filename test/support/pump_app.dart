import 'dart:ui' show Size;

import 'package:ahloulkhidmah_mobile/app/app.dart';
import 'package:ahloulkhidmah_mobile/core/api/api_client.dart';
import 'package:ahloulkhidmah_mobile/core/auth/token_store.dart';
import 'package:ahloulkhidmah_mobile/core/storage/card_cache.dart';
import 'package:ahloulkhidmah_mobile/core/providers.dart';
import 'package:ahloulkhidmah_mobile/features/payment/pay_flow_controller.dart';
import 'package:ahloulkhidmah_mobile/features/payment/payment_security.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_adapter.dart';
import 'harness.dart';

class FakeOpener implements UrlOpener {
  final opened = <Uri>[];
  bool result = true;

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return result;
  }
}

class Pumped {
  Pumped(this.adapter, this.store, this.container, this.opener);
  final FakeAdapter adapter;
  final MemoryTokenStore store;
  final ProviderContainer container;
  final FakeOpener opener;
}

const session = AuthTokens(accessToken: 'a', refreshToken: 'r');

Future<Pumped> pumpApp(
  WidgetTester tester, {
  required Map<String, FakeHandler> routes,
  AuthTokens? tokens,
  Map<String, Object> prefs = const {},
  String version = '1.0.0',
  PayPollConfig poll = const PayPollConfig(interval: Duration.zero, maxAttempts: 3),
  List<Override> extraOverrides = const [],
  CardCache? cardCache,
  double width = 400,
  double textScale = 1,
}) async {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({
    'pref.onboarding.complete': true,
    ...prefs,
  });
  final sp = await SharedPreferences.getInstance();
  final adapter = FakeAdapter(routes);
  final store = MemoryTokenStore(tokens);
  final opener = FakeOpener();
  tester.view.physicalSize = Size(width * 2, 1700);
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
        urlOpenerProvider.overrideWithValue(opener),
        payPollConfigProvider.overrideWithValue(poll),
        // Jamais le vrai stockage de fichiers dans les tests (plugin de plateforme).
        cardCacheProvider.overrideWithValue(cardCache ?? MemoryCardCache()),
        ...extraOverrides,
      ],
      child: const AhloulApp(),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(tester.element(find.byType(AhloulApp)));
  return Pumped(adapter, store, container, opener);
}
