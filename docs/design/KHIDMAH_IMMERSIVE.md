# Khidmah Immersive

L’application démarre sur le logo officiel et présente Ahloul Khidmah avec les photographies de Touba publiées par le site. L’accueil garde un accès direct à l’adhésion, au don et à la connexion pour les visiteurs. Les membres voient leur salutation, le statut de leur cotisation et les raccourcis activés par la configuration distante.

## Charte

La charte web au commit `80d3686` utilise l’émeraude `#0B3A25` et `#12512F`, l’or `#C9A24C`, l’ivoire `#FBF6EA` et l’encre `#20241C`. La déclinaison mobile adopte `#064C3B` pour les surfaces de marque, `#087A58` pour l’action, `#D6A84D` pour l’accent, `#F8F6F0` pour le fond clair, `#FFFFFF` pour les surfaces relevées et `#172620` pour le texte. Le thème sombre utilise des surfaces vert charbon et une action vert clair. [Feuille de style officielle](https://github.com/gueyeprosn/Ahloul-Khidmah/blob/80d368603842f6bc7677e08e1c458a7846f7a7e9/src/app/globals.css)

Amiri et Cairo sont conservées pour faire correspondre les titres et l’interface FR/AR au site. Les fichiers TTF et leurs licences OFL sont inclus dans le bundle. Le système Flutter applique le sens de lecture arabe, avec les numéros de téléphone et les champs PIN en gauche à droite.

- `AkTheme` et `buildAkTheme` définissent les thèmes dans `lib/app/theme/ak_theme.dart`.
- `AKColors`, `AkPalette` et `AkText` définissent les couleurs de marque, les rôles sémantiques et la typographie.
- `AkSpace`, `AkRadius`, `AkSize` et `AkLayout` définissent les espacements, rayons, surfaces tactiles et largeurs d’interface. Le pas principal est de 4 dp. Les boutons visent au minimum 48 × 48 dp. Les grands en-têtes changent de marge à 360 dp de largeur disponible. La découverte est plafonnée à 600 dp et l’accueil ou la galerie à 720 dp.
- Les cartes emploient un filet et des surfaces distinctes, avec une élévation nulle. Les jetons de couleur portent les opacités utiles aux états et aux fonds.
- `AKMotion` définit la pression à 97 % sur 120 ms. Les routes secondaires utilisent un fondu et un déplacement vertical sur 260 ms à l’entrée et 180 ms au retour. Les révélations et les feuilles modales cessent leurs transitions si le système demande une réduction du mouvement.

## Composants

| Composant | Usage |
| --- | --- |
| `AkButton`, `AkPrimaryButton`, `AkSecondaryButton`, `AkIconButton` | Actions, variantes primaire/or/contour/texte, pression Material et états désactivé ou en cours. Passer `loading` et une action déjà protégée contre les doubles envois côté contrôleur. |
| `AkAnimatedButton`, `AkReveal`, `AkPageTransition`, `showAkBottomSheet` | Mouvement partagé dans `lib/core/animations/ak_motion.dart`. |
| `AkImmersiveHeader`, `AkBottomNavigation`, `AkServiceTile` | En-tête photo, onglets pilotés par la configuration distante et accès rapides. |
| `AkMembershipCard`, `AkImageViewer` | Badge issu du serveur, visionneuse et zoom. Réutilise l’image en mémoire et le ratio officiel 2:3. Le partage demande toujours le fichier officiel au format PNG. |
| `AkContributionCard`, `AkStatusBadge` | Situation du mois courant et états identifiés par texte et icône. Les contrôleurs de paiement déterminent le succès à partir du serveur. |
| `AkNewsCard`, `AkProductCard` | Contenu photo officiel et produits du catalogue public. |
| `AkAnimatedProgress`, `AkLoadingSkeleton`, `AkEmptyState`, `AkErrorState` | Progression mesurée, attente, absence de contenu et erreur. Les cotisations affichent les périodes et statuts disponibles. |

Le catalogue de développement s’ouvre via **Khidmah Immersive** en bas de l’accueil d’un build debug. Il permet de vérifier la palette active, les boutons, les feuilles modales, le squelette et les messages d’état. Les écrans de test et le catalogue utilisent les mêmes composants que l’application.

## Contrats et parcours

- La configuration distante, la version minimale et la maintenance sont évaluées avant la découverte. Le bouton **Passer** et la fin du parcours enregistrent le choix localement. Une session membre restaurée mène directement à l’espace disponible.
- La connexion, le premier PIN, les dons, l’adhésion et les cotisations utilisent les contrôleurs de la copie Flutter fournie. Le stockage de session, les règles de paiement et les contrôles de confirmation côté serveur restent ceux de cette copie.
- Barkelu interroge les routes publiques du catalogue, des catégories et de la fiche produit. La fiche officielle sur le site prend le relais pour la sélection d’une variante, le panier, le paiement et le suivi de commande.
- La galerie embarque les sept photographies publiées dans le carrousel du site et propose l’accès à la médiathèque web pour les publications actualisées.
- Mon compte affiche la photo lorsqu’elle est fournie par l’API du site, les initiales sinon, ainsi que le numéro de membre et le téléphone lorsqu’ils sont disponibles. Il donne accès à la carte et aux destinations officielles pour l’historique, l’assistance et la gestion du compte.

## Vérifications à compléter sur environnement cible

- Valider les performances sur un Android physique de milieu de gamme et la présentation native iOS.
- Rejouer les intégrations de carte, notifications et paiement sur un staging configuré avec des comptes de test.
- Exposer un contrat mobile public pour actualités, événements et albums dynamiques avant leur intégration native.
- Documenter les contrats de commandes membres, d’historique de contributions et de suppression de compte avant d’ajouter des actions natives correspondantes.

Voir [l’inventaire des assets et licences](ASSET_INVENTORY.md) et le [rapport de vérification](VERIFICATIONS.md).
