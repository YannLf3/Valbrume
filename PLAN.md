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
- [x] `project.godot` (480×270, canvas_items + expand, entier, Nearest, snap pixels, Compatibility)
- [x] dépôt git, arborescence, `.gitignore`
- [x] autoloads : EventBus, Settings, Database, GameState, TimeManager, SaveManager, AudioManager, InputManager
- [x] `tools/palette.py` (43 couleurs), `tools/gen_font.py` (police bitmap ASCII + accents FR)
- [x] runner de tests headless

**Validation** : le projet s'importe et démarre en headless sans erreur ni avertissement ; la police s'affiche ; tests de base verts.

### P1 — Pipeline d'assets
- [x] `tools/build_assets.py` déterministe (graine fixe)
- [x] tilesets, joueur, PNJ + portraits, animaux, monstres, cultures, icônes, décor, UI, icônes d'app, effets
- [x] `tools/gen_audio.py` (≥ 30 SFX, 9 musiques)
- [x] `tools/contact_sheet.py` + inspection visuelle et corrections

**Validation** : deux exécutions donnent des fichiers identiques (hash) ; planches relues ; contrôle de palette automatique vert.

### P2 — Première boucle jouable
- [x] joueur (8 directions, collisions, action contextuelle), carte de la ferme
- [x] temps, énergie, outils de base, agriculture, coffre d'expédition, sommeil + bilan, sauvegarde

**Validation** : labourer → semer → arroser → dormir → récolter → vendre fonctionne ; aller-retour de sauvegarde testé.

### P3 — Village
- [x] cartes village / forêt / lac / côte + intérieurs
- [x] 10 PNJ, emplois du temps, pathfinding, dialogues, amitié, cadeaux, événements
- [x] 5 commerces avec horaires et stocks saisonniers

**Validation** : tests amitié + emplois du temps ; chaque boutique achète et vend.

### P4 — Élevage et artisanat
- [x] bâtiments (poulailler, étable, silo, serre), animaux, affection, production
- [x] machines, artisanat (≥ 40 recettes), cuisine (≥ 25 plats, buffs)
- [x] maison (3 niveaux), meubles plaçables et rotatifs, papiers peints et sols

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

- 2026-11-11 — P0 et P1 terminées. Pipeline : `python tools/build_assets.py` (assets) puis `python tools/build_data.py` (données + i18n). 1 829 sprites, 61 SFX, 9 musiques, déterminisme vérifié (`--verify`). Suite : P2 (cartes via `tools/gen_maps.py`, joueur, agriculture).

### Point d'arrêt — 2026-11-11 (P0 et P1, historique)

**Fait et commité** : P0 (socle) et P1 (assets + données). Tests : 9 tests / 46 vérifications verts. Rien d'autre en cours sur disque.

**Prochaine étape : P2, à commencer par `tools/gen_maps.py`** (pas encore écrit). Conception arrêtée :

