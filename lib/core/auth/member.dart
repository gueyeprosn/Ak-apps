/// Un versement de cotisation, tel que renvoyé par `GET /api/mobile/v1/me`.
class Versement {
  const Versement({
    required this.periode,
    required this.periodeLabel,
    required this.montant,
    required this.statut,
    required this.canal,
    this.paidAt,
  });

  factory Versement.fromJson(Map<String, dynamic> j) => Versement(
        periode: (j['periode'] ?? '') as String,
        periodeLabel: (j['periodeLabel'] ?? j['periode'] ?? '') as String,
        montant: (j['montant'] as num?)?.toInt() ?? 0,
        statut: (j['statut'] ?? '') as String,
        canal: (j['canal'] ?? '') as String,
        paidAt: j['paidAt'] is String ? DateTime.tryParse(j['paidAt'] as String) : null,
      );

  /// `YYYY-MM`.
  final String periode;
  final String periodeLabel;
  final int montant;

  /// `paye` | `en_attente`.
  final String statut;
  final String canal;
  final DateTime? paidAt;

  bool get isPaid => statut == 'paye';
}

/// Profil du membre connecté. Volontairement minimal : ni CNI, ni date de
/// naissance, ni adresse (le serveur ne les expose pas à l'application).
class Member {
  const Member({
    required this.id,
    required this.name,
    required this.prenoms,
    required this.nom,
    required this.status,
    required this.hasPin,
    required this.versements,
    this.memberNumber,
    this.photoUrl,
    this.email = '',
    this.whatsapp = '',
    this.tel = '',
    this.cotisationPrevue = '',
  });

  factory Member.fromJson(Map<String, dynamic> j) => Member(
        id: (j['id'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        prenoms: (j['prenoms'] ?? '') as String,
        nom: (j['nom'] ?? '') as String,
        status: (j['status'] ?? '') as String,
        hasPin: j['hasPin'] == true,
        memberNumber: (j['memberNumber'] as num?)?.toInt(),
        photoUrl: j['photoUrl'] as String?,
        email: (j['email'] ?? '') as String,
        whatsapp: (j['whatsapp'] ?? '') as String,
        tel: (j['tel'] ?? '') as String,
        cotisationPrevue: (j['cotisationPrevue'] ?? '') as String,
        versements: [
          for (final v in (j['versements'] as List? ?? const []))
            if (v is Map<String, dynamic>) Versement.fromJson(v),
        ],
      );

  final String id;
  final String name;
  final String prenoms;
  final String nom;
  final String status;
  final bool hasPin;
  final int? memberNumber;
  final String? photoUrl;
  final String email;
  final String whatsapp;
  final String tel;
  final String cotisationPrevue;
  final List<Versement> versements;

  bool get isActive => status == 'actif';

  String get initials {
    String first(String s) {
      final t = s.trim();
      return t.isEmpty ? '' : String.fromCharCode(t.runes.first);
    }
    final p = first(prenoms);
    final n = first(nom);
    final both = '$p$n';
    return both.isEmpty ? first(name) : both.toUpperCase();
  }

  /// Versement de la période donnée (`YYYY-MM`), s'il existe.
  Versement? versementFor(String periode) {
    for (final v in versements) {
      if (v.periode == periode) return v;
    }
    return null;
  }
}
