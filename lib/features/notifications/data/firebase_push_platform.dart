import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_config.dart';
import '../domain/push_models.dart';
import '../domain/push_platform.dart';

/// Messages reçus application fermée / en arrière-plan.
/// Fonction de premier niveau + `vm:entry-point` : exécutée dans un isolate
/// séparé, donc Firebase doit y être ré-initialisé. Un message portant un bloc
/// `notification` est de toute façon affiché par le système.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isNotEmpty) return;
  await Firebase.initializeApp(
    options: FirebaseConfig.optionsFor(defaultTargetPlatform),
  );
}

String? _messageText(Object? value) => value is String && value.isNotEmpty ? value : null;

PushMessage _toMessage(RemoteMessage m) => PushMessage(
      title: m.notification?.title ?? _messageText(m.data['title']),
      body: m.notification?.body ?? _messageText(m.data['body']),
      route: safePushRoute(m.data['route']),
    );

class FirebasePushPlatform implements PushPlatform {
  FirebasePushPlatform._();

  /// Initialise Firebase si la configuration est complète (Android / iOS).
  /// Ne lève jamais : en cas d'échec, les notifications restent désactivées.
  static Future<PushPlatform> create() async {
    final p = defaultTargetPlatform;
    final supported = !kIsWeb && (p == TargetPlatform.android || p == TargetPlatform.iOS);
    if (!supported || !FirebaseConfig.isConfiguredFor(p)) {
      return const NoopPushPlatform();
    }
    try {
      await Firebase.initializeApp(options: FirebaseConfig.optionsFor(p));
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      return FirebasePushPlatform._();
    } catch (_) {
      debugPrint('[push] Firebase indisponible');
      return const NoopPushPlatform();
    }
  }

  final _fm = FirebaseMessaging.instance;

  @override
  bool get isAvailable => true;

  bool _granted(NotificationSettings settings) =>
      settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;

  @override
  Future<bool> hasPermission() async => _granted(await _fm.getNotificationSettings());

  @override
  Future<bool> requestPermission() async =>
      _granted(await _fm.requestPermission(alert: true, badge: true, sound: true));

  @override
  Future<void> setAutoInitEnabled(bool enabled) => _fm.setAutoInitEnabled(enabled);

  @override
  Future<String?> getToken() async {
    try {
      // iOS : le jeton APNs doit exister avant le jeton FCM (absent sur simulateur).
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        var apns = await _fm.getAPNSToken();
        for (var i = 0; apns == null && i < 10; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          apns = await _fm.getAPNSToken();
        }
        if (apns == null) return null;
      }
      return await _fm.getToken();
    } catch (_) {
      debugPrint('[push] jeton indisponible');
      return null;
    }
  }

  @override
  Stream<String> get onTokenRefresh => _fm.onTokenRefresh;

  @override
  Stream<PushMessage> get onForeground => FirebaseMessaging.onMessage.map(_toMessage);

  @override
  Stream<PushMessage> get onOpened => FirebaseMessaging.onMessageOpenedApp.map(_toMessage);

  @override
  Future<PushMessage?> initialMessage() async {
    final m = await _fm.getInitialMessage();
    return m == null ? null : _toMessage(m);
  }

  @override
  Future<void> deleteToken() => _fm.deleteToken();
}
