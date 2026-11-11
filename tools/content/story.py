"""Fil rouge (les six cloches du Carillon), festivals, quêtes, collections du musée : données et textes FR/EN."""
from typing import Any, Dict, List, Tuple

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__))))
from items import FISH  # noqa: E402

P = Tuple[str, str]

# Exigences : (type, cible, quantité).
#   stat : statistique du joueur · kinds : espèces distinctes d'une statistique · item : objets à fournir
#   money : argent à fournir · mine_floor : étage le plus profond · hearts_total : cœurs cumulés
#   animals : nombre d'animaux · building : niveau d'un bâtiment (cible, niveau) · bells : cloches déjà fondues
#   donated : objets donnés au musée
BELLS: List[Dict[str, Any]] = [
    dict(id="furrows", fr="Sillons", en="Furrows",
         desc=("La cloche des récoltes. Elle sonnait à chaque première gerbe. Sa fonte rendra la serre à la ferme.",
               "The harvest bell. It rang at the first sheaf of every year. Casting it will give the farm its greenhouse back."),
         reward=("La serre est reconstruite : cultive toute l'année, à l'abri !", "The greenhouse is rebuilt: grow all year round, under glass!"),
         req=[("stat", "crops_harvested", 60), ("item", "ingot_copper", 5), ("money", "", 2000)]),
    dict(id="waves", fr="Ondes", en="Waves",
         desc=("La cloche des marées, grave et lente. Elle guidait les barques. Elle ouvrira la route de la plage.",
               "The tide bell, deep and slow. It guided the boats home. It will open the road to the beach."),
         reward=("L'éboulis de la route de la plage s'effondre : la mer t'attend !", "The rockslide on the beach road gives way: the sea awaits!"),
         req=[("kinds", "fish_caught", 12), ("item", "ingot_iron", 5), ("money", "", 4000)]),
    dict(id="stone", fr="Roche", en="Stone",
         desc=("La cloche des galeries. Elle prévenait les mineurs. Elle brisera le sceau de l'étage 40.",
               "The galleries' bell. It warned the miners. It will break the seal on floor 40."),
         reward=("Les profondeurs de la mine (étages 41 à 60) sont ouvertes.", "The depths of the mine (floors 41 to 60) are open."),
         req=[("mine_floor", "", 40), ("item", "ingot_silver", 5), ("money", "", 8000)]),
    dict(id="hearth", fr="Foyer", en="Hearth",
         desc=("La cloche des veillées. Elle rassemblait le village le dimanche. Elle fera revenir le marché.",
               "The evening bell. It gathered the village on Sundays. It will bring the market back."),
         reward=("Le marché du dimanche rouvre sur la place d'Ormelune.", "The Sunday market reopens on Ormelune's square."),
         req=[("hearts_total", "", 30), ("item", "cheese", 3), ("money", "", 6000)]),
    dict(id="flocks", fr="Troupeaux", en="Flocks",
         desc=("La cloche des estives, aiguë et claire. Elle appelait les bêtes. Elle ouvrira le sentier de l'alpage.",
               "The summer pasture bell, high and clear. It called the animals home. It will open the alpine trail."),
         reward=("Le sentier de l'alpage est dégagé : herbes rares et vue sur toute la vallée.", "The alpine trail is cleared: rare herbs and a view over the whole valley."),
         req=[("animals", "", 6), ("building", "coop", 2), ("item", "ingot_iron", 8), ("money", "", 12000)]),
    dict(id="great", fr="Grand Bourdon", en="Great Bourdon",
         desc=("La mère de toutes les cloches, la dernière qu'Odile n'ait pas pu fondre. Quand elle sonnera, le Carillon sera complet.",
               "The mother of all bells, the one Odile never managed to cast. When it rings, the Carillon will be whole."),
         reward=("Le Grand Bourdon sonne. Ormelune chante de nouveau !", "The Great Bourdon rings. Ormelune sings again!"),
         req=[("bells", "", 5), ("donated", "", 30), ("item", "ingot_brumite", 10), ("money", "", 30000)]),
]

LORE: List[P] = [
    ("Registre d'Odile, p. 1 — « Premier alliage : neuf parts de cuivre pour une d'étain. Elle chante, mais elle chante timide. Je recommence. »",
     "Odile's ledger, p. 1 — 'First alloy: nine parts copper to one of tin. She sings, but shyly. I'll start over.'"),
    ("Registre d'Odile, p. 2 — « Une cloche ne se fond pas pour qu'on l'entende, mais pour qu'on se retrouve. C'est Hyacinthe qui disait ça. »",
     "Odile's ledger, p. 2 — 'A bell isn't cast to be heard but so people find each other. That's what Hyacinthe used to say.'"),
    ("Registre d'Odile, p. 3 — « Le minerai de brumite ne se trouve qu'au fond. Il vibre quand on l'approche des autres métaux. Étrange et beau. »",
     "Odile's ledger, p. 3 — 'Brumite ore is only found deep down. It hums when you bring it near other metals. Strange and lovely.'"),
    ("Registre d'Odile, p. 4 — « Mes mains tremblent. Corentin écrit sous ma dictée. Il croit que je ne vois pas qu'il pleure en silence. »",
     "Odile's ledger, p. 4 — 'My hands tremble. Corentin writes as I dictate. He thinks I don't notice him crying silently.'"),
    ("Registre d'Odile, p. 5 — « J'ai quitté Ormelune sans dire où j'allais. Ce n'était pas un abandon : il me fallait quelqu'un pour reprendre le feu. »",
     "Odile's ledger, p. 5 — 'I left Ormelune without saying where I was going. It wasn't abandonment: I needed someone to take up the fire.'"),
    ("Registre d'Odile, p. 6 — « Au petit nouveau, à la petite nouvelle, à celui ou celle que j'ai choisi(e) : le Grand Bourdon n'attend que ta main. »",
     "Odile's ledger, p. 6 — 'To the newcomer, to whoever I chose: the Great Bourdon only waits for your hand.'"),
]

