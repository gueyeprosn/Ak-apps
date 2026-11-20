# Inventaire des assets Khidmah Immersive

Audit du 20 novembre 2026. Sources comparées : copie Flutter fournie, dépôt Next.js au commit `80d3686` et [accueil officiel](https://www.ahloulkhidmah.org/). Les fichiers du carrousel public et le hero ont été retrouvés sur le site et dans le dépôt. Le logo web publié correspond au master du dépôt. La variante Flutter est un fichier distinct.

## Ressources du site

| Chemin source | Format | Dimensions source (px) | Fonction | Chemin Flutter et dimensions (px) | Statut |
| --- | --- | --- | --- | --- | --- |
| `public/brand/carte-membre-model.png` | PNG | 1024 × 1536 | Gabarit ou aperçu du badge officiel | — | Serveur uniquement, PNG membre authentifié 1024 × 1536 |
| `public/brand/carte-membre-preview.png` | PNG | 1024 × 1536 | Gabarit ou aperçu du badge officiel | — | Serveur uniquement, PNG membre authentifié 1024 × 1536 |
| `public/brand/cheikh-ahmadou-bamba.jpg` | JPG | 640 × 800 | Réserve de la charte web | — | Disponible côté site |
| `public/brand/dieuwrigne-mbackiyou-faye.jpg` | JPG | 391 × 511 | Réserve de la charte web | — | Disponible côté site |
| `public/brand/fonts/OFL.txt` | TXT | — | Playfair Display et licence du badge | — | Serveur uniquement |
| `public/brand/fonts/PlayfairDisplay-Italic.ttf` | TTF | — | Playfair Display et licence du badge | — | Serveur uniquement |
| `public/brand/fonts/PlayfairDisplay.ttf` | TTF | — | Playfair Display et licence du badge | — | Serveur uniquement |
| `public/brand/khalife-mountakha.jpg` | JPG | 1200 × 1801 | Réserve de la charte web | — | Disponible côté site |
| `public/brand/logo.png` | PNG | 580 × 583 | Logo officiel du site, master couleur | `assets/images/logo.png` (318 × 320) | Variante mobile existante conservée |
| `public/brand/og-share-source.jpg` | JPG | 5262 × 3505 | Réserve de la charte web | — | Disponible côté site |
| `public/brand/og-share.jpg` | JPG | 1200 × 630 | Réserve de la charte web | — | Disponible côté site |
| `public/brand/payments/nav-logo- wave.png` | PNG | 400 × 400 | Identité des moyens de paiement | — | Variantes PNG mobiles existantes |
| `public/brand/payments/nav-logo-OM.png` | PNG | 512 × 512 | Identité des moyens de paiement | — | Variantes PNG mobiles existantes |
| `public/brand/payments/orange-money.png` | PNG | 512 × 512 | Identité des moyens de paiement | — | Variantes PNG mobiles existantes |
| `public/brand/payments/orange-money.svg` | SVG | — | Identité des moyens de paiement | — | Variantes PNG mobiles existantes |
| `public/brand/payments/wave.png` | PNG | 400 × 400 | Identité des moyens de paiement | — | Variantes PNG mobiles existantes |
| `public/brand/payments/wave.svg` | SVG | — | Identité des moyens de paiement | — | Variantes PNG mobiles existantes |
| `public/brand/slides/23022025-dji_20250223025244_0011_d.jpg` | JPG | 1600 × 900 | Réserve de la charte web | — | Disponible côté site |
| `public/brand/slides/342352396_534673642195408_18788620982124.jpg` | JPG | 1600 × 1089 | Galerie et visionneuse | `assets/images/official/communaute.webp` (1280 × 871) | Intégré, dérivé sans recadrage |
| `public/brand/slides/culture_mouride_1742743763336.jpg` | JPG | 1080 × 1179 | Galerie et visionneuse | `assets/images/official/culture-mouride.webp` (1080 × 1179) | Intégré, dérivé sans recadrage |
| `public/brand/slides/drone-touba-1.jpg` | JPG | 1600 × 1065 | Galerie et visionneuse | `assets/images/official/touba-drone.webp` (1280 × 852) | Intégré, dérivé sans recadrage |
| `public/brand/slides/drone-touba-2.jpg` | JPG | 1600 × 900 | Galerie et visionneuse | `assets/images/official/touba-aerien.webp` (1280 × 720) | Intégré, dérivé sans recadrage |
| `public/brand/slides/efaytfvx4ae4ect.jpg` | JPG | 1090 × 816 | Galerie et visionneuse | `assets/images/official/scene-communautaire.webp` (1090 × 816) | Intégré, dérivé sans recadrage |
| `public/brand/slides/gdv7h2nwgaeyljh.jpg` | JPG | 885 × 960 | Galerie et visionneuse | `assets/images/official/engagement.webp` (885 × 960) | Intégré, dérivé sans recadrage |
| `public/brand/slides/jad20230424-culture-ass-cheikh-ahmadou-b.jpg` | JPG | 1256 × 628 | Galerie et visionneuse | `assets/images/official/heritage.webp` (1256 × 628) | Intégré, dérivé sans recadrage |
| `public/brand/touba-hero.jpg` | JPG | 2400 × 1598 | En-tête accueil et découverte de la mission | `assets/images/official/touba-hero.webp` (1440 × 959) | Intégré, dérivé sans recadrage |
| `public/brand/touba-og.jpg` | JPG | 1200 × 630 | Réserve de la charte web | — | Disponible côté site |
| `public/brand/touba-vision.jpg` | JPG | 2000 × 1125 | Dernière étape de découverte | `assets/images/official/touba-vision.webp` (1280 × 720) | Intégré, dérivé sans recadrage |
| `public/brand/wave-logo.png` | PNG | 230 × 101 | Identité des moyens de paiement | — | Variantes PNG mobiles existantes |

## Ressources natives

- `assets/images/logo.png` · PNG 318 × 320 · variante officielle préexistante, affichée en `contain`. L’audit a identifié des icônes Flutter par défaut et un visuel iOS transparent de 1 × 1 au lancement. Ils ont été remplacés par des dérivés du master officiel web, centré et mis à l’échelle sur un fond #064C3B.
- `android/app/src/main/res/mipmap-*/ic_launcher.png` · PNG 48, 72, 96, 144 et 192 px, carrés · icône Android. `drawable-*/ak_launch_logo.png` · 104 à 416 px selon densité · écran natif Android. `drawable-nodpi/ak_launch_icon.png` · PNG carré de 864 px · Android 12 et plus.
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` · PNG carrés de 20 à 1024 px · icônes iOS dérivées. `LaunchImage.imageset/*.png` · 104, 208 et 312 px · écran de lancement iOS.
- `assets/images/wave.png`, `orange-money.png` · PNG 192 × 192 chacun · logos des moyens proposés par les parcours existants.
- `assets/fonts/Amiri-{Regular,Bold}.ttf` · TTF, dimensions sans objet · titres FR/AR · licence `OFL-Amiri.txt`.
- `assets/fonts/Cairo-{Regular,Medium,SemiBold,Bold}.ttf` · TTF, dimensions sans objet · texte FR/AR · licence `OFL-Cairo.txt`.
- Carte et photo de membre · ressources authentifiées, personnelles et dynamiques. Le visuel du badge et son QR sont restitués à partir du PNG serveur. Les fixtures du dépôt servent aux tests uniquement.

## Utilisation et licences

Les images de marque sont réutilisées sur instruction du propriétaire du projet. Aucun régime public de redistribution pour un autre projet n’a été identifié. Les photos WebP conservent le cadrage et le ratio des originaux à l’arrondi du pixel. En UI, `cover` est réservé aux aperçus et `contain` aux visuels qui doivent rester entiers. Les fichiers OFL doivent accompagner la redistribution d’Amiri et Cairo. Les icônes viennent des ensembles Material et Cupertino déjà déclarés dans Flutter.

## Ressources encore à confirmer

Le diaporama officiel suffit pour les écrans initiaux. Les contenus éditoriaux dynamiques, les vidéos et les mises à jour d’albums nécessitent une source publique documentée. L’application peut ouvrir la médiathèque officielle pour ces contenus. Le catalogue produit récupère ses ressources via l’API existante lorsqu’elles sont renseignées.
