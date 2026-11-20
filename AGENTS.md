# AGENTS.md — Directives d’ingénierie Flutter

Ces directives s’appliquent à l’application Android et iOS Ahloul Khidmah Mobile dans `app-adhesion-dons`.

## 1. Vue d’ensemble du projet et stack

- **Flutter et Dart** — vérifier le SDK actif avec `flutter --version`. Le SDK local relevé est Flutter 3.44.4 avec Dart 3.14.0. Consulter `pubspec.yaml` pour les contraintes déclarées et `pubspec.lock` pour les versions résolues et les minimums exigés par les dépendances.
- **Gestion d’état** — utiliser les providers et contrôleurs Riverpod existants.
- **Navigation** — utiliser GoRouter. Préserver les redirections d’authentification, les onglets pilotés par la configuration distante et les écrans de repli.
- **Sérialisation** — suivre les modèles Dart existants et leurs fabriques `fromJson`. Pour les traductions, éditer les fichiers ARB, puis lancer `flutter gen-l10n`.
- **Réseau et stockage** — réutiliser les clients Dio de `lib/core/api/`. Stocker les jetons avec `flutter_secure_storage` et les préférences non sensibles avec `shared_preferences`. Le serveur fait foi pour les données métier et la confirmation des paiements.

## 2. Architecture et organisation des dossiers

Organiser le code par fonctionnalité. Dans un module existant, suivre la structure locale. Quand un module grandit, introduire les dossiers `data/`, `domain/` et `presentation/` selon ses besoins.

```text
lib/
├── main.dart             # Initialisation et point d’entrée Flutter
├── app/                  # Application, thème et routeur
├── core/                 # API, authentification, configuration, erreurs et stockage partagés
├── features/
│   └── <fonctionnalité>/
│       ├── data/         # DTO, sources et implémentations de repositories
│       ├── domain/       # Modèles métier, contrats et cas d’usage
│       └── presentation/ # Contrôleurs Riverpod, écrans et widgets dédiés
├── shared/widgets/       # Composants d’interface réutilisés entre fonctionnalités
└── l10n/                 # Sources ARB FR et AR et fichiers générés
```

Garder les appels HTTP et le décodage JSON dans la couche de données. Les écrans lisent les états via Riverpod et délèguent les actions aux contrôleurs.

## 3. Vérification des changements

- Exécuter `flutter analyze` et `flutter test` depuis le dossier de l’application.
- Utiliser des réponses simulées ou un serveur de test pour les parcours de paiement.
- Pour une modification d’interface, vérifier le français, l’arabe RTL, les thèmes clair et sombre et le texte jusqu’à 200 %. Réutiliser les composants de la charte dans `lib/shared/widgets/`.