# Festivals : saison → (jour, id, mini-jeu)
FESTIVALS = [
    dict(id="seeds", season=0, day=14, game="memory", fr="Fête des Semis", en="Seed Fair",
         intro=("C'est la Fête des Semis ! Concours de mémoire : retiens la séquence de graines et rejoue-la sans te tromper.",
                "It's the Seed Fair! Memory contest: remember the sequence of seeds and replay it without a slip."),
         prize_item="seed_honeymelon"),
    dict(id="regatta", season=1, day=16, game="timing", fr="Régate des Ondes", en="Wave Regatta",
         intro=("C'est la Régate des Ondes ! Épreuve de cadence : frappe au bon moment quand le fanion passe devant la bouée.",
                "It's the Wave Regatta! Rhythm contest: strike at the right moment as the pennant passes the buoy."),
         prize_item="honey"),
    dict(id="pumpkin", season=2, day=20, game="judging", fr="Concours du Potiron", en="Pumpkin Contest",
         intro=("C'est le Concours du Potiron ! Présente ta plus belle récolte au jury : prix, qualité, fraîcheur comptent.",
                "It's the Pumpkin Contest! Present your finest harvest to the jury: value, quality and freshness count."),
         prize_item="saffron"),
    dict(id="lanterns", season=3, day=22, game="target", fr="Fête des Lanternes", en="Lantern Festival",
         intro=("C'est la Fête des Lanternes ! Lance cinq boules de neige sur la cible mouvante : plus tu es près du centre, mieux c'est.",
                "It's the Lantern Festival! Throw five snowballs at the moving target: the closer to the center, the better."),
         prize_item="frostberry_tart"),
]

# Collections du musée : catégorie → objets, paliers de récompense
MINERALS = ["quartz", "amethyst", "topaz", "emerald", "ruby", "moonstone", "ore_copper", "ore_iron", "ore_silver", "ore_brumite"]
ARTIFACTS = ["bell_clapper", "clay_whistle", "rusty_key", "engraved_stone", "fossil_fern", "old_coin", "glass_bead", "tin_soldier", "ammonite", "ledger_page"]
FISH_IDS = [f[0] for f in FISH]
COLLECTIONS = {
    "minerals": {"items": MINERALS, "rewards": [[3, {"item": "ingot_copper", "n": 3}], [6, {"item": "ingot_iron", "n": 3}], [10, {"money": 2500}]]},
    "artifacts": {"items": ARTIFACTS, "rewards": [[3, {"item": "quarry_charge", "n": 5}], [6, {"item": "ingot_silver", "n": 2}], [10, {"money": 4000}]]},
    "fish": {"items": FISH_IDS, "rewards": [[5, {"item": "bait", "n": 20}], [12, {"item": "rod_2", "n": 1}], [24, {"money": 6000}]]},
}

# Quêtes quotidiennes : gabarits
QUEST_ITEMS = {
    "spring": ["turnip", "carrot", "spinach", "pea", "dandelion", "wild_garlic", "egg"],
    "summer": ["tomato", "zucchini", "bean", "lavender", "blackberry", "milk", "egg"],
    "autumn": ["beet", "leek", "grape", "chestnut", "hazelnut", "cheese", "egg"],
    "winter": ["kale", "parsnip", "lambs_lettuce", "pinecone", "holly", "wool", "goat_milk"],
}
QUEST_MONSTERS = ["pebbler", "mosshop", "emberbat", "frostspit", "glowmite"]


def tables() -> Dict[str, Any]:
    story = {"bells": [{"id": b["id"], "req": [list(r) for r in b["req"]]} for b in BELLS], "lore": len(LORE)}
    festivals = {f["id"]: {"season": f["season"], "day": f["day"], "game": f["game"], "prize": f["prize_item"]} for f in FESTIVALS}
    quests = {"items": QUEST_ITEMS, "monsters": QUEST_MONSTERS, "board_size": 4, "max_active": 3}
    return {"story": story, "festivals": festivals, "quests": quests, "collections": COLLECTIONS}


def strings() -> Dict[str, Tuple[str, str]]:
    out: Dict[str, Tuple[str, str]] = {}
    for b in BELLS:
        k = b["id"].upper()
        out["BELL_" + k] = (b["fr"], b["en"])
        out["BELLD_" + k] = b["desc"]
        out["BELLR_" + k] = b["reward"]
    for i, (fr, en) in enumerate(LORE):
        out["LORE_%d" % (i + 1)] = (fr, en)
    for f in FESTIVALS:
        k = f["id"].upper()
        out["FEST_" + k] = (f["fr"], f["en"])
        out["FESTI_" + k] = f["intro"]
    out["COLL_MINERALS"] = ("Minéraux", "Minerals")
    out["COLL_ARTIFACTS"] = ("Artefacts", "Artifacts")
    out["COLL_FISH"] = ("Poissons", "Fish")
    return out
