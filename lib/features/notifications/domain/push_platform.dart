import 'push_models.dart';

/// Frontière avec Firebase : l'application ne parle qu'à cette interface, ce
/// qui garde les tests sans réseau ni plugin natif.
abstract class PushPlatform {
  /// Faux si Firebase n'est pas configuré / pas disponible sur cette plateforme.
  bool get isAvailable;

  /// Demande l'autorisation (boîte de dialogue système). Vrai si accordée.
  Future<bool> requestPermission();
  Future<bool> hasPermission();
  Future<void> setAutoInitEnabled(bool enabled);

  /// Jeton FCM, ou `null` (simulateur iOS, pas d'APNs, erreur…).
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;

  /// Messages reçus application **ouverte**.
  Stream<PushMessage> get onForeground;

  /// Tap sur une notification, application en arrière-plan.
  Stream<PushMessage> get onOpened;

  /// Tap sur une notification qui a **lancé** l'application (consommé une fois).
  Future<PushMessage?> initialMessage();

  Future<void> deleteToken();
}

/// Utilisé tant que Firebase n'est pas configuré : tout est inerte.
class NoopPushPlatform implements PushPlatform {
  const NoopPushPlatform();
  @override
  bool get isAvailable => false;
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<bool> hasPermission() async => false;
  @override
  Future<void> setAutoInitEnabled(bool enabled) async {}
  @override
  Future<String?> getToken() async => null;
  @override
  Stream<String> get onTokenRefresh => const Stream.empty();
  @override
  Stream<PushMessage> get onForeground => const Stream.empty();
  @override
  Stream<PushMessage> get onOpened => const Stream.empty();
  @override
  Future<PushMessage?> initialMessage() async => null;
  @override
  Future<void> deleteToken() async {}
}
