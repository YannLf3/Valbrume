# Valbrume — build complet sous Windows : assets → données → i18n → tests → exports.
# Variables optionnelles : $env:GODOT, $env:ANDROID_HOME, $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH/_USER/_PASSWORD
# Rien n'est téléchargé : les prérequis manquants sont listés à la fin.
$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot
$Game = "Valbrume"
$Missing = @(); $Skipped = @()

$Godot = $env:GODOT
if (-not $Godot) { foreach ($c in "godot", "godot4") { if (Get-Command $c -ErrorAction SilentlyContinue) { $Godot = $c; break } } }
if (-not $Godot) { Write-Host "Godot 4.x introuvable : définis `$env:GODOT"; exit 2 }
$Version = (& $Godot --version | Select-Object -First 1)
$TemplateVersion = ($Version -split "\.")[0..3] -join "."
Write-Host "Godot : $Version"

$Py = "python"; if (Test-Path ".venv\Scripts\python.exe") { $Py = ".venv\Scripts\python.exe" }
Write-Host "== 1. Assets et données"
& $Py tools/build_assets.py --no-audio | Out-Null
& $Py tools/build_data.py; & $Py tools/gen_maps.py | Out-Null
Write-Host "== 2. Contrôles"
& $Py tools/check_i18n.py; if ($LASTEXITCODE -ne 0) { exit 1 }
& $Py tools/check_glyphs.py; if ($LASTEXITCODE -ne 0) { exit 1 }
& $Py tools/balance_sim.py --check | Select-Object -Last 3
Write-Host "== 3. Import et tests"
& $Godot --headless --import 2>&1 | Out-Null
& $Godot --headless res://tests/test_runner.tscn | Select-Object -Last 6
if ($LASTEXITCODE -ne 0) { Write-Host "Des tests échouent : export annulé."; exit 1 }

$TemplateDir = Join-Path $env:APPDATA "Godot\export_templates\$TemplateVersion"
$HaveTemplates = Test-Path $TemplateDir
$HaveJdk = [bool](Get-Command java -ErrorAction SilentlyContinue)
$Sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } elseif ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { Join-Path $env:LOCALAPPDATA "Android\Sdk" }
$HaveSdk = Test-Path (Join-Path $Sdk "platform-tools")
if (-not $HaveTemplates) { $Missing += "Export templates Godot $TemplateVersion dans $TemplateDir" }
if (-not $HaveJdk) { $Missing += "JDK 17 (Temurin) dans le PATH" }
if (-not $HaveSdk) { $Missing += "SDK Android (Platform 36, Build-Tools 35.0.1, NDK r28) dans $Sdk, ou `$env:ANDROID_HOME" }

New-Item -ItemType Directory -Force build\windows, build\macos, build\android | Out-Null
function Export-One($Preset, $Mode, $Out) {
  Write-Host "== Export : $Preset -> $Out"
  & $Godot --headless "--export-$Mode" $Preset $Out 2>&1 | Select-Object -Last 4
  if (-not (Test-Path $Out)) { $script:Skipped += $Preset }
}
Write-Host "== 4. Exports"
if ($HaveTemplates) {
  Export-One "Windows Desktop" "release" "build\windows\$Game.exe"
  Export-One "macOS" "release" "build\macos\$Game.zip"
} else { $Skipped += "Windows Desktop", "macOS" }
if ($HaveTemplates -and $HaveJdk -and $HaveSdk) {
  $env:ANDROID_HOME = $Sdk
  if (-not (Test-Path android\build) -and (Test-Path "$TemplateDir\android_source.zip")) {
    New-Item -ItemType Directory -Force android\build | Out-Null
    Expand-Archive "$TemplateDir\android_source.zip" android\build -Force
    Set-Content android\.build_version $TemplateVersion
    New-Item android\build\.gdignore -ItemType File -Force | Out-Null
  }
  Export-One "Android APK (test)" "debug" "build\android\$Game-debug.apk"
  if ($env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH) { Export-One "Android AAB" "release" "build\android\$Game.aab" }
  else {
    Write-Host "Pas de clé de publication : AAB signé avec la clé de DEBUG (test uniquement)."
    Export-One "Android AAB" "debug" "build\android\$Game.aab"
    $Missing += "Clé de publication Android (README, section Keystore de release)"
  }
} else { $Skipped += "Android APK (test)", "Android AAB" }

if ($Missing.Count -gt 0) { Write-Host "`nÀ installer / configurer, puis relancer .\build.ps1 :"; $Missing | ForEach-Object { Write-Host "  - $_" } }
if ($Skipped.Count -gt 0) { Write-Host "Exports sautés : $($Skipped -join ', ')" }
