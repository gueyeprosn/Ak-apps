/// Numéros de téléphone internationaux (adhésion et dons).
///
/// Reprend les règles de `src/lib/phone-validate.ts` du site : longueur
/// nationale attendue par pays, et, pour le Sénégal, 9 chiffres commençant par
/// 70, 75, 76, 77 ou 78. Le serveur revalide toujours : cette validation ne
/// sert qu'à éviter un aller-retour réseau (et un paiement lancé pour rien).
class PhoneCountry {
  const PhoneCountry({
    required this.iso,
    required this.dial,
    required this.nameFr,
    required this.nameAr,
    required this.min,
    required this.max,
  });

  final String iso;

  /// Indicatif sans « + ».
  final String dial;
  final String nameFr;
  final String nameAr;

  /// Longueur de la partie nationale (sans indicatif).
  final int min;
  final int max;

  String name(String languageCode) => languageCode == 'ar' ? nameAr : nameFr;
}

/// Pays proposés en premier (diaspora et Afrique de l'Ouest). Les autres pays
/// passent par [phoneOtherCountry] : le numéro est alors saisi en entier.
const phoneCountries = <PhoneCountry>[
  PhoneCountry(iso: 'SN', dial: '221', nameFr: 'Sénégal', nameAr: 'السنغال', min: 9, max: 9),
  PhoneCountry(iso: 'FR', dial: '33', nameFr: 'France', nameAr: 'فرنسا', min: 9, max: 9),
  PhoneCountry(iso: 'IT', dial: '39', nameFr: 'Italie', nameAr: 'إيطاليا', min: 9, max: 11),
  PhoneCountry(iso: 'ES', dial: '34', nameFr: 'Espagne', nameAr: 'إسبانيا', min: 9, max: 9),
  PhoneCountry(iso: 'US', dial: '1', nameFr: 'États-Unis / Canada', nameAr: 'الولايات المتحدة / كندا', min: 10, max: 10),
  PhoneCountry(iso: 'BE', dial: '32', nameFr: 'Belgique', nameAr: 'بلجيكا', min: 8, max: 9),
  PhoneCountry(iso: 'DE', dial: '49', nameFr: 'Allemagne', nameAr: 'ألمانيا', min: 10, max: 12),
  PhoneCountry(iso: 'GB', dial: '44', nameFr: 'Royaume-Uni', nameAr: 'المملكة المتحدة', min: 10, max: 10),
  PhoneCountry(iso: 'MR', dial: '222', nameFr: 'Mauritanie', nameAr: 'موريتانيا', min: 8, max: 8),
  PhoneCountry(iso: 'GM', dial: '220', nameFr: 'Gambie', nameAr: 'غامبيا', min: 7, max: 7),
  PhoneCountry(iso: 'ML', dial: '223', nameFr: 'Mali', nameAr: 'مالي', min: 8, max: 8),
  PhoneCountry(iso: 'GN', dial: '224', nameFr: 'Guinée', nameAr: 'غينيا', min: 9, max: 9),
  PhoneCountry(iso: 'CI', dial: '225', nameFr: "Côte d'Ivoire", nameAr: 'ساحل العاج', min: 10, max: 10),
  PhoneCountry(iso: 'MA', dial: '212', nameFr: 'Maroc', nameAr: 'المغرب', min: 9, max: 9),
];

/// Pays par défaut : le Sénégal.
PhoneCountry get defaultPhoneCountry => phoneCountries.first;

/// Choix « autre pays » : le numéro est saisi en entier, indicatif compris.
const phoneOtherCountry = PhoneCountry(
  iso: '',
  dial: '',
  nameFr: 'Autre pays',
  nameAr: 'بلد آخر',
  min: 10,
  max: 15,
);

enum PhoneProblem { empty, tooShort, tooLong, invalidSenegal }

class PhoneResult {
  const PhoneResult.ok(String this.e164) : problem = null;
  const PhoneResult.bad(PhoneProblem this.problem) : e164 = null;

  /// Format `+221771234567`, tel qu'envoyé au serveur.
  final String? e164;
  final PhoneProblem? problem;
  bool get isOk => e164 != null;
}

final _senegalMobile = RegExp(r'^7[0-8]\d{7}$');

/// Valide la saisie [input] pour le pays [country].
///
/// Les chiffres arabo-indiens sont acceptés. Un « 0 » de tête (usage national
/// en France, Belgique…) est retiré seulement quand le numéro est trop long.
PhoneResult validatePhone(PhoneCountry country, String input) {
  var digits = latinDigits(input).replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return const PhoneResult.bad(PhoneProblem.empty);

  if (country.dial.isEmpty) {
    // Numéro international saisi en entier (« 00 » ou « + » de tête acceptés).
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.length < country.min) return const PhoneResult.bad(PhoneProblem.tooShort);
    if (digits.length > country.max) return const PhoneResult.bad(PhoneProblem.tooLong);
    return PhoneResult.ok('+$digits');
  }

  // L'utilisateur a pu coller le numéro avec l'indicatif.
  if (digits.startsWith('00${country.dial}')) {
    digits = digits.substring(2 + country.dial.length);
  } else if (digits.startsWith(country.dial) && digits.length > country.max) {
    digits = digits.substring(country.dial.length);
  }
  if (digits.startsWith('0') && digits.length > country.max) digits = digits.substring(1);

  if (digits.length < country.min) return const PhoneResult.bad(PhoneProblem.tooShort);
  if (digits.length > country.max) return const PhoneResult.bad(PhoneProblem.tooLong);
  if (country.dial == '221' && !_senegalMobile.hasMatch(digits)) {
    return const PhoneResult.bad(PhoneProblem.invalidSenegal);
  }
  return PhoneResult.ok('+${country.dial}$digits');
}

String latinDigits(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0x0660 && r <= 0x0669) {
      b.write(String.fromCharCode(0x30 + r - 0x0660));
    } else if (r >= 0x06F0 && r <= 0x06F9) {
      b.write(String.fromCharCode(0x30 + r - 0x06F0));
    } else {
      b.write(String.fromCharCode(r));
    }
  }
  return b.toString();
}

/// Retrouve le pays et la partie nationale d'un numéro `+221771234567`
/// (pour réafficher un formulaire déjà rempli). Inconnu : « autre pays ».
({PhoneCountry country, String national}) splitE164(String e164) {
  final digits = e164.replaceAll(RegExp(r'\D'), '');
  final sorted = [...phoneCountries]..sort((a, b) => b.dial.length.compareTo(a.dial.length));
  for (final c in sorted) {
    if (digits.startsWith(c.dial) && digits.length - c.dial.length >= c.min) {
      return (country: c, national: digits.substring(c.dial.length));
    }
  }
  return (country: phoneOtherCountry, national: digits);
}
