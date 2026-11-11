# Valbrume — Game Design Document

## Pitch
*Valbrume* est un jeu de ferme et de vie de village en 2D, cosy et bienveillant. Tu hérites de la ferme de ta tante Odile, fondeuse de cloches, au village d'Ormelune, dont le Carillon s'est tu le jour de son départ. Cultive, élève, pêche, descends à la mine, tisse des liens… et refonds les six cloches pour qu'Ormelune chante de nouveau.

## Univers
- **Région** : la vallée de Brume-Val. **Village** : Ormelune. **Ferme** : au choix du joueur (« Les Trois Sillons » par défaut).
- **Histoire de départ** : Odile a pris la route sans dire où ; elle lègue la ferme et une lettre. Le Carillon (six cloches : *Sillons, Ondes, Roche, Foyer, Troupeaux, Grand Bourdon*) est muet. Son registre, dont six pages se retrouvent en creusant, raconte pourquoi elle est partie : pour qu'il y ait quelqu'un pour reprendre le feu.
- **Ton** : doux, humoristique, jamais cruel ; contenu tout public.

## Cartes (24)
Ferme 64×52 · maison (3 niveaux) · village 80×60 · forêt de Bois-Brume · lac Miroir (entrée de la mine) · plage des Ondes (verrouillée) · alpage (verrouillé) · beffroi du Carillon · serre · poulailler et étable (2 niveaux chacun) · 9 intérieurs (épicerie, forge, charpenterie, élevage, pêcherie, clinique, auberge, musée, chaumière) · mine : 60 étages générés à l'exécution (graine = partie + étage + jour).

## Habitants (10)
| PNJ | Métier | Anniv. | Romance |
|---|---|---|---|
| Capucine | Épicière | Printemps 8 | oui |
| Bastien | Forgeron | Automne 3 | oui |
| Isaure | Charpentière | Été 12 | oui |
| Théodule | Éleveur | Hiver 5 | non |
| Maïwenn | Pêcheuse | Automne 17 | non |
| Hyacinthe | Guérisseuse | Printemps 25 | non |
| Gaspard | Aubergiste | Été 26 | non |
| Corentin | Conservateur du musée | Hiver 18 | oui |
| Roseline | Tisserande | Été 4 | non |
| Pim | Écolier | Automne 25 | non |

