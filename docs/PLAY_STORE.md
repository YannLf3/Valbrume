# Fiche Google Play — Valbrume

## Informations
- **Nom** : Valbrume · **Package** : `com.yourname.valbrume` (à personnaliser dans `export_presets.cfg`).
- **Catégorie** : Jeux → Simulation (étiquettes : ferme, détente, pixel art, hors ligne).
- **Classification de contenu attendue** : tout public (PEGI 3 / ESRB Everyone) — violence très légère et cartoon contre des monstres de fantaisie (questionnaire IARC : « violence fantastique légère »), aucun contenu sexuel, aucune boisson ou drogue réelle, aucun achat intégré, aucune publicité.
- **Public cible** : 7 ans et plus. Application non destinée spécifiquement aux enfants de moins de 13 ans (pas de collecte de données, donc pas de contrainte COPPA/GDPR-K supplémentaire).
- **Sécurité des données** : « Aucune donnée collectée ni partagée ». Permissions Android demandées : aucune.
- **SDK cible** : API 36 (exigence Play pour toute nouvelle application et mise à jour à partir du 31 août 2026). Architectures : arm64-v8a, armeabi-v7a. Format : AAB.

## Description courte (80 caractères max)
- FR : Cultive, pêche, creuse et refonds les cloches d'un village. Cosy, hors ligne.
- EN : Farm, fish, mine and recast a village's bells. Cozy and fully offline.

## Description longue — Français
Hérite de la ferme de ta tante Odile, fondeuse de cloches, au village d'Ormelune… dont le Carillon s'est tu le jour de son départ.

Cultive 24 plantes au fil des quatre saisons, élève poules, vaches, chèvres, moutons et canes, soigne ton chien, installe tes machines (fromagerie, fumoir, ruches…) et transforme ta récolte en plats savoureux. Pêche grâce au mini-jeu « Ondes », descends dans une mine de 60 étages, affronte des monstres rigolos et rapporte des minerais pour améliorer tes outils.

Rencontre dix habitants attachants : chacun a ses goûts, son emploi du temps, son anniversaire et ses secrets. Offre des cadeaux, découvre leurs histoires, et peut-être tomberas-tu amoureux(se).

Rassemble matériaux, amis et courage pour refondre les six cloches du Carillon, participe aux quatre festivals, complète le musée et rends à Ormelune sa musique.

• Pixel art, musique et sons 100 % originaux • Sauvegarde automatique, 3 emplacements • Manette, clavier et commandes tactiles • Français et anglais • Aucun achat intégré, aucune publicité, aucune donnée collectée

## Long description — English
Inherit your aunt Odile's farm — she was a bell-founder — in the village of Ormelune, whose Carillon fell silent the day she left.

Grow 24 crops through four seasons, raise chickens, cows, goats, sheep and ducks, look after your dog, set up machines (cheese press, smoker, beehives...) and turn your harvest into hearty dishes. Fish with the "Waves" mini-game, dive into a 60-floor mine, face goofy monsters and bring back ore to upgrade your tools.

Meet ten lovable villagers, each with their own tastes, schedule, birthday and secrets. Give gifts, uncover their stories, and perhaps fall in love.

Gather materials, friends and courage to recast the Carillon's six bells, take part in four festivals, complete the museum and give Ormelune its music back.

• 100% original pixel art, music and sound • Autosave, 3 slots • Gamepad, keyboard and touch controls • French and English • No in-app purchases, no ads, no data collected

## Captures à produire (paysage, au moins 2, idéalement 8)
1. Ferme au printemps avec champ planté. 2. Place d'Ormelune un jour de festival. 3. Village la nuit sous la pluie (lumières). 4. Mine, étage de biome 3 avec monstres. 5. Mini-jeu de pêche « Ondes ». 6. Intérieur de la maison avec cuisine. 7. Dialogue avec portrait. 8. Fonderie du Carillon. Tailles : 1920×1080 minimum (téléphone), capture tablette 7" et 10" recommandées ; graphique de présentation 1024×500 (utiliser `assets/ui/title_bg.png` mis à l'échelle) ; icône 512×512 (`assets/icons/icon_512.png`). La commande `godot --path . res://tests/shot_story.tscn -- --out=<dossier>` (et les autres `tests/shot_*.tscn`) produit des captures de départ.

## Politique de confidentialité (minimale, à publier sur une URL)
> **Valbrume — politique de confidentialité.** Le jeu ne collecte, n'enregistre, ne transmet et ne partage aucune donnée personnelle. Il ne demande aucune permission et ne contient ni publicité, ni outil d'analyse, ni achat intégré, ni connexion réseau. Les sauvegardes et les options restent sur ton appareil, dans l'espace privé de l'application ; elles sont supprimées si tu désinstalles le jeu. Contact : *(ton adresse e-mail)*. Dernière mise à jour : *(date)*.

## Checklist de publication
- [ ] Remplacer `com.yourname.valbrume` par ton package définitif (les deux presets Android) ; incrémenter `version/code` à chaque envoi.
- [ ] Générer le keystore de release et configurer les variables (README), ou activer Play App Signing ; sauvegarder le keystore.
- [ ] `./build.sh` → `build/android/Valbrume.aab` signé en release (pas la clé de debug).
- [ ] Tester l'APK sur au moins un appareil réel (portrait refusé, paysage forcé, joystick, zones sûres, pause en arrière-plan = sauvegarde).
- [ ] Créer l'application dans la Play Console ; remplir fiche, captures, graphique, icône, descriptions FR/EN.
- [ ] Classification du contenu (questionnaire IARC) ; section Sécurité des données : « aucune donnée » ; déclaration du public cible ; URL de la politique de confidentialité.
- [ ] Piste de test interne puis fermée (obligation de tests pour les nouveaux comptes personnels), puis production.
- [ ] Vérifier le rapport de pré-lancement (Android vitals, 64 bits ✓, API cible 36 ✓).
