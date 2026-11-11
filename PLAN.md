# PLAN — Valbrume

Jeu de ferme / vie de village 2D, 100 % original, Godot 4.7 (GDScript typé), assets générés par scripts Python.

Légende : `[ ]` à faire · `[x]` fait et validé.

## Environnement constaté (2026-11-11)

| Outil | État |
|---|---|
| Godot | 4.7.2 stable — `/Applications/Godot.app/Contents/MacOS/Godot` (pas dans le PATH) |
| Python | 3.9 + venv local `.venv` (Pillow 11.3, numpy 2.0) |
| git | 2.54 |
| Export templates Godot | **absents** |
| JDK | **absent** |
| SDK Android | **absent** |
| ffmpeg / oggenc | absents → audio livré en WAV (compression QOA à l'import Godot) |

## Décisions structurantes

- **Source de vérité du contenu** : tables Python dans `tools/content/` → `tools/build_data.py` écrit `data/*.json` et `i18n/strings.csv`. Ajouter une culture = ajouter une ligne dans une table, aucun code de jeu.
- **Cartes** : générées de façon déterministe par `tools/gen_maps.py` → `data/maps/*.json` (terrain, décors, passages, points d'intérêt). Godot les peint à l'exécution.
- **Collisions** : grille maison (pas de moteur physique) → déterministe, testable en headless, léger sur mobile.
- **État du jeu** : dictionnaires JSON-sérialisables dans `GameState` ; les systèmes sont de la logique pure, les scènes ne font qu'afficher.
- **Scènes** : `.tscn` minimales (nœud racine + script), l'arbre est construit en code.

## Phases

### P0 — Setup
- [ ] `project.godot` (480×270, canvas_items + expand, entier, Nearest, snap pixels, Compatibility)
- [ ] dépôt git, arborescence, `.gitignore`
- [ ] autoloads : EventBus, Settings, Database, GameState, TimeManager, SaveManager, AudioManager, InputManager
- [ ] `tools/palette.py` (43 couleurs), `tools/gen_font.py` (police bitmap ASCII + accents FR)
- [ ] runner de tests headless

**Validation** : le projet s'importe et démarre en headless sans erreur ni avertissement ; la police s'affiche ; tests de base verts.

### P1 — Pipeline d'assets
- [ ] `tools/build_assets.py` déterministe (graine fixe)
- [ ] tilesets, joueur, PNJ + portraits, animaux, monstres, cultures, icônes, décor, UI, icônes d'app, effets
- [ ] `tools/gen_audio.py` (≥ 30 SFX, 9 musiques)
- [ ] `tools/contact_sheet.py` + inspection visuelle et corrections

**Validation** : deux exécutions donnent des fichiers identiques (hash) ; planches relues ; contrôle de palette automatique vert.

### P2 — Première boucle jouable
- [ ] joueur (8 directions, collisions, action contextuelle), carte de la ferme
- [ ] temps, énergie, outils de base, agriculture, coffre d'expédition, sommeil + bilan, sauvegarde

**Validation** : labourer → semer → arroser → dormir → récolter → vendre fonctionne ; aller-retour de sauvegarde testé.

### P3 — Village
- [ ] cartes village / forêt / lac / côte + intérieurs
- [ ] 10 PNJ, emplois du temps, pathfinding, dialogues, amitié, cadeaux, événements
- [ ] 5 commerces avec horaires et stocks saisonniers

**Validation** : tests amitié + emplois du temps ; chaque boutique achète et vend.

### P4 — Élevage et artisanat
- [ ] bâtiments (poulailler, étable, silo, serre), animaux, affection, production
- [ ] machines, artisanat (≥ 40 recettes), cuisine (≥ 25 plats, buffs)
- [ ] maison (3 niveaux), meubles plaçables et rotatifs, papiers peints et sols

**Validation** : tests production animale, machines, recettes.

### P5 — Mine, combat, pêche
- [ ] mine 60 étages procéduraux, 3 biomes, ascenseur, coffres
- [ ] combat temps réel, 6 monstres, butin, défaite
- [ ] fourneau, amélioration d'outils, mini-jeu de pêche original, ≥ 20 poissons, casiers

**Validation** : génération de mine reproductible par graine ; tables de pêche testées.

### P6 — Monde vivant
- [ ] météo + prévision, saisons complètes, cycle jour/nuit
- [ ] 4 festivals avec mini-jeu, quêtes quotidiennes, collections, fil rouge (6 cloches)

**Validation** : simulation d'une année complète en headless sans erreur.

### P7 — Finitions
- [ ] audio branché, particules, transitions, « juice »
- [ ] UI tactile (joystick, boutons, zones sûres), manette, remappage
- [ ] i18n FR / EN complet + `tools/check_i18n.py`

**Validation** : `check_i18n.py` vert ; aucun texte en dur.

### P8 — Livraison
- [ ] `tools/balance_sim.py` + équilibrage chiffré dans le GDD
- [ ] tests complets, mode debug F3, performances
- [ ] `export_presets.cfg`, `build.sh`, `build.ps1`
- [ ] README, LEGAL, CREDITS, CHANGELOG, docs/GDD, ARCHITECTURE, PLAY_STORE

**Validation** : suite de tests verte ; exports générés ou prérequis manquants listés précisément.

## Journal de reprise

_(mis à jour à chaque fin de phase : où on en est, quoi faire ensuite)_

- 2026-11-11 — P0 démarrée.