Chacun a 24 répliques (par palier de cœurs, saison, météo, anniversaire, cadeaux), 2 événements de cœur à choix (3 et 7 cœurs), des goûts (aimé / apprécié / détesté), un emploi du temps selon le jour, la météo, les festivals et les cloches. Amitié 0 à 10 cœurs (plafond à 8 pour les romançables tant qu'on ne sort pas ensemble : bouquet à 8 cœurs ; anneau à 10 cœurs et maison niveau 2 → noces 3 jours plus tard).

## Temps et saisons
Journée de 6 h à 2 h du matin ; 1 minute de jeu = 0,7 s réelle (réglable). 4 saisons × 28 jours, 112 jours par an. Évanouissement à 2 h : perte de 10 % de l'argent (max. 1 000) et énergie réduite de moitié. Météo : soleil, pluie, orage, vent, neige, tirées par saison avec prévision (rainette de la maison, harpe des vents de la place).

## Boucle de jeu
Labourer → semer → arroser → récolter → expédier (vente payée la nuit) ; mine et combat pour les minerais ; forge pour les lingots et les outils ; pêche et élevage pour des revenus réguliers ; amitiés, quêtes, festivals pour les récompenses ; cloches pour la progression.

## Économie chiffrée
Tous les nombres vivent dans `tools/content/world.py` (équilibrage) et `tools/content/items.py` (objets). Rentabilité des cultures (or par parcelle et par jour, saison de 28 jours, qualité moyenne ×1,12) :

```
culture          saison  graine  vente jours repousse or/parcelle/jour
Tulipe-cloche    spring      40     96     8       -       7.2
Oignon nouveau   spring      35     76     7       -       7.2
Petit pois       spring      60     32     9       3       6.8
Navet            spring      20     38     4       -       5.6
Carotte          spring      30     60     6       -       5.3
Épinard          spring      25     46     5       -       4.7
Melon miel       summer      90    260    13       -      14.4
Courgette        summer      50     38     8       3       8.9
Lavande          summer      35     82     7       -       8.1
Tomate           summer      55     50    10       4       8.0
Aubergine        summer      45    106     8       -       7.9
Haricot          summer      65     36     9       3       7.8
Potiron          autumn     100    300    13       -      16.9
Raisin           autumn      70     55    10       3      12.9
Safran           autumn      80    190    11       -       9.5
Chou rouge       autumn      60    150    10       -       7.7
Betterave        autumn      30     70     6       -       6.9
Poireau          autumn      40     92     8       -       6.8
Givrelle         winter      80     60    10       4       9.1
Perce-neige      winter      30     72     7       -       7.2
Panais           winter      35     86     9       -       6.6
Topinambour      winter      50    126    11       -       6.5
Chou frisé       winter      30     66     7       -       6.3
Mâche            winter      15     30     4       -       4.7
```

Simulation de l'année 1 (`tools/balance_sim.py`, agriculture seule, joueur raisonnablement efficace, rendement réel estimé à 75 %) :

```
fin de spring  (jour  28) : argent     4440 · parcelles  97 · arroseurs oui · gains cumulés     5440 · dépensé     1500
fin de summer  (jour  56) : argent     3577 · parcelles 110 · arroseurs oui · gains cumulés    24577 · dépensé    21500
fin de autumn  (jour  84) : argent     3577 · parcelles 110 · arroseurs oui · gains cumulés    48577 · dépensé    45500
fin de winter  (jour 112) : argent     7970 · parcelles 110 · arroseurs oui · gains cumulés    62970 · dépensé    55500

Achats réalisés (jour) :
  j 10  arroseurs
  j 29  poulailler
  j 30  cloche Sillons
  j 35  houe+arrosoir 2
  j 42  étable
  j 46  cloche Ondes
  j 63  maison 2
  j 68  cloche Foyer
  j 76  cloche Roche
  j 97  pioche+hache 3
ATTENTION : objectifs non atteints en un an : cloche Troupeaux, cloche Bourdon

bilan : 62970 é gagnés, 55500 é investis, 10/12 grands achats dans l'année.

```
L'agriculture seule finance 10 des 12 grands achats dans l'année ; la mine, la pêche, l'élevage et les festivals apportent le reste : l'année est gratifiante sans être triviale. Le script échoue (`--check`) si moins de 7 achats sont possibles ou si tout est bouclé avant le jour 56.

Coûts clés : poulailler 4 000 (+150 bois, 50 pierre) puis 8 000 ; étable 6 000 puis 12 000 ; silo 1 500 ; maison 10 000 puis 30 000 ; outils 2 000 / 5 000 / 10 000 (+ 5 lingots) ; grand sac 5 000 ; cloches 2 000 à 30 000 plus matériaux (voir la fonderie en jeu).

## Progression (fil rouge)
Six grands objectifs, chacun avec exigences et récompense :
1. **Sillons** (récolter 60 cultures) → serre reconstruite.
2. **Ondes** (12 espèces de poissons) → route de la plage.
3. **Roche** (étage 40 de la mine) → étages 41 à 60.
4. **Foyer** (30 cœurs cumulés) → marché du dimanche.
5. **Troupeaux** (6 animaux, poulailler niveau 2) → alpage.
6. **Grand Bourdon** (5 cloches, 30 dons au musée, 10 lingots de brumite, 30 000) → fin.

## Systèmes
- **Compétences** (niveaux 1 à 10) : agriculture, élevage, pêche, minage, combat, cueillette ; chaque palier donne une recette ou un bonus.
- **Outils** (4 niveaux) : houe, arrosoir, hache, pioche, faux, canne, épée ; la charge maintenue agit en zone aux niveaux élevés.
- **Agriculture** : qualité (normale/argent/or) selon engrais et compétence, cultures à repousse, mort hors saison, arroseurs ×3, épouvantail à grelots contre les *grignotins*, arbres fruitiers (28 jours), serre.
- **Élevage** : 5 espèces + chien ; affection (caresse quotidienne), pâturage ou foin du silo, production de qualité variable.
- **Machines** : fourneau, fromagerie, baratte, métier à tisser, pressoir, bocaux, fumoir, trieuse, ruche, casier.
- **Pêche** : mini-jeu « Ondes » (anneau, bille, arc ; ferrage puis cadence ; 3 ratés = ligne cassée), 24 poissons + 4 prises de casier selon lieu/saison/heure/météo.
- **Mine** : 60 étages, 3 biomes, ascenseur tous les 5, coffre tous les 10, 6 monstres à l'IA distincte.
- **Festivals** (4) : Semis (mémoire), Régate (cadence), Potiron (jury), Lanternes (cible).
- **Musée** : minéraux, artefacts, poissons ; paliers de récompenses.
- **Quêtes quotidiennes** : livraison, récolte, chasse, pêche.
- **Mobile** : joystick flottant, boutons Action/Outil/Sac/Menu, zones sûres, échelle d'interface 1 à 2.
