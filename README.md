# Ahloul Khidmah Mobile (Flutter)

Application Android et iOS reliée à la plateforme `www.ahloulkhidmah.org` : une seule source de vérité (le serveur), aucune base métier sur le téléphone.

## Prérequis
Flutter 3.x et SDK Dart.

## Lancer
```bash
flutter pub get
flutter gen-l10n          # régénère lib/l10n/app_localizations*.dart depuis les .arb
flutter run --dart-define=ENV=staging --dart-define=API_BASE_URL=https://staging.ahloulkhidmah.org
```
Variables de compilation (jamais de secret) : `ENV` (`prod` par défaut), `API_BASE_URL` (HTTPS obligatoire hors développement), `STORE_URL` (lien du magasin pour l'écran « mise à jour nécessaire »).

## Vérifier
```bash
flutter analyze
flutter test                                   # tests locaux avec serveurs simulés
flutter test test/integration \                # contre un serveur de TEST à base anonymisée
  --dart-define=STAGING_URL=http://127.0.0.1:3001 \
  --dart-define=STAGING_TEL=+221770000001 --dart-define=STAGING_PIN=1234 \
  --dart-define=STAGING_TEL_NOPIN=+221770000002 --dart-define=STAGING_SUFFIX=633N
flutter test --update-goldens tool/screenshots/screens_test.dart   # captures dans tool/screenshots/out/
```

## Architecture
```
lib/
  app/          application, thème (tokens de la charte), routeur go_router
  core/         api (Dio, renouvellement de jeton), auth, config distante, sécurité, format
  features/     auth, home, cotisations, barkelu, account, shell (onglets), system
  shared/       widgets de la charte (bouton, champs, PIN, pastille, bandeau, états)
  l10n/         app_fr.arb, app_ar.arb (+ code généré)
```
- **Navigation pilotée par le serveur** : la barre d'onglets vient de `GET /api/mobile/v1/config` (libellés FR/AR, drapeaux, `requiresAuth`). Une rubrique inconnue de la version installée mène à un écran de repli.
- **Authentification** : jeton d'accès (15 min) + jeton de renouvellement rotatif dans le stockage sécurisé du système ; un seul renouvellement à la fois ; une panne réseau ne déconnecte jamais.
- **Aucun secret dans l'application**, aucune clé de paiement ; la confirmation d'un paiement vient toujours du serveur.

Polices Cairo et Amiri (licence OFL) embarquées dans `assets/fonts/`.

## Notifications Firebase

Pour un build de test avec notifications, copier `firebase.example.json` vers
`firebase.json` et renseigner les identifiants publics des applications Firebase
associées aux identifiants Android et iOS du projet. Lancer sur un appareil
avec la configuration et l’URL d’une API de staging joignable.
Remplacer l’adresse ci-dessous si le sous-domaine de démonstration ne répond pas.

```bash
flutter run --dart-define-from-file=firebase.json \
  --dart-define=ENV=staging --dart-define=API_BASE_URL=https://staging.ahloulkhidmah.org
```

Sur iOS, activer la capacité Push Notifications pour Runner et utiliser un
profil de signature avec les droits APNs. Configurer APNs dans Firebase.
L’envoi serveur doit cibler le même projet Firebase et l’API de test doit
exposer `POST/DELETE /api/mobile/v1/devices`. Garder les clés de service
Firebase et les clés privées APNs côté serveur ou dans la console appropriée.

Depuis **Mon compte**, activer la bascule pour demander la permission système.
La bascule dépend de la configuration Firebase. Vérifier un envoi de test
au premier plan, en arrière-plan et au démarrage depuis une notification,
puis la révocation après désactivation et déconnexion.
