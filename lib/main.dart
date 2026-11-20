import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/api/api_client.dart';
import 'core/providers.dart';
import 'features/notifications/data/firebase_push_platform.dart';
import 'features/notifications/presentation/push_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final prefs = await SharedPreferences.getInstance();
  final info = await PackageInfo.fromPlatform();

  final platform = switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    _ => 'other',
  };

  final push = await FirebasePushPlatform.create();
  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        pushPlatformProvider.overrideWithValue(push),
        clientInfoProvider.overrideWithValue(
          ClientInfo(platform: platform, appVersion: info.version),
        ),
      ],
      child: const AhloulApp(),
    ),
  );
}
