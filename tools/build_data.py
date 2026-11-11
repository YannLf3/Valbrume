"""Compile les tables de tools/content/ en data/*.json et i18n/strings.csv.

Le jeu ne lit que ces fichiers : c'est la frontière data-driven.
"""
import csv
import importlib
import json
import os
import sys
from typing import Any, Dict, Tuple

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "content"))

import items as I  # noqa: E402
import registry  # noqa: E402
import strings as S  # noqa: E402
import world as W  # noqa: E402
import gen_tiles  # noqa: E402

DATA = os.path.join(ROOT, "data")
STR: Dict[str, Tuple[str, str]] = {}


def opt(name: str):
    try:
        return importlib.import_module(name)
    except ModuleNotFoundError as e:
        if e.name != name:
            raise
        return None


def put(key: str, fr: str, en: str) -> None:
    if key in STR and STR[key] != (fr, en):
        raise ValueError("clé de traduction en double : " + key)
    STR[key] = (fr, en)


def dump(name: str, obj: Any) -> None:
    path = os.path.join(DATA, name + ".json")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(obj, f, ensure_ascii=False, indent=1, sort_keys=True)


def build_items() -> Dict[str, Any]:
    out: Dict[str, Any] = {}
    for idx, o in enumerate(registry.all_items()):
        d = {k: v for k, v in o.items() if k not in ("id", "fr", "en", "icon_spec", "desc")}
        d["icon"] = idx
        if "buff" in d:
            d["buff"] = {"stat": d["buff"][0], "amount": d["buff"][1], "minutes": d["buff"][2]}
        put("ITEM_" + o["id"].upper(), o["fr"], o["en"])
        if "desc" in o:
            d["desc"] = True
            put("ITEMD_" + o["id"].upper(), o["desc"][0], o["desc"][1])
        out[o["id"]] = d
    return out


def build_crops() -> Dict[str, Any]:
    out = {}
    for row, c in enumerate(I.CROPS):
        cid, fr, en, season, seed_price, sell, days, regrow, shape, col, col2, icon = c
        out[cid] = {"season": season, "days": days, "regrow": regrow, "row": row, "stages": 5,
                    "seed": "seed_" + cid, "flower": cid in I.FLOWERS, "fruit": cid in I.FRUIT_CROPS,
                    "tall": shape == "trellis"}
    return out


def build_fruit_trees() -> Dict[str, Any]:
    return {f[0]: {"season": f[3], "sapling": "sapling_" + f[0]} for f in I.FRUIT_TREES}


def build_fish() -> Dict[str, Any]:
    fish = {}
    for f in I.FISH:
        fid, fr, en, price, place, seasons, hours, weather, diff, shape, back, belly = f
        fish[fid] = {"place": place, "seasons": list(seasons), "hours": list(hours), "weather": weather, "difficulty": diff}
    pots: Dict[str, list] = {}
    for p in I.POT_CATCH:
        pots.setdefault(p[4], []).append(p[0])
    return {"fish": fish, "pot": pots}


def build_recipes() -> Dict[str, Any]:
    craft = {}
    for out_id, n, ins, unlock in I.CRAFTS:
        craft[out_id] = {"n": n, "in": ins, "unlock": unlock}
    cook = {}
    for d in I.DISHES:
        cook[d[0]] = {"n": 1, "in": d[8], "unlock": W.DISH_UNLOCKS.get(d[0], "start")}
    missing = [d[0] for d in I.DISHES if d[0] not in W.DISH_UNLOCKS]
    assert not missing, "plats sans déblocage : %s" % missing
    return {"craft": craft, "cook": cook}


def build_skills() -> Dict[str, Any]:
    """Par compétence et niveau : recettes débloquées + bonus."""
    out: Dict[str, Any] = {}
    rec = build_recipes()
    for skill in ("farming", "husbandry", "fishing", "mining", "combat", "foraging"):
        levels: Dict[str, Any] = {}
        for lvl in range(1, 11):
            entry: Dict[str, Any] = {"recipes": [], "perk": W.PERKS.get(skill, {}).get(str(lvl))}
            for kind in ("craft", "cook"):
                for rid, r in rec[kind].items():
                    if r["unlock"] == "skill:%s:%d" % (skill, lvl):
                        entry["recipes"].append(rid)
            levels[str(lvl)] = entry
            if lvl >= 2:
                assert entry["recipes"] or entry["perk"], "niveau sans récompense : %s %d" % (skill, lvl)
        out[skill] = levels
    for k, (fr, en) in PERK_TEXT.items():
        put("PERK_" + k.upper(), fr, en)
    return out


