import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('fr')
  ];

  /// No description provided for @aboutTitle.
  ///
  /// In fr, this message translates to:
  /// **'Qui sommes-nous ?'**
  String get aboutTitle;

  /// No description provided for @aboutHeroTitle.
  ///
  /// In fr, this message translates to:
  /// **'Servir ensemble'**
  String get aboutHeroTitle;

  /// No description provided for @aboutHeroBody.
  ///
  /// In fr, this message translates to:
  /// **'Une communauté engagée pour Touba et la Mouridiyah.'**
  String get aboutHeroBody;

  /// No description provided for @aboutMissionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notre raison d’être'**
  String get aboutMissionTitle;

  /// No description provided for @aboutMissionBody.
  ///
  /// In fr, this message translates to:
  /// **'Ahloul Khidmah rassemble des personnes qui souhaitent mettre leur temps, leurs compétences et leurs ressources au service de la communauté. Notre démarche associe le savoir, le travail et la solidarité pour faire avancer des projets utiles dans la durée.'**
  String get aboutMissionBody;

  /// No description provided for @aboutPillarsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Du service à l’action'**
  String get aboutPillarsTitle;

  /// No description provided for @aboutMobilize.
  ///
  /// In fr, this message translates to:
  /// **'Mobiliser'**
  String get aboutMobilize;

  /// No description provided for @aboutMobilizeBody.
  ///
  /// In fr, this message translates to:
  /// **'Rassembler celles et ceux qui souhaitent contribuer.'**
  String get aboutMobilizeBody;

  /// No description provided for @aboutOrganize.
  ///
  /// In fr, this message translates to:
  /// **'Organiser'**
  String get aboutOrganize;

  /// No description provided for @aboutOrganizeBody.
  ///
  /// In fr, this message translates to:
  /// **'Coordonner les compétences et les initiatives.'**
  String get aboutOrganizeBody;

  /// No description provided for @aboutFund.
  ///
  /// In fr, this message translates to:
  /// **'Financer'**
  String get aboutFund;

  /// No description provided for @aboutFundBody.
  ///
  /// In fr, this message translates to:
  /// **'Réunir les moyens nécessaires aux projets.'**
  String get aboutFundBody;

  /// No description provided for @aboutImpact.
  ///
  /// In fr, this message translates to:
  /// **'Agir durablement'**
  String get aboutImpact;

  /// No description provided for @aboutImpactBody.
  ///
  /// In fr, this message translates to:
  /// **'Soutenir des actions utiles à la communauté.'**
  String get aboutImpactBody;

  /// No description provided for @aboutContacts.
  ///
  /// In fr, this message translates to:
  /// **'Nous contacter'**
  String get aboutContacts;

  /// No description provided for @aboutLocation.
  ///
  /// In fr, this message translates to:
  /// **'Touba, Sénégal'**
  String get aboutLocation;

  /// No description provided for @aboutEmail.
  ///
  /// In fr, this message translates to:
  /// **'Courriel'**
  String get aboutEmail;

  /// No description provided for @aboutReadOfficial.
  ///
  /// In fr, this message translates to:
  /// **'Lire la présentation officielle'**
  String get aboutReadOfficial;

  /// No description provided for @aboutWhatsApp.
  ///
  /// In fr, this message translates to:
  /// **'Contacter sur WhatsApp'**
  String get aboutWhatsApp;

  /// No description provided for @cardDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails de la carte'**
  String get cardDetails;

  /// No description provided for @contributionsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Cotisations'**
  String get contributionsLabel;

  /// No description provided for @mediaLabel.
  ///
  /// In fr, this message translates to:
  /// **'Médiathèque'**
  String get mediaLabel;

  /// No description provided for @assalamuAlaykum.
  ///
  /// In fr, this message translates to:
  /// **'Salam alaykoum'**
  String get assalamuAlaykum;

  /// No description provided for @welcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur Ahloul Khidmah'**
  String get welcomeTitle;

  /// No description provided for @shopSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'La boutique solidaire Ahloul Khidmah'**
  String get shopSubtitle;

  /// No description provided for @shopAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous les produits'**
  String get shopAll;

  /// No description provided for @loginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Espace membre'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous avec votre téléphone et votre code PIN.'**
  String get loginSubtitle;

  /// No description provided for @phoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get phoneLabel;

  /// No description provided for @phoneHint.
  ///
  /// In fr, this message translates to:
  /// **'77 123 45 67'**
  String get phoneHint;

  /// No description provided for @pinLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN (4 chiffres)'**
  String get pinLabel;

  /// No description provided for @loginButton.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginButton;

  /// No description provided for @invalidCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants incorrects. Vérifiez votre numéro et votre code.'**
  String get invalidCredentials;

  /// No description provided for @tooManyAttempts.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Réessayez dans {minutes} min.'**
  String tooManyAttempts(int minutes);

  /// No description provided for @networkError.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Vérifiez votre réseau et réessayez.'**
  String get networkError;

  /// No description provided for @genericError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Vos données sont en sécurité.'**
  String get genericError;

  /// No description provided for @sessionExpired.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée, reconnectez-vous.'**
  String get sessionExpired;

  /// No description provided for @pinSetupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre code PIN'**
  String get pinSetupTitle;

  /// No description provided for @pinSetupBody.
  ///
  /// In fr, this message translates to:
  /// **'Première connexion : choisissez 4 chiffres que vous seul connaissez. Ne le partagez pas, même avec un responsable.'**
  String get pinSetupBody;

  /// No description provided for @newPinLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau code'**
  String get newPinLabel;

  /// No description provided for @confirmPinLabel.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez le code'**
  String get confirmPinLabel;

  /// No description provided for @pinMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les deux codes ne correspondent pas.'**
  String get pinMismatch;

  /// No description provided for @pinSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer et continuer'**
  String get pinSave;

  /// No description provided for @homeGreeting.
  ///
  /// In fr, this message translates to:
  /// **'Salam, {name}'**
  String homeGreeting(String name);

  /// No description provided for @heroTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ensemble, servons la Mouridiyah'**
  String get heroTitle;

  /// No description provided for @heroSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Foi · Discipline · Savoir · Excellence'**
  String get heroSubtitle;

  /// No description provided for @dueCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Cotisation de {month}'**
  String dueCardTitle(String month);

  /// No description provided for @statusUpToDate.
  ///
  /// In fr, this message translates to:
  /// **'À jour'**
  String get statusUpToDate;

  /// No description provided for @statusPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get statusPending;

  /// No description provided for @statusDue.
  ///
  /// In fr, this message translates to:
  /// **'À régler'**
  String get statusDue;

  /// No description provided for @actionPay.
  ///
  /// In fr, this message translates to:
  /// **'Payer ma cotisation'**
  String get actionPay;

  /// No description provided for @actionCard.
  ///
  /// In fr, this message translates to:
  /// **'Ma carte membre'**
  String get actionCard;

  /// No description provided for @actionContribute.
  ///
  /// In fr, this message translates to:
  /// **'Contribuer'**
  String get actionContribute;

  /// No description provided for @actionBarkelu.
  ///
  /// In fr, this message translates to:
  /// **'Barkelu'**
  String get actionBarkelu;

  /// No description provided for @comingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get comingSoon;

  /// No description provided for @versementsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes versements'**
  String get versementsTitle;

  /// No description provided for @noVersements.
  ///
  /// In fr, this message translates to:
  /// **'Aucun versement'**
  String get noVersements;

  /// No description provided for @noVersementsBody.
  ///
  /// In fr, this message translates to:
  /// **'Aucun versement n’est disponible dans l’application pour ce compte. Tu peux consulter ton historique complet sur le site.'**
  String get noVersementsBody;

  /// No description provided for @paidLabel.
  ///
  /// In fr, this message translates to:
  /// **'Payé'**
  String get paidLabel;

  /// No description provided for @accountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get accountTitle;

  /// No description provided for @memberActive.
  ///
  /// In fr, this message translates to:
  /// **'Membre actif'**
  String get memberActive;

  /// No description provided for @languageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get languageLabel;

  /// No description provided for @appearanceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get appearanceLabel;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @langSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get langSystem;

  /// No description provided for @logoutButton.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logoutButton;

  /// No description provided for @versionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Version {v}'**
  String versionLabel(String v);

  /// No description provided for @barkeluSoonBody.
  ///
  /// In fr, this message translates to:
  /// **'La boutique Barkelu prépare ses premiers articles. Revenez bientôt.'**
  String get barkeluSoonBody;

  /// No description provided for @maintenanceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Maintenance en cours'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceBody.
  ///
  /// In fr, this message translates to:
  /// **'Le service reprendra dans quelques minutes. Merci de votre patience.'**
  String get maintenanceBody;

  /// No description provided for @retryButton.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retryButton;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour nécessaire'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In fr, this message translates to:
  /// **'Cette version de l\'application n\'est plus prise en charge. Mettez-la à jour pour continuer.'**
  String get updateRequiredBody;

  /// No description provided for @updateButton.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get updateButton;

  /// No description provided for @offlineTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes hors ligne'**
  String get offlineTitle;

  /// No description provided for @offlineBody.
  ///
  /// In fr, this message translates to:
  /// **'Reconnectez-vous pour continuer.'**
  String get offlineBody;

  /// No description provided for @unknownScreenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Cette rubrique nécessite une mise à jour'**
  String get unknownScreenTitle;

  /// No description provided for @unknownScreenBody.
  ///
  /// In fr, this message translates to:
  /// **'Mettez à jour l\'application pour y accéder.'**
  String get unknownScreenBody;

  /// No description provided for @loginRequiredTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion requise'**
  String get loginRequiredTitle;

  /// No description provided for @loginRequiredBody.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour accéder à cette rubrique.'**
  String get loginRequiredBody;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get loading;

  /// No description provided for @firstLoginLink.
  ///
  /// In fr, this message translates to:
  /// **'Première connexion ?'**
  String get firstLoginLink;

  /// No description provided for @firstLoginLabel.
  ///
  /// In fr, this message translates to:
  /// **'4 derniers caractères de votre N° de membre'**
  String get firstLoginLabel;

  /// No description provided for @firstLoginHelp.
  ///
  /// In fr, this message translates to:
  /// **'Ils figurent sur votre carte membre et dans le message WhatsApp reçu à l\'adhésion.'**
  String get firstLoginHelp;

  /// No description provided for @havePinLink.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai déjà un code PIN'**
  String get havePinLink;

  /// No description provided for @firstLoginContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get firstLoginContinue;

  /// No description provided for @payTitle.
  ///
  /// In fr, this message translates to:
  /// **'Payer ma cotisation'**
  String get payTitle;

  /// No description provided for @payChooseIntro.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le nombre de mois à régler. Les mois les plus récents sont réglés en premier.'**
  String get payChooseIntro;

  /// No description provided for @payMonthsMinus.
  ///
  /// In fr, this message translates to:
  /// **'Retirer un mois'**
  String get payMonthsMinus;

  /// No description provided for @payMonthsPlus.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un mois'**
  String get payMonthsPlus;

  /// No description provided for @payMonthsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de mois'**
  String get payMonthsLabel;

  /// No description provided for @payMonthLate.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get payMonthLate;

  /// No description provided for @payMonthCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Mois en cours'**
  String get payMonthCurrent;

  /// No description provided for @payTotalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get payTotalLabel;

  /// No description provided for @payContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get payContinue;

  /// No description provided for @payMethodTitle.
  ///
  /// In fr, this message translates to:
  /// **'Moyen de paiement'**
  String get payMethodTitle;

  /// No description provided for @payMethodWave.
  ///
  /// In fr, this message translates to:
  /// **'Wave'**
  String get payMethodWave;

  /// No description provided for @payMethodWaveSub.
  ///
  /// In fr, this message translates to:
  /// **'Validation dans l\'application Wave'**
  String get payMethodWaveSub;

  /// No description provided for @payMethodOrange.
  ///
  /// In fr, this message translates to:
  /// **'Orange Money'**
  String get payMethodOrange;

  /// No description provided for @payMethodOrangeSub.
  ///
  /// In fr, this message translates to:
  /// **'Validation dans l\'application Orange'**
  String get payMethodOrangeSub;

  /// No description provided for @payMethodCard.
  ///
  /// In fr, this message translates to:
  /// **'Carte bancaire'**
  String get payMethodCard;

  /// No description provided for @payMethodCardSub.
  ///
  /// In fr, this message translates to:
  /// **'Page de paiement sécurisée'**
  String get payMethodCardSub;

  /// No description provided for @payPhoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro à débiter'**
  String get payPhoneLabel;

  /// No description provided for @payPhoneRequired.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le numéro à débiter.'**
  String get payPhoneRequired;

  /// No description provided for @payWithMethod.
  ///
  /// In fr, this message translates to:
  /// **'Payer avec {method}'**
  String payWithMethod(String method);

  /// No description provided for @payWaitingTitle.
  ///
  /// In fr, this message translates to:
  /// **'En attente de confirmation'**
  String get payWaitingTitle;

  /// No description provided for @payWaitingBody.
  ///
  /// In fr, this message translates to:
  /// **'Validez le paiement dans {method}. Ne fermez pas l\'application : nous attendons la confirmation.'**
  String payWaitingBody(String method);

  /// No description provided for @payNotYetPaidTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore payé'**
  String get payNotYetPaidTitle;

  /// No description provided for @payNotYetPaidBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre cotisation sera enregistrée uniquement quand le paiement sera confirmé.'**
  String get payNotYetPaidBody;

  /// No description provided for @payReopenButton.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir à nouveau'**
  String get payReopenButton;

  /// No description provided for @payChangeMethod.
  ///
  /// In fr, this message translates to:
  /// **'Changer de moyen'**
  String get payChangeMethod;

  /// No description provided for @payDoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement confirmé'**
  String get payDoneTitle;

  /// No description provided for @payDoneBody.
  ///
  /// In fr, this message translates to:
  /// **'Merci. Votre cotisation ({months}) est enregistrée : {amount}.'**
  String payDoneBody(String months, String amount);

  /// No description provided for @payReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Voir mon reçu'**
  String get payReceipt;

  /// No description provided for @payFinish.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get payFinish;

  /// No description provided for @payFailedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement non abouti'**
  String get payFailedTitle;

  /// No description provided for @payFailedBody.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement a été annulé ou refusé. Aucun montant n\'a été enregistré.'**
  String get payFailedBody;

  /// No description provided for @payRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get payRetry;

  /// No description provided for @payTimeoutTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation pas encore reçue'**
  String get payTimeoutTitle;

  /// No description provided for @payTimeoutBody.
  ///
  /// In fr, this message translates to:
  /// **'Si vous avez payé, la confirmation peut prendre quelques minutes. Votre cotisation sera mise à jour dès qu\'elle arrivera.'**
  String get payTimeoutBody;

  /// No description provided for @payCheckNow.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier maintenant'**
  String get payCheckNow;

  /// No description provided for @payCheckLater.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier plus tard'**
  String get payCheckLater;

  /// No description provided for @payUnavailableTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement indisponible'**
  String get payUnavailableTitle;

  /// No description provided for @payUnavailableBody.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement en ligne n\'est pas disponible pour le moment. Réessayez plus tard.'**
  String get payUnavailableBody;

  /// No description provided for @payUpToDateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes à jour'**
  String get payUpToDateTitle;

  /// No description provided for @payUpToDateBody.
  ///
  /// In fr, this message translates to:
  /// **'Aucune cotisation à régler pour le moment.'**
  String get payUpToDateBody;

  /// No description provided for @payOpenFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir l\'application de paiement. Choisissez la carte bancaire ou réessayez.'**
  String get payOpenFailed;

  /// No description provided for @payChangeMonths.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le nombre de mois'**
  String get payChangeMonths;

  /// No description provided for @cardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ma carte membre'**
  String get cardTitle;

  /// No description provided for @cardHint.
  ///
  /// In fr, this message translates to:
  /// **'Présentez ce QR code pour faire valider votre carte.'**
  String get cardHint;

  /// No description provided for @cardShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get cardShare;

  /// No description provided for @cardShareFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le partage a échoué. Réessayez.'**
  String get cardShareFailed;

  /// No description provided for @cardStaleBanner.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne : version enregistrée le {date}.'**
  String cardStaleBanner(String date);

  /// No description provided for @cardUnavailableTitle.
  ///
  /// In fr, this message translates to:
  /// **'Carte indisponible'**
  String get cardUnavailableTitle;

  /// No description provided for @cardUnavailableBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre carte n\'est pas disponible pour le moment.'**
  String get cardUnavailableBody;

  /// No description provided for @cardLoadFailedBody.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la carte. Vérifiez votre réseau et réessayez.'**
  String get cardLoadFailedBody;

  /// No description provided for @cardImageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Carte membre de {name}'**
  String cardImageLabel(String name);

  /// No description provided for @joinTitle.
  ///
  /// In fr, this message translates to:
  /// **'Devenir membre'**
  String get joinTitle;

  /// No description provided for @joinIntro.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez Ahloul Khidmah en quelques clics : nom, prénom, téléphone, pays et montant, puis payez en ligne.'**
  String get joinIntro;

  /// No description provided for @joinIdentityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous identifier'**
  String get joinIdentityTitle;

  /// No description provided for @joinAmountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir votre montant'**
  String get joinAmountTitle;

  /// No description provided for @joinAmountSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Cotisation mensuelle'**
  String get joinAmountSubtitle;

  /// No description provided for @joinNotMemberYet.
  ///
  /// In fr, this message translates to:
  /// **'Vous devenez membre uniquement après la confirmation du paiement.'**
  String get joinNotMemberYet;

  /// No description provided for @joinSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Adhérer'**
  String get joinSubmit;

  /// No description provided for @joinNotYetPaidBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre adhésion sera enregistrée uniquement quand le paiement sera confirmé.'**
  String get joinNotYetPaidBody;

  /// No description provided for @joinEditInfo.
  ///
  /// In fr, this message translates to:
  /// **'Modifier mes informations'**
  String get joinEditInfo;

  /// No description provided for @joinDoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement confirmé'**
  String get joinDoneTitle;

  /// No description provided for @joinDoneBody.
  ///
  /// In fr, this message translates to:
  /// **'Merci, votre adhésion ({amount}) est enregistrée. Votre carte de membre vous est envoyée par WhatsApp au numéro indiqué.'**
  String joinDoneBody(String amount);

  /// No description provided for @joinDoneLogin.
  ///
  /// In fr, this message translates to:
  /// **'Ensuite, connectez-vous à l\'application : « Première connexion ? » demande les 4 derniers caractères du numéro de votre carte.'**
  String get joinDoneLogin;

  /// No description provided for @joinDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro est déjà inscrit. Connectez-vous avec votre compte membre.'**
  String get joinDuplicate;

  /// No description provided for @joinHaveAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà membre ? Se connecter'**
  String get joinHaveAccount;

  /// No description provided for @joinLink.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore membre ? Adhérer'**
  String get joinLink;

  /// No description provided for @fieldLastName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get fieldLastName;

  /// No description provided for @fieldFirstNames.
  ///
  /// In fr, this message translates to:
  /// **'Prénom(s)'**
  String get fieldFirstNames;

  /// No description provided for @fieldPhoneWhatsapp.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone / WhatsApp'**
  String get fieldPhoneWhatsapp;

  /// No description provided for @fieldDial.
  ///
  /// In fr, this message translates to:
  /// **'Indicatif'**
  String get fieldDial;

  /// No description provided for @fieldPhoneFull.
  ///
  /// In fr, this message translates to:
  /// **'Numéro complet avec indicatif'**
  String get fieldPhoneFull;

  /// No description provided for @fieldCountryRegion.
  ///
  /// In fr, this message translates to:
  /// **'Pays ou région'**
  String get fieldCountryRegion;

  /// No description provided for @fieldCountryRegionHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Sénégal, France, Touba, Dakar…'**
  String get fieldCountryRegionHint;

  /// No description provided for @fieldEmailOptional.
  ///
  /// In fr, this message translates to:
  /// **'Email (optionnel)'**
  String get fieldEmailOptional;

  /// No description provided for @fieldAmountOther.
  ///
  /// In fr, this message translates to:
  /// **'Montant en FCFA'**
  String get fieldAmountOther;

  /// No description provided for @amountPerMonth.
  ///
  /// In fr, this message translates to:
  /// **'par mois'**
  String get amountPerMonth;

  /// No description provided for @amountOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre montant'**
  String get amountOther;

  /// No description provided for @errRequired.
  ///
  /// In fr, this message translates to:
  /// **'Champ obligatoire.'**
  String get errRequired;

  /// No description provided for @errTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 2 caractères.'**
  String get errTooShort;

  /// No description provided for @errPhoneShort.
  ///
  /// In fr, this message translates to:
  /// **'Numéro incomplet.'**
  String get errPhoneShort;

  /// No description provided for @errPhoneLong.
  ///
  /// In fr, this message translates to:
  /// **'Numéro trop long.'**
  String get errPhoneLong;

  /// No description provided for @errPhoneSenegal.
  ///
  /// In fr, this message translates to:
  /// **'Numéro sénégalais invalide : 9 chiffres commençant par 70, 75, 76, 77 ou 78.'**
  String get errPhoneSenegal;

  /// No description provided for @errEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide.'**
  String get errEmail;

  /// No description provided for @errAmountMin.
  ///
  /// In fr, this message translates to:
  /// **'Montant minimum : {amount}.'**
  String errAmountMin(String amount);

  /// No description provided for @errAmountMissing.
  ///
  /// In fr, this message translates to:
  /// **'Précisez le montant.'**
  String get errAmountMissing;

  /// No description provided for @errServerInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Certaines informations sont refusées. Vérifiez le formulaire.'**
  String get errServerInvalid;

  /// No description provided for @donateIdentityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos coordonnées'**
  String get donateIdentityTitle;

  /// No description provided for @donateIdentitySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Optionnel si vous restez anonyme'**
  String get donateIdentitySubtitle;

  /// No description provided for @donateAnonymous.
  ///
  /// In fr, this message translates to:
  /// **'Je souhaite rester anonyme'**
  String get donateAnonymous;

  /// No description provided for @donateMemberNote.
  ///
  /// In fr, this message translates to:
  /// **'Si vous indiquez votre téléphone, une fiche de membre (sans cotisation mensuelle) peut être créée à partir de votre don.'**
  String get donateMemberNote;

  /// No description provided for @donateAmountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get donateAmountTitle;

  /// No description provided for @donateCampaign.
  ///
  /// In fr, this message translates to:
  /// **'Destination'**
  String get donateCampaign;

  /// No description provided for @campaignGeneral.
  ///
  /// In fr, this message translates to:
  /// **'Soutien général'**
  String get campaignGeneral;

  /// No description provided for @campaignTouba.
  ///
  /// In fr, this message translates to:
  /// **'Projets à Touba'**
  String get campaignTouba;

  /// No description provided for @campaignMagal.
  ///
  /// In fr, this message translates to:
  /// **'Magal / grands événements'**
  String get campaignMagal;

  /// No description provided for @campaignEducation.
  ///
  /// In fr, this message translates to:
  /// **'Éducation & compétences'**
  String get campaignEducation;

  /// No description provided for @campaignOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get campaignOther;

  /// No description provided for @donateMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message (optionnel)'**
  String get donateMessage;

  /// No description provided for @donateMessageHint.
  ///
  /// In fr, this message translates to:
  /// **'Une intention, une dédicace, ou un mot pour l\'équipe.'**
  String get donateMessageHint;

  /// No description provided for @donateSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Continuer vers le paiement'**
  String get donateSubmit;

  /// No description provided for @donateNotYetPaidBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre contribution sera enregistrée uniquement quand le paiement sera confirmé.'**
  String get donateNotYetPaidBody;

  /// No description provided for @donateDoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Merci pour votre soutien'**
  String get donateDoneTitle;

  /// No description provided for @donateDoneBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre contribution de {amount} est confirmée.'**
  String donateDoneBody(String amount);

  /// No description provided for @donateEditInfo.
  ///
  /// In fr, this message translates to:
  /// **'Modifier ma contribution'**
  String get donateEditInfo;

  /// No description provided for @publicTimeoutBody.
  ///
  /// In fr, this message translates to:
  /// **'Si vous avez payé, la confirmation peut prendre quelques minutes. Rien n\'est enregistré tant qu\'elle n\'est pas reçue.'**
  String get publicTimeoutBody;

  /// No description provided for @waveManualTitle.
  ///
  /// In fr, this message translates to:
  /// **'Adhésion enregistrée, paiement à faire'**
  String get waveManualTitle;

  /// No description provided for @waveManualBody.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement en ligne est indisponible. Envoyez {amount} par Wave au {number} en indiquant la référence {reference}.'**
  String waveManualBody(String amount, String number, String reference);

  /// No description provided for @waveManualNotPaid.
  ///
  /// In fr, this message translates to:
  /// **'Votre paiement n\'est pas encore reçu : cette adhésion n\'est pas payée.'**
  String get waveManualNotPaid;

  /// No description provided for @homeJoin.
  ///
  /// In fr, this message translates to:
  /// **'Adhérer'**
  String get homeJoin;

  /// No description provided for @homeContribute.
  ///
  /// In fr, this message translates to:
  /// **'Faire un don'**
  String get homeContribute;

  /// No description provided for @officialPageError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’ouvrir ce lien. Réessayez.'**
  String get officialPageError;

  /// No description provided for @mediaOpen.
  ///
  /// In fr, this message translates to:
  /// **'Voir la médiathèque'**
  String get mediaOpen;

  /// No description provided for @shopOpenWeb.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir la boutique'**
  String get shopOpenWeb;

  /// No description provided for @shopWebCheckout.
  ///
  /// In fr, this message translates to:
  /// **'Consultez les options, le panier et la livraison dans la boutique officielle.'**
  String get shopWebCheckout;

  /// No description provided for @accountAccessHeading.
  ///
  /// In fr, this message translates to:
  /// **'Accès au compte'**
  String get accountAccessHeading;

  /// No description provided for @accountWebHint.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous à votre espace membre sur le site pour gérer votre code PIN.'**
  String get accountWebHint;

  /// No description provided for @accountOpenWeb.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir mon espace sur le site'**
  String get accountOpenWeb;

  /// No description provided for @accountForgotPin.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN oublié ?'**
  String get accountForgotPin;

  /// No description provided for @accountRecoveryHint.
  ///
  /// In fr, this message translates to:
  /// **'Contactez l’équipe Ahloul Khidmah si vous ne pouvez plus vous connecter. Gardez votre code PIN confidentiel.'**
  String get accountRecoveryHint;

  /// No description provided for @accountContactSupport.
  ///
  /// In fr, this message translates to:
  /// **'Contacter l’équipe sur WhatsApp'**
  String get accountContactSupport;

  /// No description provided for @pushUpdateError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de mettre à jour les notifications. Réessayez.'**
  String get pushUpdateError;

  /// No description provided for @pushSettingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get pushSettingTitle;

  /// No description provided for @pushSettingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir les rappels de cotisation et les annonces de l\'association.'**
  String get pushSettingSubtitle;

  /// No description provided for @pushDenied.
  ///
  /// In fr, this message translates to:
  /// **'Notifications refusées. Activez-les dans les réglages du téléphone.'**
  String get pushDenied;

  /// No description provided for @pushOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get pushOpen;

  /// No description provided for @cardMobileUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'La carte n’est pas disponible dans l’application pour le moment. Consulte ton espace membre sur le site.'**
  String get cardMobileUnavailable;

  /// No description provided for @payMobileUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement des cotisations n’est pas disponible dans l’application pour le moment. Ouvre ton espace membre sur le site pour continuer.'**
  String get payMobileUnavailable;

  /// No description provided for @historyOpenWeb.
  ///
  /// In fr, this message translates to:
  /// **'Voir l’historique complet sur le site'**
  String get historyOpenWeb;

  /// No description provided for @onboardingMission.
  ///
  /// In fr, this message translates to:
  /// **'Ensemble, servons la Mouridiyah'**
  String get onboardingMission;

  /// No description provided for @onboardingMissionBody.
  ///
  /// In fr, this message translates to:
  /// **'Ahloul Khidmah rassemble les compétences et les talents au service de Touba.'**
  String get onboardingMissionBody;

  /// No description provided for @onboardingCommunity.
  ///
  /// In fr, this message translates to:
  /// **'Une communauté engagée'**
  String get onboardingCommunity;

  /// No description provided for @onboardingCommunityBody.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez une cellule locale ou soutenez les actions de la communauté par un don.'**
  String get onboardingCommunityBody;

  /// No description provided for @onboardingServices.
  ///
  /// In fr, this message translates to:
  /// **'Votre espace membre'**
  String get onboardingServices;

  /// No description provided for @onboardingServicesBody.
  ///
  /// In fr, this message translates to:
  /// **'Retrouvez votre carte membre, suivez vos cotisations et découvrez Barkelu.'**
  String get onboardingServicesBody;

  /// No description provided for @onboardingStep.
  ///
  /// In fr, this message translates to:
  /// **'Étape {current} sur {total}'**
  String onboardingStep(int current, int total);

  /// No description provided for @onboardingStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onboardingStart;

  /// No description provided for @onboardingNext.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get onboardingNext;

  /// No description provided for @onboardingBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get onboardingBack;

  /// No description provided for @onboardingSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get onboardingSkip;

  /// No description provided for @galleryOpen.
  ///
  /// In fr, this message translates to:
  /// **'Explorer les photos'**
  String get galleryOpen;

  /// No description provided for @galleryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Images du khidma'**
  String get galleryTitle;

  /// No description provided for @galleryPhoto0.
  ///
  /// In fr, this message translates to:
  /// **'Grande Mosquée de Touba — vue drone'**
  String get galleryPhoto0;

  /// No description provided for @galleryPhoto1.
  ///
  /// In fr, this message translates to:
  /// **'Touba — vue aérienne'**
  String get galleryPhoto1;

  /// No description provided for @galleryPhoto2.
  ///
  /// In fr, this message translates to:
  /// **'Communauté et service à Touba'**
  String get galleryPhoto2;

  /// No description provided for @galleryPhoto3.
  ///
  /// In fr, this message translates to:
  /// **'Scène communautaire Ahloul Khidmah'**
  String get galleryPhoto3;

  /// No description provided for @galleryPhoto4.
  ///
  /// In fr, this message translates to:
  /// **'Engagement et khidma'**
  String get galleryPhoto4;

  /// No description provided for @galleryPhoto5.
  ///
  /// In fr, this message translates to:
  /// **'Culture mouride'**
  String get galleryPhoto5;

  /// No description provided for @galleryPhoto6.
  ///
  /// In fr, this message translates to:
  /// **'Héritage de Cheikh Ahmadou Bamba'**
  String get galleryPhoto6;

  /// No description provided for @cardFullScreen.
  ///
  /// In fr, this message translates to:
  /// **'Agrandir la carte'**
  String get cardFullScreen;

  /// No description provided for @shopSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un produit'**
  String get shopSearch;

  /// No description provided for @shopNoMatches.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit ne correspond à cette recherche.'**
  String get shopNoMatches;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
