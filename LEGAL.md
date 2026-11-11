# Mentions légales et originalité

*Valbrume* est une œuvre originale. Aucun fichier externe n'y est inclus.

## Origine de chaque catégorie d'asset
| Catégorie | Source (script qui la génère) |
|---|---|
| Palette de 43 couleurs | `tools/palette.py` |
| Police bitmap « Valbrume Pixel » (ASCII + accents français) | `tools/gen_font.py` |
| Tuiles de terrain (herbe ×4 saisons, terre, sable, chemins, pavés, bois, falaises, sols de mine ×3, intérieurs, eau animée) | `tools/gen_tiles.py` |
| Joueur (3 tenues), 10 PNJ, 30 portraits | `tools/gen_chars.py` |
| Animaux, chien, 6 monstres | `tools/gen_creatures.py` |
| 24 cultures × 6 stades, arbres des 4 saisons, arbres fruitiers | `tools/gen_crops.py` |
| 259 icônes d'objets | `tools/gen_icons.py` (+ `tools/content/items.py`, `registry.py`) |
| Décors, bâtiments, mobilier, objets du monde | `tools/gen_objects.py` |
| Interface (9-slice, boutons, HUD, tactile, particules, logo, fond du titre, lumière) | `tools/gen_ui.py` |
| Icônes d'application (1024, .ico, .icns, adaptatives Android) | `tools/gen_app_icons.py` |
| 61 effets sonores et 9 musiques originales | `tools/gen_audio.py` (synthèse numpy) |
| Cartes | `tools/gen_maps.py`, `tools/gen_maps_world.py`, `tools/mapkit.py`, mine : `scripts/systems/mine_gen.gd` |
| Textes, noms, dialogues, événements | `tools/content/*.py` (écrits pour ce projet) |

Tout est déterministe (graine fixe) : `python tools/build_assets.py --verify` régénère et compare les empreintes SHA-256.

## Outils et licences
| Outil | Usage | Licence |
|---|---|---|
| Godot Engine 4.7 | moteur et export (runtime) | MIT |
| Python 3, Pillow, numpy | génération des assets uniquement (jamais au runtime) | PSF, HPND (MIT-CMU), BSD-3-Clause |

Aucune dépendance runtime sous licence restrictive.

## Checklist d'originalité
- [x] Aucun asset externe (images, sons, musiques, polices, modèles).
- [x] Aucune copie d'un autre jeu : noms, personnages, dialogues, carte, interface, musique, code sont originaux.
- [x] Mécaniques de genre (planter, arroser, saisons, relations, mine, pêche) implémentées à notre façon : mini-jeu de pêche « Ondes » (anneau, bille, arc), cloches du Carillon, grignotins, festivals et jeux propres.
- [x] Le nom d'un jeu existant ou de ses personnages n'apparaît ni dans le jeu, ni dans le code, ni dans les assets, ni dans les métadonnées de build (vérifié par recherche dans le dépôt).
- [x] Aucune dépendance runtime restrictive.
- [x] Métadonnées de build sans nom de tiers (société « Valbrume », package `com.yourname.valbrume` à personnaliser).