PERK_TEXT = {
    "crop_quality": ("Récoltes de meilleure qualité", "Better crop quality"),
    "crop_price": ("Récoltes vendues plus cher", "Crops sell for more"),
    "affection_gain": ("Les animaux s'attachent plus vite", "Animals bond faster"),
    "animal_price": ("Produits animaux vendus plus cher", "Animal products sell for more"),
    "product_quality": ("Produits animaux de meilleure qualité", "Better animal product quality"),
    "fish_window": ("Fenêtre de ferrage élargie", "Wider hooking window"),
    "bait_saver": ("Chance de garder son appât", "Chance to keep your bait"),
    "fish_quality": ("Poissons de meilleure qualité", "Better fish quality"),
    "treasure_chance": ("Plus de trésors repêchés", "More fished-up treasure"),
    "fish_price": ("Poissons vendus plus cher", "Fish sell for more"),
    "ore_bonus": ("Chance de minerai en double", "Chance for double ore"),
    "gem_chance": ("Gemmes dans les rochers ordinaires", "Gems in ordinary rocks"),
    "ladder_chance": ("Échelles plus faciles à trouver", "Ladders are easier to find"),
    "mineral_price": ("Minéraux vendus plus cher", "Minerals sell for more"),
    "max_health": ("Santé maximale augmentée", "Maximum health increased"),
    "damage": ("Dégâts augmentés", "Damage increased"),
    "crit_chance": ("Chance de coup critique", "Critical hit chance"),
    "defense": ("Défense augmentée", "Defense increased"),
    "double_forage": ("Chance de cueillette double", "Chance for double forage"),
    "wood_bonus": ("Plus de bois par arbre", "More wood per tree"),
    "forage_quality": ("Cueillette de meilleure qualité", "Better forage quality"),
    "forage_price": ("Cueillette vendue plus cher", "Forage sells for more"),
}


def main() -> int:
    for k, (fr, en) in S.UI.items():
        put(k, fr, en)
    dump("items", build_items())
    dump("crops", build_crops())
    dump("fruit_trees", build_fruit_trees())
    dump("fish", build_fish())
    dump("recipes", build_recipes())
    dump("skills", build_skills())
    dump("terrains", {t["id"]: t for t in gen_tiles.TERRAINS})
    dump("balance", W.BALANCE)
    dump("tools", {"kinds": W.TOOL_KINDS, "areas": W.AREAS, "upgrades": W.TOOL_UPGRADES, "start_items": W.START_ITEMS})
    dump("objects", {"world": W.OBJECTS, "place": W.PLACEABLES, "gems": W.GEM_WEIGHTS})
    dump("machines", W.MACHINES)
    dump("animals", W.ANIMALS)
    dump("buildings", W.BUILDINGS)
    dump("shops", W.SHOPS)
    dump("weather", W.WEATHER)
    dump("monsters", W.MONSTERS)
    dump("mine", W.MINE)
    dump("house", W.HOUSE)
    # modules ajoutés au fil des phases
    for mod_name in ("strings_ui", "npcs", "story", "maps_text"):
        mod = opt(mod_name)
        if mod is not None:
            for table, obj in mod.tables().items():
                dump(table, obj)
            for k, (fr, en) in mod.strings().items():
                put(k, fr, en)
    path = os.path.join(ROOT, "i18n", "strings.csv")
    with open(path, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(["keys", "fr", "en"])
        for k in sorted(STR):
            w.writerow([k, STR[k][0], STR[k][1]])
    print("données : %d objets, %d cultures, %d poissons, %d recettes, %d clés de traduction" % (
        len(registry.all_items()), len(I.CROPS), len(I.FISH) + len(I.POT_CATCH), len(I.CRAFTS) + len(I.DISHES), len(STR)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
