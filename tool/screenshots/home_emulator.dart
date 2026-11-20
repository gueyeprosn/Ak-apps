// Run with: flutter run --no-pub -d emulator-5554 -t tool/screenshots/home_emulator.dart
// AK_PREVIEW_VISITOR=true ouvre la session visiteur, et AK_PREVIEW_ONBOARDING=true
// lance la découverte. Pour afficher la carte de test, déposer card-demo.webp
// dans le cache de l'application avec adb run-as sous le nom ak-card-preview.webp.
import 'dart:io';

import 'package:ahloulkhidmah_mobile/app/app.dart';
import 'package:ahloulkhidmah_mobile/core/api/api_client.dart';
import 'package:ahloulkhidmah_mobile/core/auth/token_store.dart';
import 'package:ahloulkhidmah_mobile/core/format.dart';
import 'package:ahloulkhidmah_mobile/core/providers.dart';
import 'package:ahloulkhidmah_mobile/core/storage/card_cache.dart';
import 'package:ahloulkhidmah_mobile/shared/widgets/official_page_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test/support/fake_adapter.dart';
import '../../test/support/harness.dart';

Future<void> main() async {
  if (!kDebugMode) throw StateError('Debug preview only');
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  const visitor = bool.fromEnvironment('AK_PREVIEW_VISITOR');
  const lang = String.fromEnvironment('AK_PREVIEW_LANG', defaultValue: 'fr');
  const onboarding = bool.fromEnvironment('AK_PREVIEW_ONBOARDING');
  // In-memory preferences keep this preview separate from the installed app.
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({
    'pref.onboarding.complete': !onboarding,
    'pref.lang': lang,
    'pref.theme': 'light',
  });
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now();
  final period = currentPeriode(now);
  final previousPeriod = currentPeriode(DateTime(now.year, now.month - 1));
  final member = memberJson(versements: [
    {'periode': period, 'montant': 1400, 'statut': 'paye', 'canal': 'wave'},
    {
      'periode': previousPeriod,
      'montant': 1400,
      'statut': 'en_attente',
      'canal': 'wave',
    },
  ]);
  final previewSession = {
    'member': member,
    'accessToken': 'a',
    'refreshToken': 'r',
  };
  const products = [
    {
      'slug': 't-shirt-demo',
      'name': 'T-shirt · Démo',
      'price': 8000,
      'category': 'textile'
    },
    {
      'slug': 'casquette-demo',
      'name': 'Casquette · Démo',
      'price': 5000,
      'category': 'accessoires'
    },
    {
      'slug': 'mug-demo',
      'name': 'Mug · Démo',
      'price': 3500,
      'category': 'accessoires'
    },
    {
      'slug': 'sac-demo',
      'name': 'Sac · Démo',
      'price': 4000,
      'category': 'textile'
    },
  ];
  final adapter = FakeAdapter({
    'GET /api/mobile/v1/me': (_) => FakeReply(200, {'member': member}),
    'GET /api/mobile/v1/me/card': (request) async {
      if (request.queryParameters['size'] == 'full') {
        return const FakeReply(404);
      }
      final cache = await getTemporaryDirectory();
      final file = File('${cache.path}/ak-card-preview.webp');
      return await file.exists()
          ? FakeReply(200, await file.readAsBytes())
          : const FakeReply(404);
    },
    'POST /api/mobile/v1/auth/login': (request) {
      final data = request.data;
      final code = data is Map ? data['suffix'] : null;
      return switch (code) {
        'AB12' => const FakeReply(200, {
            'status': 'pin_setup_required',
            'setupToken': 'preview-setup-token',
          }),
        '1234' => FakeReply(200, previewSession),
        _ => const FakeReply(401, {
            'error': {'code': 'invalid_credentials'}
          }),
      };
    },
    'POST /api/mobile/v1/auth/pin-setup': (_) => FakeReply(200, previewSession),
    'POST /api/mobile/v1/auth/logout': (_) => const FakeReply(200),
    'GET /api/store/categories': (_) => const FakeReply(200, {
          'categories': [
            {'slug': 'textile', 'name': 'Textile'},
            {'slug': 'accessoires', 'name': 'Accessoires'},
          ],
        }),
    'GET /api/store/products': (request) {
      final category = request.queryParameters['categorie'];
      final query = request.queryParameters['q']?.toString().toLowerCase();
      return FakeReply(200, {
        'products': [
          for (final product in products)
            if ((category == null || product['category'] == category) &&
                (query == null ||
                    product['name'].toString().toLowerCase().contains(query)))
              product,
        ],
      });
    },
    for (final product in products)
      'GET /api/store/products/${product['slug']}': (_) =>
          FakeReply(200, {'product': product}),
  });
  runApp(
    ProviderScope(
      overrides: [
        appEnvProvider.overrideWithValue(testEnv),
        sharedPrefsProvider.overrideWithValue(prefs),
        clientInfoProvider.overrideWithValue(
          const ClientInfo(platform: 'android', appVersion: '1.0.0'),
        ),
        httpAdapterProvider.overrideWithValue(adapter),
        tokenStoreProvider.overrideWithValue(
          MemoryTokenStore(
            visitor || onboarding
                ? null
                : const AuthTokens(accessToken: 'a', refreshToken: 'r'),
          ),
        ),
        cardCacheProvider.overrideWithValue(MemoryCardCache()),
        officialPageLauncherProvider.overrideWithValue((_) async => true),
      ],
      child: const AhloulApp(),
    ),
  );
}
