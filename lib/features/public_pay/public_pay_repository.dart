import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../payment/payment_repository.dart';

/// Montants proposés par le site pour l'adhésion (`MONTANTS`), plus « autre ».
const adhesionAmounts = ['1400', '14000', '140000'];
const adhesionOtherMin = 100;

/// Montants proposés par le site pour un don (`CONTRIBUTION_AMOUNTS`).
const donationAmounts = ['5000', '10000', '25000', '50000'];
const donationOtherMin = 500;

/// Destinations d'un don (`CONTRIBUTION_CAMPAGNES`), valeurs du serveur.
const donationCampaigns = ['general', 'touba', 'magal', 'education', 'autre'];

/// Une demande de paiement public (adhésion ou don). Deux demandes égales
/// représentent le même paiement : le paiement déjà créé est alors réutilisé.
abstract class PublicPayRequest {
  const PublicPayRequest();

  /// Montant annoncé à l'écran (le serveur recalcule et fait foi).
  int? get previewAmount;
}

/// Adhésion « allégée » du site (`adhesionLightSchema`). Le membre n'est créé
/// par le serveur **qu'après** la confirmation du paiement.
class AdhesionDraft extends PublicPayRequest {
  const AdhesionDraft({
    required this.nom,
    required this.prenoms,
    required this.tel,
    required this.paysRegion,
    required this.montant,
    this.montantAutre = '',
  });

  final String nom;
  final String prenoms;

  /// Format international `+221771234567`.
  final String tel;
  final String paysRegion;

  /// `1400`, `14000`, `140000` ou `autre`.
  final String montant;
  final String montantAutre;

  @override
  int? get previewAmount =>
      montant == 'autre' ? int.tryParse(montantAutre) : int.tryParse(montant);

  Map<String, Object?> toJson() => {
    'nom': nom.trim(),
    'prenoms': prenoms.trim(),
    'tel': tel,
    'paysRegion': paysRegion.trim(),
    'montant': montant,
    if (montant == 'autre') 'montantAutre': montantAutre,
  };

  @override
  bool operator ==(Object other) =>
      other is AdhesionDraft &&
      other.nom == nom &&
      other.prenoms == prenoms &&
      other.tel == tel &&
      other.paysRegion == paysRegion &&
      other.montant == montant &&
      other.montantAutre == montantAutre;

  @override
  int get hashCode =>
      Object.hash(nom, prenoms, tel, paysRegion, montant, montantAutre);
}

/// Don (`contributionSchema`).
class DonationDraft extends PublicPayRequest {
  const DonationDraft({
    required this.anonymous,
    required this.montant,
    required this.campagne,
    this.montantAutre = '',
    this.prenoms = '',
    this.nom = '',
    this.tel = '',
    this.email = '',
    this.message = '',
  });

  final bool anonymous;
  final String montant;
  final String montantAutre;
  final String campagne;
  final String prenoms;
  final String nom;
  final String tel;
  final String email;
  final String message;

  @override
  int? get previewAmount =>
      montant == 'autre' ? int.tryParse(montantAutre) : int.tryParse(montant);

  /// Un don anonyme n'envoie **aucune** donnée d'identité.
  Map<String, Object?> toJson() => {
    'anonymous': anonymous,
    'montant': montant,
    if (montant == 'autre') 'montantAutre': montantAutre,
    'campagne': campagne,
    if (!anonymous) ...{
      'prenoms': prenoms.trim(),
      if (nom.trim().isNotEmpty) 'nom': nom.trim(),
      'tel': tel,
      if (email.trim().isNotEmpty) 'email': email.trim(),
    },
    if (message.trim().isNotEmpty) 'message': message.trim(),
  };

  @override
  bool operator ==(Object other) =>
      other is DonationDraft &&
      other.anonymous == anonymous &&
      other.montant == montant &&
      other.montantAutre == montantAutre &&
      other.campagne == campagne &&
      other.prenoms == prenoms &&
      other.nom == nom &&
      other.tel == tel &&
      other.email == email &&
      other.message == message;