- Sortie `data/maps/<id>.json` + `data/maps/index.json` ; aperçu PNG dans `assets/contact/map_<id>.png`.
- Format : `{id, w, h, rows[] (symboles de data/terrains.json), outdoor, music, farmable, protected, statics[{s,x,y,w,h,solid,glow,until_flag}], warps[{x,y,to,tx,ty,face,locked}], spots{nom:[x,y]}, interact[{x,y,kind,arg}], spawn[{t,x,y,…}], pads{…}, zones{fish}, style{floor,wall}}`.
- Orientation : 0 bas, 1 haut, 2 droite, 3 gauche (= lignes des feuilles de personnages).
- Sprite d'un static : centré horizontalement sur l'emprise, bas aligné sur le bas de l'emprise ; emprise des bâtiments = largeur × 3 cases, la case de porte (rangée du bas) est un passage.
- Graphe : ferme ⟷ village (est/ouest) · ferme ⟷ forêt (sud/nord) · village ⟷ lac (nord/sud, entrée de mine + alpage verrouillé) · village ⟷ côte (sud/nord, verrouillé jusqu'à la cloche des Ondes).
- Cartes : farm 64×52, village 80×60, forest 56×48, lake 56×44, beach 56×34, intérieurs (farmhouse_1/2/3, store, forge, carpentry, ranch_shop, fishshop, clinic, inn, museum, cottage, coop_in, barn_in, greenhouse_in, mine_hub). Les étages de mine sont générés à l'exécution (GDScript, graine par étage).
- À corriger au passage dans `tools/gen_objects.py` : portes de `coop()` et `greenhouse()` à aligner sur une case (x = 34 et 50), `barn(2)` en 112 px de large.

**Ensuite (P2)** : `scripts/world/map_view.gd` (2 couches de tuiles : terrain inférieur + tuile de masque ; TileSet construit en code avec bits de terrain), joueur à collisions sur grille, `scripts/systems/farming.gd`, outils avec charge, coffre d'expédition, `DayCycle.run_night` complet, HUD, bilan de nuit. Puis P3 → P8 selon le plan ci-dessus.

**Univers décidé** (à écrire dans `docs/GDD.md`) : jeu *Valbrume*, village d'Ormelune, tante Odile fondeuse de cloches ; fil rouge = refondre les 6 cloches du Carillon (Sillons → serre, Ondes → côte, Roche → mine 41-60, Foyer → marché du dimanche, Troupeaux → alpage, Grand Bourdon → final). PNJ : Capucine, Bastien, Isaure, Théodule, Maïwenn, Hyacinthe, Gaspard, Corentin, Roseline, Pim (romances : Capucine, Isaure, Bastien, Corentin). Pêche = mini-jeu de rythme « ondes ». Nuisible = grignotins (épouvantail à grelots). Festivals : jours 14 / 16 / 20 / 22 de chaque saison.

**Commandes utiles**
- Godot : `/Applications/Godot.app/Contents/MacOS/Godot`
- Assets : `.venv/bin/python tools/build_assets.py [--no-audio] [--verify]` · données : `.venv/bin/python tools/build_data.py`
- Tests : `Godot --headless res://tests/test_runner.tscn` · import : `Godot --headless --import`

### Journal — P2 terminée (2026-11-11)

Première boucle jouable : titre → nouvelle partie (3 emplacements) → introduction → ferme. Labour (zones aux niveaux élevés, charge maintenue), semis, arrosage, croissance nocturne, récolte (qualité), cultures à repousse, mort hors saison, pluie, arroseurs, épouvantail, arbres fruitiers, coffre d'expédition (conteneur glisser-déposer), sommeil → bilan → réveil dans le lit, sauvegarde automatique, évanouissement à 2 h.

- Code : `scripts/world/` (MapRuntime, MapView, World, Fx, DayLight), `scripts/entities/player.gd`, `scripts/systems/` (farming, tool_use, world_objects, placement, consumables, skills, recipes, economy, weather, day_cycle, loot, loc), `scripts/ui/` (ui_kit, hud, slot_grid, container/dialog/summary/options/pause/confirm/title).
- Cartes : `tools/gen_maps.py` produit `farm`, `farmhouse_1..3` (+ aperçus `assets/contact/map_*.png`). Les cartes village/forêt/lac/côte/intérieurs arrivent en P3 : les passages vers elles affichent « chemin pas encore praticable ».
- Contrôle visuel : `godot --path . res://tests/shot.tscn -- --out=<dossier>` (et `shot_title.tscn`) lancent une vraie fenêtre et enregistrent des captures.
- Tests : 28 tests, 247 vérifications, journal sans erreur ni avertissement (`godot --headless res://tests/test_runner.tscn`).
- Débogage (F3 puis F4-F10) : actif seulement dans les builds de debug.
- Écarts connus à traiter : butin perdu si sac plein (toast d'avertissement) ; manette/tactile des écrans à valider en P7 ; remappage des touches en P7.

**Prochaine étape : P3** — étendre `tools/gen_maps.py` (village 80×60, forêt 56×48, lac 56×44, côte 56×34, intérieurs des commerces/maisons), `tools/content/npcs.py` (10 PNJ, dialogues FR/EN, événements, cadeaux, emplois du temps), système d'amitié, pathfinding A* sur grille, magasins.

### Journal — P3 terminée (2026-11-11)

Village d'Ormelune habité : 17 cartes (ferme, 3 maisons, village, forêt, lac, plage, 9 intérieurs), 10 PNJ originaux (18+ répliques chacun, 2 événements de cœur, goûts, anniversaires), amitié 0-10 cœurs (plafond 8 sans relation, bouquet → couple, anneau → fiançailles), cadeaux (1/jour, 2/semaine, ×4 à l'anniversaire), emplois du temps (jour de semaine, saison/météo, cloche des Ondes), déplacements A* (AStarGrid2D) et trajets entre cartes par graphe de passages, 7 commerces + marché avec horaires, jours de fermeture, stocks de saison, achat/vente, recettes à l'auberge, grand sac.

- Nouveau code : `friendship.gd`, `dialogue.gd`, `schedule.gd`, `grid_nav.gd`, `shops.gd`, `npc.gd`, `npc_manager.gd`, `shop_screen.gd`, `tools/content/npcs.py`, `tools/mapkit.py`, `tools/gen_maps_world.py`, `tools/check_glyphs.py`.
- Tests : 41 tests, 2 089 vérifications (cohérence des données PNJ, points d'horaire marchables, chemin A* vers chaque point, passages, amitié, magasins, PNJ en situation réelle).
- Reste pour plus tard : mariage effectif (scène de noces le `wedding_day`) et écran des relations/anniversaires → P6 (journal) ; entrée de la mine et de l'alpage → P5/P6.

**Prochaine étape : P4** — élevage (poulailler, étable, silo, achat d'animaux, affection, production), machines (fourneau déjà défini, fromagerie, baratte, métier à tisser, presse, bocaux, fumoir, ruche, trieuse), menu d'artisanat (75 recettes), cuisine (28 plats avec buffs), construction chez Isaure, amélioration de la maison, meubles rotatifs, papiers peints et sols.

### Journal — P4 terminée (2026-11-11)

Élevage, machines, artisanat, cuisine, construction, maison : poulailler / étable / silo (2 niveaux d'extension, un chantier à la fois, délais en jours), maison à 3 niveaux (cuisine dès le niveau 2, cartes `farmhouse_1..3`, bâtiments et maison dessinés dynamiquement par `MapRuntime.all_statics/all_warps/all_zones`), 6 types d'animaux + chien, affection (caresse quotidienne, pâturage ou foin du silo), production selon la qualité (affection), 8 machines (heure absolue, qualité conservée, combustible, ruches saisonnières), menu d'artisanat (47 recettes) et de cuisine (28 plats), meubles posables (indoor), rotation par miroir (limite d'art : pas de sprites par orientation), papiers peints et sols.

- Nouveau code : `machines.gd`, `crafting.gd`, `buildings.gd`, `animals.gd`, `animal_entity.gd`, `animal_manager.gd`, `crafting_screen.gd`, `build_screen.gd`, `animal_shop_screen.gd`, `name_prompt.gd`.
- Tests : 51 tests, 2 205 vérifications.
- Reste : buffs de plats testés (déjà en P2) ; serre → P6.

**Prochaine étape : P5** — mine (60 étages procéduraux, 3 biomes, ascenseur), combat temps réel (6 monstres), fourneau déjà en place, amélioration d'outils chez Bastien, pêche (mini-jeu « ondes », 20+ poissons, casiers).
