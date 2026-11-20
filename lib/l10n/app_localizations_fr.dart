// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get loginTitle => 'Espace membre';

  @override
  String get loginSubtitle =>
      'Connectez-vous avec votre téléphone et votre code PIN.';

  @override
  String get phoneLabel => 'Numéro de téléphone';

  @override
  String get phoneHint => '77 123 45 67';

  @override
  String get pinLabel => 'Code PIN (4 chiffres)';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get invalidCredentials =>
      'Identifiants incorrects. Vérifiez votre numéro et votre code.';

  @override
  String tooManyAttempts(int minutes) {
    return 'Trop de tentatives. Réessayez dans $minutes min.';
  }

  @override
  String get networkError =>
      'Connexion impossible. Vérifiez votre réseau et réessayez.';

  @override
  String get genericError =>
      'Une erreur est survenue. Vos données sont en sécurité.';

  @override
  String get sessionExpired => 'Session expirée, reconnectez-vous.';

  @override
  String get pinSetupTitle => 'Créez votre code PIN';

  @override
  String get pinSetupBody =>
      'Première connexion : choisissez 4 chiffres que vous seul connaissez. Ne le partagez pas, même avec un responsable.';

  @override
  String get newPinLabel => 'Nouveau code';

  @override
  String get confirmPinLabel => 'Confirmez le code';

  @override
  String get pinMismatch => 'Les deux codes ne correspondent pas.';

  @override
  String get pinSave => 'Enregistrer et continuer';

  @override
  String homeGreeting(String name) {
    return 'Salam, $name';
  }

  @override
  String get heroTitle => 'Ensemble, servons la Mouridiyah';

  @override
  String get heroSubtitle => 'Foi · Discipline · Savoir · Excellence';

  @override
  String dueCardTitle(String month) {
    return 'Cotisation de $month';
  }

  @override
  String get statusUpToDate => 'À jour';

  @override
  String get statusPending => 'En attente';

  @override
  String get statusDue => 'À régler';

  @override
  String get actionPay => 'Payer ma cotisation';

  @override
  String get actionCard => 'Ma carte membre';

  @override
  String get actionContribute => 'Contribuer';

  @override
  String get actionBarkelu => 'Barkelu';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get versementsTitle => 'Mes versements';

  @override
  String get noVersements => 'Aucun versement';

  @override
  String get noVersementsBody =>
      'Aucun versement n’est disponible dans l’application pour ce compte. Tu peux consulter ton historique complet sur le site.';

  @override
  String get paidLabel => 'Payé';

  @override
  String get accountTitle => 'Mon compte';

  @override
  String get memberActive => 'Membre actif';

  @override
  String get languageLabel => 'Langue';

  @override
  String get appearanceLabel => 'Apparence';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get langSystem => 'Système';

  @override
  String get logoutButton => 'Se déconnecter';

  @override
  String versionLabel(String v) {
    return 'Version $v';
  }

  @override
  String get barkeluSoonBody =>
      'La boutique Barkelu prépare ses premiers articles. Revenez bientôt.';

  @override
  String get maintenanceTitle => 'Maintenance en cours';

  @override
  String get maintenanceBody =>
      'Le service reprendra dans quelques minutes. Merci de votre patience.';

  @override
  String get retryButton => 'Réessayer';

  @override
  String get updateRequiredTitle => 'Mise à jour nécessaire';

  @override
  String get updateRequiredBody =>
      'Cette version de l\'application n\'est plus prise en charge. Mettez-la à jour pour continuer.';

  @override
  String get updateButton => 'Mettre à jour';

  @override
  String get offlineTitle => 'Vous êtes hors ligne';

  @override
  String get offlineBody => 'Reconnectez-vous pour continuer.';

  @override
  String get unknownScreenTitle => 'Cette rubrique nécessite une mise à jour';

  @override
  String get unknownScreenBody =>
      'Mettez à jour l\'application pour y accéder.';

  @override
  String get loginRequiredTitle => 'Connexion requise';

  @override
  String get loginRequiredBody =>
      'Connectez-vous pour accéder à cette rubrique.';

  @override
  String get loading => 'Chargement…';

  @override
  String get firstLoginLink => 'Première connexion ?';

  @override
  String get firstLoginLabel => '4 derniers caractères de votre N° de membre';

  @override
  String get firstLoginHelp =>
      'Ils figurent sur votre carte membre et dans le message WhatsApp reçu à l\'adhésion.';

  @override
  String get havePinLink => 'J\'ai déjà un code PIN';

  @override
  String get firstLoginContinue => 'Continuer';

  @override
  String get payTitle => 'Payer ma cotisation';

  @override
  String get payChooseIntro =>
      'Choisissez le nombre de mois à régler. Les mois les plus récents sont réglés en premier.';

  @override
  String get payMonthsMinus => 'Retirer un mois';

  @override
  String get payMonthsPlus => 'Ajouter un mois';

  @override
  String get payMonthsLabel => 'Nombre de mois';

  @override
  String get payMonthLate => 'En retard';

  @override
  String get payMonthCurrent => 'Mois en cours';

  @override
  String get payTotalLabel => 'Total';

  @override
  String get payContinue => 'Continuer';

  @override
  String get payMethodTitle => 'Moyen de paiement';

  @override
  String get payMethodWave => 'Wave';

  @override
  String get payMethodWaveSub => 'Validation dans l\'application Wave';

  @override
  String get payMethodOrange => 'Orange Money';

  @override
  String get payMethodOrangeSub => 'Validation dans l\'application Orange';

  @override
  String get payMethodCard => 'Carte bancaire';

  @override
  String get payMethodCardSub => 'Page de paiement sécurisée';

  @override
  String get payPhoneLabel => 'Numéro à débiter';

  @override
  String get payPhoneRequired => 'Saisissez le numéro à débiter.';

  @override
  String payWithMethod(String method) {
    return 'Payer avec $method';
  }

  @override
  String get payWaitingTitle => 'En attente de confirmation';

  @override
  String payWaitingBody(String method) {
    return 'Validez le paiement dans $method. Ne fermez pas l\'application : nous attendons la confirmation.';
  }

  @override
  String get payNotYetPaidTitle => 'Pas encore payé';

  @override
  String get payNotYetPaidBody =>
      'Votre cotisation sera enregistrée uniquement quand le paiement sera confirmé.';

  @override
  String get payReopenButton => 'Ouvrir à nouveau';

  @override
  String get payChangeMethod => 'Changer de moyen';

  @override
  String get payDoneTitle => 'Paiement confirmé';

  @override
  String payDoneBody(String months, String amount) {
    return 'Merci. Votre cotisation ($months) est enregistrée : $amount.';
  }

  @override
  String get payReceipt => 'Voir mon reçu';

  @override
  String get payFinish => 'Terminer';

  @override
  String get payFailedTitle => 'Paiement non abouti';

  @override
  String get payFailedBody =>
      'Le paiement a été annulé ou refusé. Aucun montant n\'a été enregistré.';

  @override
  String get payRetry => 'Réessayer';

  @override
  String get payTimeoutTitle => 'Confirmation pas encore reçue';

  @override
  String get payTimeoutBody =>
      'Si vous avez payé, la confirmation peut prendre quelques minutes. Votre cotisation sera mise à jour dès qu\'elle arrivera.';

  @override
  String get payCheckNow => 'Vérifier maintenant';

  @override
  String get payCheckLater => 'Vérifier plus tard';

  @override
  String get payUnavailableTitle => 'Paiement indisponible';

  @override
  String get payUnavailableBody =>
      'Le paiement en ligne n\'est pas disponible pour le moment. Réessayez plus tard.';

  @override
  String get payUpToDateTitle => 'Vous êtes à jour';

  @override
  String get payUpToDateBody => 'Aucune cotisation à régler pour le moment.';

  @override
  String get payOpenFailed =>
      'Impossible d\'ouvrir l\'application de paiement. Choisissez la carte bancaire ou réessayez.';

  @override
  String get payChangeMonths => 'Modifier le nombre de mois';

  @override
  String get cardTitle => 'Ma carte membre';

  @override
  String get cardHint => 'Présentez ce QR code pour faire valider votre carte.';

  @override
  String get cardShare => 'Partager';

  @override
  String get cardShareFailed => 'Le partage a échoué. Réessayez.';

  @override
  String cardStaleBanner(String date) {
    return 'Hors ligne : version enregistrée le $date.';
  }

  @override
  String get cardUnavailableTitle => 'Carte indisponible';

  @override
  String get cardUnavailableBody =>
      'Votre carte n\'est pas disponible pour le moment.';

  @override
  String get cardLoadFailedBody =>
      'Impossible de charger la carte. Vérifiez votre réseau et réessayez.';

  @override
  String cardImageLabel(String name) {
    return 'Carte membre de $name';
  }

  @override
  String get joinTitle => 'Devenir membre';

  @override
  String get joinIntro =>
      'Rejoignez Ahloul Khidmah en quelques clics : nom, prénom, téléphone, pays et montant, puis payez en ligne.';

  @override
  String get joinIdentityTitle => 'Vous identifier';

  @override
  String get joinAmountTitle => 'Choisir votre montant';

  @override
  String get joinAmountSubtitle => 'Cotisation mensuelle';

  @override
  String get joinNotMemberYet =>
      'Vous devenez membre uniquement après la confirmation du paiement.';

  @override
  String get joinSubmit => 'Adhérer';

  @override
  String get joinNotYetPaidBody =>
      'Votre adhésion sera enregistrée uniquement quand le paiement sera confirmé.';

  @override
  String get joinEditInfo => 'Modifier mes informations';

  @override
  String get joinDoneTitle => 'Paiement confirmé';

  @override
  String joinDoneBody(String amount) {
    return 'Merci, votre adhésion ($amount) est enregistrée. Votre carte de membre vous est envoyée par WhatsApp au numéro indiqué.';
  }

  @override
  String get joinDoneLogin =>
      'Ensuite, connectez-vous à l\'application : « Première connexion ? » demande les 4 derniers caractères du numéro de votre carte.';

  @override
  String get joinDuplicate =>
      'Ce numéro est déjà inscrit. Connectez-vous avec votre compte membre.';

  @override
  String get joinHaveAccount => 'Déjà membre ? Se connecter';

  @override
  String get joinLink => 'Pas encore membre ? Adhérer';

  @override
  String get fieldLastName => 'Nom';

  @override
  String get fieldFirstNames => 'Prénom(s)';

  @override
  String get fieldPhoneWhatsapp => 'Téléphone / WhatsApp';

  @override
  String get fieldDial => 'Indicatif';

  @override
  String get fieldPhoneFull => 'Numéro complet avec indicatif';

  @override
  String get fieldCountryRegion => 'Pays ou région';

  @override
  String get fieldCountryRegionHint => 'Ex : Sénégal, France, Touba, Dakar…';

  @override
  String get fieldEmailOptional => 'Email (optionnel)';

  @override
  String get fieldAmountOther => 'Montant en FCFA';

  @override
  String get amountPerMonth => 'par mois';

  @override
  String get amountOther => 'Autre montant';

  @override
  String get errRequired => 'Champ obligatoire.';

  @override
  String get errTooShort => 'Au moins 2 caractères.';

  @override
  String get errPhoneShort => 'Numéro incomplet.';

  @override
  String get errPhoneLong => 'Numéro trop long.';

  @override
  String get errPhoneSenegal =>
      'Numéro sénégalais invalide : 9 chiffres commençant par 70, 75, 76, 77 ou 78.';

  @override
  String get errEmail => 'Email invalide.';

  @override
  String errAmountMin(String amount) {
    return 'Montant minimum : $amount.';
  }

  @override
  String get errAmountMissing => 'Précisez le montant.';

  @override
  String get errServerInvalid =>
      'Certaines informations sont refusées. Vérifiez le formulaire.';

  @override
  String get donateIdentityTitle => 'Vos coordonnées';

  @override
  String get donateIdentitySubtitle => 'Optionnel si vous restez anonyme';

  @override
  String get donateAnonymous => 'Je souhaite rester anonyme';

  @override
  String get donateMemberNote =>
      'Si vous indiquez votre téléphone, une fiche de membre (sans cotisation mensuelle) peut être créée à partir de votre don.';

  @override
  String get donateAmountTitle => 'Montant';

  @override
  String get donateCampaign => 'Destination';

  @override
  String get campaignGeneral => 'Soutien général';

  @override
  String get campaignTouba => 'Projets à Touba';

  @override
  String get campaignMagal => 'Magal / grands événements';

  @override
  String get campaignEducation => 'Éducation & compétences';

  @override
  String get campaignOther => 'Autre';

  @override
  String get donateMessage => 'Message (optionnel)';

  @override
  String get donateMessageHint =>
      'Une intention, une dédicace, ou un mot pour l\'équipe.';

  @override
  String get donateSubmit => 'Continuer vers le paiement';

  @override
  String get donateNotYetPaidBody =>
      'Votre contribution sera enregistrée uniquement quand le paiement sera confirmé.';

  @override
  String get donateDoneTitle => 'Merci pour votre soutien';

  @override
  String donateDoneBody(String amount) {
    return 'Votre contribution de $amount est confirmée.';
  }

  @override
  String get donateEditInfo => 'Modifier ma contribution';

  @override
  String get publicTimeoutBody =>
      'Si vous avez payé, la confirmation peut prendre quelques minutes. Rien n\'est enregistré tant qu\'elle n\'est pas reçue.';

  @override
  String get waveManualTitle => 'Adhésion enregistrée, paiement à faire';

  @override
  String waveManualBody(String amount, String number, String reference) {
    return 'Le paiement en ligne est indisponible. Envoyez $amount par Wave au $number en indiquant la référence $reference.';
  }

  @override
  String get waveManualNotPaid =>
      'Votre paiement n\'est pas encore reçu : cette adhésion n\'est pas payée.';

  @override
  String get homeJoin => 'Adhérer';

  @override
  String get homeContribute => 'Faire un don';

  @override
  String get officialPageError => 'Impossible d’ouvrir ce lien. Réessayez.';

  @override
  String get mediaOpen => 'Voir la médiathèque';

  @override
  String get shopOpenWeb => 'Ouvrir la boutique';

  @override
  String get shopWebCheckout =>
      'Consultez les options, le panier et la livraison dans la boutique officielle.';

  @override
  String get accountAccessHeading => 'Accès au compte';

  @override
  String get accountWebHint =>
      'Connectez-vous à votre espace membre sur le site pour gérer votre code PIN.';

  @override
  String get accountOpenWeb => 'Ouvrir mon espace sur le site';

  @override
  String get accountForgotPin => 'Code PIN oublié ?';

  @override
  String get accountRecoveryHint =>
      'Contactez l’équipe Ahloul Khidmah si vous ne pouvez plus vous connecter. Gardez votre code PIN confidentiel.';

  @override
  String get accountContactSupport => 'Contacter l’équipe sur WhatsApp';

  @override
  String get pushUpdateError =>
      'Impossible de mettre à jour les notifications. Réessayez.';

  @override
  String get pushSettingTitle => 'Notifications';

  @override
  String get pushSettingSubtitle =>
      'Recevoir les rappels de cotisation et les annonces de l\'association.';

  @override
  String get pushDenied =>
      'Notifications refusées. Activez-les dans les réglages du téléphone.';

  @override
  String get pushOpen => 'Ouvrir';

  @override
  String get cardMobileUnavailable =>
      'La carte n’est pas disponible dans l’application pour le moment. Consulte ton espace membre sur le site.';

  @override
  String get payMobileUnavailable =>
      'Le paiement des cotisations n’est pas disponible dans l’application pour le moment. Ouvre ton espace membre sur le site pour continuer.';

  @override
  String get historyOpenWeb => 'Voir l’historique complet sur le site';

  @override
  String get onboardingMission => 'Ensemble, servons la Mouridiyah';

  @override
  String get onboardingMissionBody =>
      'Ahloul Khidmah rassemble les compétences et les talents au service de Touba.';

  @override
  String get onboardingCommunity => 'Une communauté engagée';

  @override
  String get onboardingCommunityBody =>
      'Rejoignez une cellule locale ou soutenez les actions de la communauté par un don.';

  @override
  String get onboardingServices => 'Votre espace membre';

  @override
  String get onboardingServicesBody =>
      'Retrouvez votre carte membre, suivez vos cotisations et découvrez Barkelu.';

  @override
  String onboardingStep(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String get onboardingStart => 'Commencer';

  @override
  String get onboardingNext => 'Continuer';

  @override
  String get onboardingBack => 'Retour';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get galleryOpen => 'Explorer les photos';

  @override
  String get galleryTitle => 'Images du khidma';

  @override
  String get galleryPhoto0 => 'Grande Mosquée de Touba — vue drone';

  @override
  String get galleryPhoto1 => 'Touba — vue aérienne';

  @override
  String get galleryPhoto2 => 'Communauté et service à Touba';

  @override
  String get galleryPhoto3 => 'Scène communautaire Ahloul Khidmah';

  @override
  String get galleryPhoto4 => 'Engagement et khidma';

  @override
  String get galleryPhoto5 => 'Culture mouride';

  @override
  String get galleryPhoto6 => 'Héritage de Cheikh Ahmadou Bamba';

  @override
  String get cardFullScreen => 'Agrandir la carte';

  @override
  String get shopSearch => 'Rechercher un produit';

  @override
  String get shopNoMatches => 'Aucun produit ne correspond à cette recherche.';
}