  @override
  int get hashCode => Object.hash(
    anonymous,
    montant,
    montantAutre,
    campagne,
    prenoms,
    nom,
    tel,
    email,
    message,
  );
}

/// Résultat de la création côté serveur. Rien n'est encore payé.
sealed class CreatedPayment {
  const CreatedPayment();
}

/// Paiement « pending » créé, avec sa page de paiement hébergée.
class HostedPayment extends CreatedPayment {
  const HostedPayment({
    required this.paymentId,
    required this.checkoutUrl,
    this.amount,
  });
  final String paymentId;
  final String? checkoutUrl;
  final int? amount;
}

/// Secours Wave du site (activé seulement quand PayDunya est en panne et que
/// l'interrupteur serveur est ouvert) : aucun paiement en ligne n'existe, le
/// membre est invité à payer à la main. **Ce n'est jamais un paiement confirmé.**
class WaveManualPayment extends CreatedPayment {
  const WaveManualPayment({
    required this.number,
    required this.amount,
    required this.reference,
  });
  final String number;
  final int amount;
  final String reference;
}

/// Accès aux endpoints **publics** du site (sans session) : adhésion, don,
/// SoftPay et statut. Aucune de ces méthodes ne « confirme » quoi que ce soit.
class PublicPayRepository {
  PublicPayRepository(this._clients);
  final ApiClients _clients;

  Future<CreatedPayment> createAdhesion(AdhesionDraft d) => guardApi(() async {
    final res = await _clients.plain.post<Map<String, dynamic>>(
      '/api/adhesions',
      data: d.toJson(),
    );
    final j = res.data ?? const {};
    if (j['fallback'] == 'wave' && j['wave'] is Map) {
      final w = j['wave'] as Map;
      return WaveManualPayment(
        number: (w['number'] ?? '').toString(),
        amount: (w['amount'] as num?)?.toInt() ?? 0,
        reference: (w['reference'] ?? '').toString(),
      );
    }
    return _hosted(j, urlKey: 'paymentUrl');
  });

  Future<CreatedPayment> createDonation(DonationDraft d) => guardApi(() async {
    final res = await _clients.plain.post<Map<String, dynamic>>(
      '/api/contributions',
      data: d.toJson(),
    );
    return _hosted(res.data ?? const {}, urlKey: 'url');
  });

  HostedPayment _hosted(Map<String, dynamic> j, {required String urlKey}) {
    final id = (j['paymentId'] ?? '').toString();
    if (id.isEmpty) {
      throw const ApiException(
        code: 'bad_response',
        message: 'Paiement non créé',
      );
    }
    return HostedPayment(
      paymentId: id,
      checkoutUrl: j[urlKey] as String?,
      amount: (j['amount'] as num?)?.toInt(),
    );
  }

  Future<LaunchTarget> startSoftpay(
    String paymentId,
    PayMethod method, {
    String? phone,
  }) => guardApi(() async {
    final res = await _clients.plain.post<Map<String, dynamic>>(
      '/api/payments/softpay',
      data: {
        'paymentId': paymentId,
        'method': method == PayMethod.wave ? 'wave' : 'orange',
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
    final d = res.data ?? const {};
    if (d['alreadyPaid'] == true) return const LaunchTarget(alreadyPaid: true);
    // `fallback` : SoftPay indisponible, le serveur renvoie la page classique.
    if (d['fallback'] == true) {
      return LaunchTarget(url: d['url'] as String?, hosted: true);
    }
    final url = method == PayMethod.orange
        ? (d['omUrl'] ?? d['maxitUrl'] ?? d['url']) as String?
        : (d['url'] ?? d['omUrl']) as String?;
    return LaunchTarget(url: url);
  });

  /// `GET /api/payments/{id}/status` : seul le statut du serveur fait foi.
  Future<PaymentSnapshot> status(String paymentId) => guardApi(() async {
    final res = await _clients.plain.get<Map<String, dynamic>>(
      '/api/payments/$paymentId/status',
    );
    return PaymentSnapshot.fromJson(res.data ?? const {});
  });
}
