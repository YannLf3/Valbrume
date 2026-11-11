"""Assemble la liste complète des objets à partir des tables de items.py."""
from typing import Any, Dict, List

from items import CROPS, DISHES, FISH, FRUIT_TREES, POT_CATCH, SIMPLE, TIERS, TOOLS

SEASON_FR = {"spring": "au printemps", "summer": "en été", "autumn": "en automne", "winter": "en hiver"}
SEASON_EN = {"spring": "spring", "summer": "summer", "autumn": "autumn", "winter": "winter"}


def all_items() -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []

    def add(id_: str, fr: str, en: str, cat: str, price: int, icon: str, **extra: Any) -> None:
        d: Dict[str, Any] = {"id": id_, "fr": fr, "en": en, "cat": cat, "price": price, "icon_spec": icon}
        d.update(extra)
        out.append(d)

    for tid, tfr, ten in TOOLS:
        for lvl, sfr, sen, col in TIERS:
            add("%s_%d" % (tid, lvl), "%s %s" % (tfr, sfr), "%s %s" % (sen, ten), "tool", 0,
                "tool_%s:%s" % (tid, col), tool=tid, level=lvl, stack=1)
    for c in CROPS:
        cid, fr, en, season, seed_price, sell, days, regrow, shape, col, col2, icon = c
        fr_de = "d'" if fr[0].lower() in "aeiouéèêh" else "de "
        add("seed_" + cid, "Graines %s%s" % (fr_de, fr.lower()), "%s Seeds" % en, "seed", max(1, seed_price // 2),
            "seed:%s:%s" % (col, col2), buy=seed_price, crop=cid, season=season)
        energy = max(6, sell // 5)
        add(cid, fr, en, "crop", sell, "c_%s:%s:%s" % (icon, col, col2), energy=energy, season=season)
    for f in FRUIT_TREES:
        fid, fr, en, season, sap_price, price, col, tree_fr, tree_en = f
        add(fid, fr, en, "fruit", price, "fruit_%s:%s:%s" % (fid, col, col), energy=price // 4, season=season)
        add("sapling_" + fid, "Jeune %s" % tree_fr.lower(), "%s Sapling" % tree_en.replace(" Tree", ""), "sapling",
            sap_price // 4, "sapling:%s:leaf" % col, buy=sap_price, tree=fid)
    for f in FISH:
        fid, fr, en, price, place, seasons, hours, weather, diff, shape, back, belly = f
        add(fid, fr, en, "fish", price, "fish_%s:%s:%s" % (shape, back, belly), energy=max(8, price // 6))
    for p in POT_CATCH:
        pid, fr, en, price, place, col = p
        add(pid, fr, en, "fish", price, "pot_%s:%s:cream" % (pid, col), energy=price // 5, pot=True)
    for s in SIMPLE:
        sid, fr, en, cat, price, icon, extra = s
        add(sid, fr, en, cat, price, icon, **extra)
    for d in DISHES:
        did, fr, en, price, icon, energy, health, buff, ingredients = d
        extra: Dict[str, Any] = {"energy": energy, "health": health}
        if buff:
            extra["buff"] = buff
        add(did, fr, en, "dish", price, icon, **extra)
    ids = [o["id"] for o in out]
    assert len(ids) == len(set(ids)), "identifiants d'objets en double : %s" % [i for i in ids if ids.count(i) > 1]
    return out


def icon_index() -> Dict[str, int]:
    return {o["id"]: i for i, o in enumerate(all_items())}
