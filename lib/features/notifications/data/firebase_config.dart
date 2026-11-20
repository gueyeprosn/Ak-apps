import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart';

/// Configuration Firebase injectée à la compilation — **jamais de secret** :
/// ces valeurs (clé d'API de l'app, identifiants) sont publiques par
/// conception. Tant qu'elles sont vides, les notifications sont désactivées
/// et l'application fonctionne normalement.
///
/// ```
/// flutter run --dart-define-from-file=firebase.json
/// ```
/// (modèle : `firebase.example.json`)
class FirebaseConfig {
  const FirebaseConfig._();

  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const appIdAndroid = String.fromEnvironment('FIREBASE_APP_ID_ANDROID');
  static const appIdIos = String.fromEnvironment('FIREBASE_APP_ID_IOS');
  static const iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'org.ahloulkhidmah.ahloulkhidmahMobile',
  );

  static String _appId(TargetPlatform p) => switch (p) {
        TargetPlatform.android => appIdAndroid,
        TargetPlatform.iOS => appIdIos,
        _ => '',
      };

  /// Vrai seulement si toutes les valeurs de la plateforme courante sont fournies.
  static bool isConfiguredFor(TargetPlatform p) =>
      apiKey.isNotEmpty && projectId.isNotEmpty && senderId.isNotEmpty && _appId(p).isNotEmpty;

  /// Options explicites : pas besoin de `google-services.json` ni de
  /// `GoogleService-Info.plist` (ni de plugin Gradle).
  static FirebaseOptions optionsFor(TargetPlatform p) => FirebaseOptions(
        apiKey: apiKey,
        appId: _appId(p),
        messagingSenderId: senderId,
        projectId: projectId,
        iosBundleId: p == TargetPlatform.iOS ? iosBundleId : null,
      );
}
