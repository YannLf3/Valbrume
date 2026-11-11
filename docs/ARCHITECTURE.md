# Architecture

## Principes
Data-driven (ajouter une culture, un objet, un PNJ = ajouter une entrée dans `tools/content/`), systèmes de logique pure (`scripts/systems/`, testables headless), scènes minimales (l'arbre est construit en code), communication par signaux via `EventBus`, aucune valeur d'équilibrage en dur (`data/balance.json`, lu par `Database.bal*`).

## Chaîne de production
```
tools/content/*.py ──► tools/build_data.py ──► data/*.json + i18n/strings.csv ──► import Godot (.translation)
tools/gen_*.py ──────► assets/*.png *.wav *.fnt (déterministe, graine fixe, palette de 43 couleurs)
tools/gen_maps*.py ──► data/maps/*.json (+ aperçus assets/contact/map_*.png)
```
`tools/build_assets.py` est le point d'entrée des assets (`--verify` contrôle le déterminisme par empreintes SHA-256 et la palette).

## Autoloads
| Autoload | Rôle |
|---|---|
| `EventBus` | Signaux globaux (temps, joueur, monde, social, interface) |
| `Settings` | Options persistées (`user://settings.json`) : langue, volumes, touches, tactile, échelle |
| `Database` | Charge `data/*.json` et les cartes ; textures d'atlas ; cartes de mine générées à la demande |
| `GameState` | Tout l'état de la partie (types JSON) ; `to_dict`/`from_dict` |
| `TimeManager` | Horloge, calendrier, verrous de temps (menus) |
| `SaveManager` | 3 emplacements JSON versionnés, copie de secours, migrations, sauvegarde en arrière-plan Android |
| `AudioManager` | Pool de SFX, musique à fondu enchaîné, volumes |
| `InputManager` | Actions, dispositions clavier, remappage, détection du mode actif (clavier/manette/tactile) |

## Systèmes (`scripts/systems/`, sans nœuds)
`farming`, `tool_use`, `world_objects`, `placement`, `machines`, `crafting`, `consumables`, `skills`, `recipes`, `economy`, `weather`, `day_cycle` (la nuit), `buildings`, `animals`, `friendship`, `dialogue`, `schedule`, `grid_nav` (A*), `shops`, `mine_gen`, `combat`, `fishing`, `fishing_game`, `tool_upgrades`, `story`, `festivals`, `festival_games`, `quests`, `collections`, `inventory` (`Inv`), `loot`, `loc`.

## Monde (`scripts/world/`, `scripts/entities/`)
`MapRuntime` (données d'une carte + état modifiable dans `GameState.maps`) → `MapView` (tuiles à 2 couches + sol + objets triés en profondeur + lumières) ; `World` orchestre : joueur, caméra, HUD, interactions, écrans, transitions, nuit ; gestionnaires `NpcManager`, `AnimalManager`, `MonsterManager` ; `Fx` (particules en pool), `WeatherFx`, `DayLight`.

## Flux des signaux (extraits)
```
TimeManager.minute_passed ─► Hud.refresh · World._on_minute (PNJ, lumières, machines) · Consumables.tick (buffs)
TimeManager.day_ended(summary) ─► World : fondu → SummaryScreen → load_map(réveil) → TimeManager.begin_day
DayCycle.run_night : vente du coffre → croissance/pluie/grignotins → saison → machines/ruches/casiers → animaux
                     → chantiers → outils chez le forgeron → météo suivante → sauvegarde auto
GameState.add_item ─► EventBus.item_gained ─► Hud (toast) + World (popup flottant)
MapRuntime.add/remove_object, set_soil ─► EventBus.object_changed/soil_changed ─► MapView (rafraîchit la case)
Skills.add_xp ─► skill_level_up ─► Recipes.refresh · fx · toast
MonsterManager.player_died ─► World ─► GameState.flags.died ─► TimeManager.end_day ─► DayCycle (pénalité, réveil à la clinique)
```

## Tests (`tests/`)
Runner maison : `godot --headless res://tests/test_runner.tscn` (81 tests, ~6 300 vérifications) ; `-- --only=test_save` pour un seul fichier. Contrôles visuels : `tests/shot*.tscn` lancent une fenêtre et enregistrent des captures. Performance : `tests/perf.tscn`.
