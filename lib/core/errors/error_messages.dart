import '../../l10n/app_localizations.dart';
import '../api/api_error.dart';

/// Message affiché à l'utilisateur pour une erreur d'API.
///
/// Jamais de code technique à l'écran ; la connexion renvoie toujours le même
/// message pour un compte inexistant et un mauvais code (pas d'énumération).
String messageForError(AppLocalizations l, Object error) {
  if (error is! ApiException) return l.genericError;
  if (error.isNetwork) return l.networkError;
  if (error.isRateLimited) {
    final seconds = error.retryAfter?.inSeconds ?? 900;
    return l.tooManyAttempts((seconds / 60).ceil().clamp(1, 60));
  }
  switch (error.code) {
    case 'invalid_credentials':
    case 'invalid_request':
      return l.invalidCredentials;
    case 'invalid_refresh':
    case 'unauthorized':
      return l.sessionExpired;
    default:
      return l.genericError;
  }
}

/// Message pour une erreur des endpoints **publics** du site (adhésion, don,
/// SoftPay, statut). Ils ne renvoient pas de code normalisé : on se fie au
/// statut HTTP. Jamais de texte du serveur à l'écran (français seulement).
String publicErrorMessage(AppLocalizations l, Object error) {
  if (error is ApiException) {
    if (error.code == 'phone_required') return l.payPhoneRequired;
    switch (error.status) {
      case 409:
        return l.joinDuplicate;
      case 400:
        return l.errServerInvalid;
      case 502:
      case 503:
        return l.payUnavailableBody;
    }
  }
  return messageForError(l, error);
}
