# Valbrume

Jeu de ferme et de vie de village en 2D (Godot 4.7, GDScript typé), **100 % original** : tout l'art, le son et la musique sont générés par les scripts de ce dépôt. Cultive la terre, élève des animaux, pêche, descends à la mine, tisse des liens avec les dix habitants d'Ormelune et refonds les six cloches du Carillon. Voir [docs/GDD.md](docs/GDD.md).

Lancer : ouvrir le dossier dans Godot 4.7 et appuyer sur **F5** (scène principale `scenes/main.tscn`). Les assets et données générés sont versionnés : le projet s'ouvre sans rien régénérer.

## Contrôles
| | Clavier / souris | Manette | Tactile (Android) |
|---|---|---|---|
| Se déplacer | ZQSD, WASD ou flèches (option) | stick gauche / croix | joystick flottant (moitié gauche) |
| Action intelligente | E ou Espace · clic gauche sur une case proche | A | bouton Action · toucher une case proche |
| Outil (maintenir = charge, zone aux niveaux élevés) | F ou C | X | bouton Outil |
| Sac / artisanat | Tab ou I | Y | bouton Sac |
| Journal | J | Retour | — (via le menu) |
| Menu pause | Échap | Start | bouton Menu |
| Barre d'objets | 1–9, 0, -, = · molette | épaules | toucher un emplacement |

Les touches se remappent dans Options → Touches. L'interface tactile n'apparaît que sur écran tactile (ou si l'option la force) ; l'échelle de l'interface se règle dans les options. Débogage (versions de debug uniquement) : F3 puis F4 +1 h, F5 +1 jour, F6 +1 saison, F7 +1000, F8 kit d'objets, F9 énergie, F10 météo.

## Régénérer les assets et les données
Prérequis : Python 3 + Pillow + numpy (`python3 -m venv .venv && .venv/bin/pip install Pillow numpy`).
```bash
.venv/bin/python tools/build_assets.py            # sprites, tuiles, icônes, UI, audio (déterministe ; --verify pour contrôler)
.venv/bin/python tools/build_data.py              # data/*.json et i18n/strings.csv depuis tools/content/
.venv/bin/python tools/gen_maps.py                # cartes data/maps/*.json et aperçus
.venv/bin/python tools/contact_sheet.py           # planches de contact ×4 pour inspection visuelle
godot --headless --import                         # (ré)importe les ressources
```

## Tests et contrôles
```bash
godot --headless res://tests/test_runner.tscn     # 81 tests
.venv/bin/python tools/check_i18n.py              # FR/EN complets, aucun texte en dur
.venv/bin/python tools/check_glyphs.py            # tous les textes tiennent dans la police
.venv/bin/python tools/balance_sim.py --check     # courbe d'argent de l'année 1
```

## Builds
`./build.sh` (macOS/Linux) ou `.\build.ps1` (Windows) : régénère, vérifie, teste puis exporte Windows (`build/windows/Valbrume.exe`), macOS (`build/macos/Valbrume.zip`, universel x86_64 + arm64, signature ad hoc) et Android (`build/android/Valbrume.aab` + `Valbrume-debug.apk`). Le script **ne télécharge rien** : s'il manque les export templates, le JDK ou le SDK Android, il saute l'export concerné et liste exactement ce qu'il faut installer.

Prérequis d'export : *export templates* Godot 4.7.2 ; pour Android, JDK 17, SDK Android (Platform 36, Build-Tools 35.0.1, CMake 3.10.2, NDK r28) et la variable `ANDROID_HOME`. Configuration Android : gradle activé, `arm64-v8a` + `armeabi-v7a`, `minSdk` 24, **`targetSdk` 36** (Google Play exige l'API 36 pour toute nouvelle application ou mise à jour à partir du 31 août 2026), paysage forcé, aucune permission, icônes adaptatives. Le nom de package est `com.yourname.valbrume` : remplace `yourname` dans `export_presets.cfg` (deux presets Android) avant de publier.

### Keystore de release Android
Aucune clé de publication n'est fournie. Pour signer ton AAB :
```bash
keytool -genkeypair -v -keystore ~/valbrume-release.keystore -alias valbrume -keyalg RSA -keysize 2048 -validity 10000
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=~/valbrume-release.keystore
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=valbrume
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD='…'      # ne jamais l'écrire dans le dépôt
./build.sh
```
Sans cette configuration, l'AAB est signé avec la clé de debug (test uniquement, refusé par le Play Store). Conserve précieusement le keystore et active la signature Play App Signing dans la Play Console.

### macOS : signature et notarisation
Le build est signé *ad hoc* (il se lance localement ; Gatekeeper demandera un clic droit → Ouvrir pour un téléchargement). Pour distribuer proprement (compte Apple Developer requis) :
1. Dans `export_presets.cfg` (preset macOS) : `codesign/codesign=2`, `codesign/identity="Developer ID Application: Ton Nom (TEAMID)"`, `codesign/apple_team_id="TEAMID"`, `codesign/entitlements/…` si besoin ; `notarization/notarization=2` (notarytool) avec `notarization/apple_id_name`, `apple_id_password` (mot de passe d'application) et `apple_team_id`.
2. Ou en ligne de commande, sur le `.app` extrait du zip : `codesign --deep --force --options runtime --timestamp --sign "Developer ID Application: …" Valbrume.app`, puis `ditto -c -k --keepParent Valbrume.app Valbrume.zip`, `xcrun notarytool submit Valbrume.zip --apple-id … --team-id … --password … --wait`, et `xcrun stapler staple Valbrume.app`.

## Structure
```
project.godot  export_presets.cfg  build.sh  build.ps1
tools/    générateurs Python (palette, sprites, audio, police, cartes, données, contrôles)
assets/   sortie générée (PNG, WAV, polices, icônes)      data/   JSON de données et de cartes
scenes/ scripts/ (autoload, systems, world, entities, ui)  i18n/   traductions FR/EN (CSV)
tests/    runner et tests headless                          docs/   GDD, architecture, fiche Play Store
```
Documents : [LEGAL.md](LEGAL.md), [CREDITS.md](CREDITS.md), [CHANGELOG.md](CHANGELOG.md), [PLAN.md](PLAN.md).
