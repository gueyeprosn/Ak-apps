# Vérifications et performance

Exécution le 20 novembre 2026 avec Flutter 3.44.4 et Dart 3.14.0.

## Tests Flutter

- `flutter analyze --no-pub --no-fatal-infos` termine avec zéro erreur et zéro avertissement. Le SDK installé émet des diagnostics informatifs pour la migration Material et quelques règles de style existantes.
- `flutter test --no-pub` exécute 188 tests avec succès. Les 24 scénarios d’intégration qui exigent un serveur ou des identifiants de staging sont ignorés par le projet.
- Les nouveaux tests couvrent la découverte et sa persistance, le choix de langue, le mode sombre arabe en paysage avec texte à 200 % et mouvement réduit, la galerie puis le retour depuis la visionneuse, les filtres et variantes Barkelu et l’échelle des boutons pendant la pression.
- Le générateur de visuels exécute 41 scénarios avec le rendu Flutter et des fixtures locales. Il couvre notamment le premier accès, le PIN, le badge, un cache hors ligne, les contributions et la cotisation en attente, confirmée ou échouée. La comparaison sans régénération a aussi réussi pour les 13 écrans principaux. Les captures sont dans [docs/captures-immersive/widgets](../../../docs/captures-immersive/widgets).

## Coût du rendu et accessibilité

Les neuf photographies embarquées occupent 1,74 Mo sur disque. Le hero de Touba passe de 1 092 504 à 487 950 octets via un redimensionnement proportionnel et l’encodage WebP, soit 55 % de moins. Sa largeur est de 1 440 px et sa hauteur de 959 px. Au maximum, un rendu RGBA de la photo représente environ 5,3 Mio avant les surcoûts du cache et du GPU. Le décodage est demandé à la largeur physique du composant, avec un plafond de 1 440 px. La liste de la galerie crée ses éléments à la demande. La visionneuse du badge conserve le fichier reçu et sa résolution.

Les animations principales sont finies et portent sur l’opacité, l’échelle et la translation. Les squelettes de chargement sont statiques. Le réglage de mouvement réduit coupe les animations d’entrée, de pression, d’onglet et de feuille modale de la charte. Les formulaires continuent d’exposer leur état de chargement.

| Paire de couleurs | Rapport mesuré |
| --- | --- |
| Ivoire sur vert d’action | 4,94:1 |
| Ivoire sur vert profond | 9,23:1 |
| Vert profond sur or | 4,55:1 |
| Charbon sur ivoire | 14,56:1 |
| Texte sombre principal sur fond sombre | 16,10:1 |
| Texte sombre secondaire sur surface relevée sombre | 8,37:1 |

Le texte de l’en-tête commence sur une surface de couleur unie, après le dégradé photo. Le texte et le statut de la carte membre gardent leurs libellés à côté des couleurs et icônes. Le dimensionnement des cibles suit les composants Material et le token de 48 dp.

## Android

L’APK ARM64 profile a été compilé avec Gradle et Temurin 17, installé sur l’émulateur Medium Phone Android 17, API 37, 1 080 × 2 400. Le démarrage, le changement de langue, l’accueil, la connexion, la galerie et Barkelu ont été parcourus. Les huit [captures natives Android](../../../docs/captures-immersive/android) proviennent de cet émulateur.

Trois démarrages à froid via `am start -W -S` avec les données d’application conservées ont été mesurés à 1 625, 1 808 et 1 817 ms. La médiane est de 1 808 ms. Le relevé `dumpsys meminfo` sur Barkelu après le passage par la galerie indique 152 322 Kio de PSS et 294 920 Kio de RSS.

La trace VM Service de l’enchaînement accueil, galerie, ouverture d’une photo, retour et défilement contient 50 trames Flutter. La durée du travail UI médiane est de 1,03 ms et son p95 de 15,13 ms. Le p95 de `GPURasterizer::Draw` atteint 101,91 ms avec Impeller OpenGLES et le GPU logiciel SwiftShader de l’émulateur. Le budget de 16,67 ms est dépassé par 42 des 50 trames de cette mesure raster. Une campagne sur Android physique reste nécessaire pour valider l’objectif de 60 images/s.

La compilation de l’APK dans cet environnement a abouti via le Gradle Wrapper avec Temurin 17. Les scripts de build ont aussi signalé la future migration de dépendances Flutter vers Kotlin intégré.

## iOS

Le projet contient l’icône de l’application et le storyboard de lancement actualisés à partir du logo officiel. Le storyboard et le catalogue des ressources ont été vérifiés structurellement. Le système dispose des Command Line Tools, sans le simulateur `simctl`. La compilation native iOS, les captures iOS et le profilage sur iPhone restent à valider avec Xcode.

## Reproduire les tests

```sh
flutter pub get
flutter analyze --no-pub --no-fatal-infos
flutter test --no-pub
FLUTTER_ROOT=/chemin/vers/flutter flutter test --no-pub --update-goldens tool/screenshots
```

`AK_SCREENSHOT_DIR` permet de choisir le dossier des PNG. Lancer les parcours de paiement sur des fixtures ou sur un environnement de test configuré.
