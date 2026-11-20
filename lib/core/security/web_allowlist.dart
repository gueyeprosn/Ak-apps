/// Contrôle des URL ouvertes par l'application (WebView ou navigateur).
///
/// Une URL n'est ouverte que si elle est en **HTTPS**, sans identifiants
/// intégrés, et si son hôte est dans la liste blanche de la configuration.
bool isAllowedWebUrl(String? raw, List<String> allowedHosts) {
  if (raw == null || raw.isEmpty) return false;
  final uri = Uri.tryParse(raw);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return false;
  if (uri.userInfo.isNotEmpty) return false;
  final host = uri.host.toLowerCase();
  return allowedHosts.any((h) => h.toLowerCase() == host);
}
