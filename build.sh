#!/usr/bin/env bash
# Valbrume — build complet : assets → données → i18n → équilibrage → tests → exports (Windows, macOS, Android).
# Variables optionnelles : GODOT=/chemin/godot  ·  ANDROID_HOME=/chemin/sdk
#   GODOT_ANDROID_KEYSTORE_RELEASE_PATH / _USER / _PASSWORD : clé de publication (AAB signé pour le Play Store)
# Les export templates, le JDK et le SDK Android ne sont JAMAIS téléchargés par ce script : s'ils manquent,
# l'export concerné est sauté et la liste exacte de ce qu'il faut installer est affichée à la fin.
set -u
cd "$(dirname "$0")"
GAME="Valbrume"
MISSING=()
SKIPPED=()

say() { printf '\n\033[1m== %s\033[0m\n' "$*"; }

# --- Godot -----------------------------------------------------------------------
if [ -z "${GODOT:-}" ]; then
  for c in godot godot4 /Applications/Godot.app/Contents/MacOS/Godot; do
    if command -v "$c" >/dev/null 2>&1; then GODOT="$c"; break; fi
  done
fi
if [ -z "${GODOT:-}" ]; then echo "Godot 4.x introuvable : définis GODOT=/chemin/vers/godot"; exit 2; fi
GODOT_VERSION="$("$GODOT" --version | head -1)"
TEMPLATE_VERSION="$(echo "$GODOT_VERSION" | cut -d. -f1-4)"      # ex. 4.7.2.stable
echo "Godot : $GODOT_VERSION"

PY=python3
[ -x .venv/bin/python ] && PY=.venv/bin/python

say "1. Assets (déterministes) et données"
$PY tools/build_assets.py --no-audio >/dev/null || { echo "échec build_assets"; exit 1; }
$PY tools/build_data.py && $PY tools/gen_maps.py >/dev/null || { echo "échec build_data / gen_maps"; exit 1; }

say "2. Contrôles : i18n, glyphes, équilibrage"
$PY tools/check_i18n.py || exit 1
$PY tools/check_glyphs.py || exit 1
$PY tools/balance_sim.py --check | tail -3 || exit 1

say "3. Import et tests headless"
"$GODOT" --headless --import >/dev/null 2>&1
"$GODOT" --headless res://tests/test_runner.tscn | tail -6
if [ "${PIPESTATUS[0]}" -ne 0 ]; then echo "Des tests échouent : export annulé."; exit 1; fi

# --- prérequis d'export ------------------------------------------------------------
case "$(uname -s)" in
  Darwin) TEMPLATE_DIR="$HOME/Library/Application Support/Godot/export_templates/$TEMPLATE_VERSION" ;;
  Linux)  TEMPLATE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/$TEMPLATE_VERSION" ;;
  *)      TEMPLATE_DIR="${APPDATA:-$HOME}/Godot/export_templates/$TEMPLATE_VERSION" ;;
esac
HAVE_TEMPLATES=0; [ -d "$TEMPLATE_DIR" ] && HAVE_TEMPLATES=1
HAVE_JDK=0; if command -v java >/dev/null 2>&1 && java -version >/dev/null 2>&1; then HAVE_JDK=1; fi
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
HAVE_SDK=0; [ -d "$SDK/platform-tools" ] && HAVE_SDK=1

if [ $HAVE_TEMPLATES -eq 0 ]; then MISSING+=("Export templates Godot $TEMPLATE_VERSION (Éditeur Godot → Projet → Gérer les modèles d'exportation, ou godotengine.org/download) dans : $TEMPLATE_DIR"); fi
if [ $HAVE_JDK -eq 0 ]; then MISSING+=("JDK 17 (ex. brew install --cask temurin@17) puis relancer ce script"); fi
if [ $HAVE_SDK -eq 0 ]; then MISSING+=("SDK Android (Android Studio → SDK Manager : Platform-Tools, Build-Tools 35.0.1, Platform 36, CMake 3.10.2, NDK r28) dans : $SDK, ou export ANDROID_HOME=…"); fi

mkdir -p build/windows build/macos build/android

export_one() {  # $1 preset  $2 mode (release|debug)  $3 sortie
  say "Export : $1 → $3"
  if "$GODOT" --headless --export-$2 "$1" "$3" 2>&1 | tail -4; then
    [ -s "$3" ] && echo "OK : $3" || { echo "pas de fichier produit"; SKIPPED+=("$1"); }
  fi
}

say "4. Exports"
if [ $HAVE_TEMPLATES -eq 1 ]; then
  export_one "Windows Desktop" release "build/windows/$GAME.exe"
  export_one "macOS" release "build/macos/$GAME.zip"
else
  SKIPPED+=("Windows Desktop" "macOS")
fi

if [ $HAVE_TEMPLATES -eq 1 ] && [ $HAVE_JDK -eq 1 ] && [ $HAVE_SDK -eq 1 ]; then
  export ANDROID_HOME="$SDK"
  if [ ! -d android/build ] && [ -f "$TEMPLATE_DIR/android_source.zip" ]; then
    mkdir -p android/build && unzip -q "$TEMPLATE_DIR/android_source.zip" -d android/build
    echo "$TEMPLATE_VERSION" > android/.build_version
    touch android/build/.gdignore
  fi
  export_one "Android APK (test)" debug "build/android/$GAME-debug.apk"
  if [ -n "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:-}" ]; then
    export GODOT_ANDROID_KEYSTORE_RELEASE_USER GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
    export_one "Android AAB" release "build/android/$GAME.aab"
  else
    echo "Pas de clé de publication configurée : AAB signé avec la clé de DEBUG (test uniquement, refusé par le Play Store)."
    export_one "Android AAB" debug "build/android/$GAME.aab"
    MISSING+=("Clé de publication Android (voir README, section « Keystore de release ») : GODOT_ANDROID_KEYSTORE_RELEASE_PATH/_USER/_PASSWORD, puis relancer ./build.sh")
  fi
else
  SKIPPED+=("Android APK (test)" "Android AAB")
fi

say "Résumé"
ls -la build/windows build/macos build/android 2>/dev/null | grep -v '^total' | grep -v '^d'
if [ ${#MISSING[@]} -gt 0 ]; then
  echo
  echo "À installer / configurer, puis relancer ./build.sh :"
  for m in "${MISSING[@]}"; do echo "  - $m"; done
fi
[ ${#SKIPPED[@]} -gt 0 ] && echo "Exports sautés : ${SKIPPED[*]}"
exit 0
