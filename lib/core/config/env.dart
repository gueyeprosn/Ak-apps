/// Environnement d'exécution, fixé à la compilation :
///
/// ```
/// flutter run --dart-define=ENV=staging --dart-define=API_BASE_URL=https://staging.ahloulkhidmah.org
/// ```
///
/// Aucun secret n'est jamais passé ici : l'application n'en contient pas.
class AppEnv {
  const AppEnv({
    required this.name,
    required this.apiBaseUrl,
    this.allowInsecureHttp = false,
  });

  final String name;
  final String apiBaseUrl;

  /// Réservé aux tests et au développement local (jamais en production).
  final bool allowInsecureHttp;

  static const AppEnv fromDefines = AppEnv(
    name: String.fromEnvironment('ENV', defaultValue: 'prod'),
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://www.ahloulkhidmah.org',
    ),
  );

  bool get isProd => name == 'prod';

  /// HTTPS obligatoire, sauf développement explicite hors production.
  void assertSecure() {
    final uri = Uri.parse(apiBaseUrl);
    final secure = uri.scheme == 'https';
    if (!secure && (isProd || !allowInsecureHttp)) {
      throw StateError(
        'API_BASE_URL doit utiliser HTTPS (reçu : ${uri.scheme}://${uri.host}).',
      );
    }
  }
}
