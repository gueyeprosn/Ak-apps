import 'package:url_launcher/url_launcher.dart';

/// Hôtes vers lesquels l'application accepte d'envoyer le membre pour payer.
/// Ce sont ceux que le site déclare déjà (`form-action` de sa CSP). Une URL
/// reçue du serveur hors de cette liste est refusée : une configuration ou une
/// réponse compromise ne doit pas pouvoir rediriger un paiement.
const paymentHosts = <String>{
  'app.paydunya.com',
  'paydunya.com',
  'pay.wave.com',
  'orangemoneysn.page.link',
  'sugu.orange-sonatel.com',
};

bool isAllowedPaymentUrl(String? raw) {
  if (raw == null || raw.isEmpty) return false;
  final uri = Uri.tryParse(raw);
  if (uri == null || uri.scheme != 'https' || uri.userInfo.isNotEmpty) return false;
  return paymentHosts.contains(uri.host.toLowerCase());
}

/// Ouvre une URL hors de l'application (navigateur ou application du
/// prestataire). Abstrait pour pouvoir être remplacé dans les tests.
abstract class UrlOpener {
  Future<bool> open(Uri uri);
}

class LaunchUrlOpener implements UrlOpener {
  const LaunchUrlOpener();

  @override
  Future<bool> open(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
}
