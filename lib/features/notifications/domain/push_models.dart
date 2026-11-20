/// Notification reçue, réduite à ce dont l'application a besoin.
class PushMessage {
  const PushMessage({this.title, this.body, this.route});
  final String? title;
  final String? body;

  /// Chemin interne déjà validé par [safePushRoute], sinon `null`.
  final String? route;
}

/// Une notification est une entrée **non fiable** : seul un chemin interne
/// connu est suivi. Jamais d'URL, de schéma ou de chemin arbitraire.
///
/// Acceptés : `/card`, `/pay` et `/t/<onglet>` (ex. `/t/home`).
String? safePushRoute(Object? raw) {
  if (raw is! String) return null;
  final r = raw.trim();
  if (r == '/card' || r == '/pay') return r;
  if (RegExp(r'^/t/[a-z0-9_-]{1,32}$').hasMatch(r)) return r;
  return null;
}
