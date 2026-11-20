import 'package:intl/intl.dart';

/// Mise en forme des montants et des périodes.
///
/// Français : `1 400 FCFA` avec une espace **insécable U+00A0**. Le livre de
/// marque prévoyait l'espace fine U+202F, mais la police Cairo ne contient pas
/// ce caractère (vérifié) : U+00A0 s'affiche partout.
///
/// Arabe : chiffres arabo-indiens, séparateur de milliers arabe `٬` (U+066C)
/// et « فرنك », comme le site. Convention encore à valider (fiche de relecture).
String formatAmount(int amount, String languageCode) {
  final negative = amount < 0;
  final digits = amount.abs().toString();
  final isAr = languageCode == 'ar';
  final sep = isAr ? '٬' : ' ';
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(sep);
    buf.write(digits[i]);
  }
  var out = buf.toString();
  if (isAr) out = toArabicIndicDigits(out);
  return '${negative ? '-' : ''}$out${isAr ? ' فرنك' : ' FCFA'}';
}

String toArabicIndicDigits(String s) {
  const latin = '0123456789';
  final b = StringBuffer();
  for (final ch in s.runes) {
    final i = latin.indexOf(String.fromCharCode(ch));
    b.write(i >= 0 ? String.fromCharCode(0x0660 + i) : String.fromCharCode(ch));
  }
  return b.toString();
}

/// Période courante au format `YYYY-MM`.
String currentPeriode(DateTime now) =>
    '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';

/// « novembre 2026 » / « نوفمبر 2026 » à partir de `YYYY-MM`. Le serveur ne
/// fournit le libellé qu'en français : l'application le calcule pour la langue
/// d'affichage. Requiert `initializeDateFormatting` (fait au démarrage et par
/// les délégués de localisation).
String periodeLabel(String periode, String languageCode) {
  final parts = periode.split('-');
  final y = parts.length == 2 ? int.tryParse(parts[0]) : null;
  final m = parts.length == 2 ? int.tryParse(parts[1]) : null;
  if (y == null || m == null || m < 1 || m > 12) return periode;
  try {
    return DateFormat.yMMMM(languageCode).format(DateTime(y, m));
  } on Object {
    return periode;
  }
}
