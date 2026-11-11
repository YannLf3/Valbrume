"""Cartes du monde : ferme et intérieurs de la maison (les autres cartes s'ajoutent en P3).

Sortie : data/maps/<id>.json + data/maps/index.json, et un aperçu PNG par carte
dans assets/contact/map_<id>.png.

Format d'une carte
  rows      lignes de symboles de terrain (voir data/terrains.json)
  statics   décors fixes : s (sprite), x, y, w, h (emprise en cases), solid, door [x, y]
  objects   objets initiaux modifiables : t (type), x, y + paramètres
  warps     passages : x, y, w, h, to, spot, face (0 bas, 1 haut, 2 droite, 3 gauche)
  spots     points nommés [x, y] (arrivées, lits…)
  interact  zones d'interaction : x, y, w, h, kind
Un sprite est centré sur son emprise, son bas aligné sur le bas de l'emprise.
"""
import json
import math
import os
import sys
from typing import Dict, List, Optional, Tuple

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

from px import rng_for  # noqa: E402

OUT = os.path.join(ROOT, "data", "maps")
from mapkit import M, T  # noqa: E402


# --------------------------------------------------------------------------- ferme
def farm() -> M:
    W, H = 64, 52
    m = M("farm", W, H, ".", outdoor=True, farmable=True, biome="farm", name="MAP_FARM", music="season")
    r = rng_for("farm")
    # falaise nord, irrégulière
    for x in range(W):
        d = 3 + int(round(1.6 * math.sin(x * 0.37) + 1.2 * math.sin(x * 0.11 + 1.0)))
        for y in range(max(2, min(5, d))):
            m.set(x, y, "^")
    # mare à l'ouest : berge de sable puis eau
    m.ellipse(9, 35, 7.8, 6.3, ":")
    m.ellipse(9, 35, 6.0, 4.5, "~")
    # chemins : porte → sortie sud, et route de l'est
    for y in range(11, H):
        for x in (28, 29):
            m.set(x, y, "=")
    for x in range(28, W):
        for y in (13, 14):
            m.set(x, y, "=")
    m.rect(26, 11, 6, 2, "#")
    # maison de départ
    # la maison est dessinée à l'exécution (taille selon le niveau) ; sa porte reste en (28, 10)
    m.block(25, 8, 7, 3)
    m.warp(28, 10, 1, 1, "farmhouse", "door", 1)
    # coffre d'expédition, boîte aux lettres, puits
    m.static("shipping_bin", 32, 12, 2, 1)
    m.zone(32, 12, 2, 1, "bin")
    m.static("mailbox", 25, 12, 1, 1)
    m.zone(25, 12, 1, 1, "mailbox")
    m.static("well", 22, 16, 2, 1)
    m.zone(22, 16, 2, 1, "well")
    # serre en ruine (reconstruite plus tard par la cloche des Sillons)
    m.static("greenhouse_ruin", 46, 6, 6, 3, not_flag="greenhouse_built")
    m.static("greenhouse", 46, 6, 6, 3, door=(49, 8), flag="greenhouse_built")
    m.warp(49, 8, 1, 1, "greenhouse_in", "door", 1)
    m.warps[-1]["flag"] = "greenhouse_built"
    # emplacements des bâtiments d'élevage (construits chez le charpentier)
    m.meta["lots"] = {"coop": {"x": 36, "y": 6, "w": 4, "h": 3}, "barn": {"x": 51, "y": 15, "w": 5, "h": 3},
                      "silo": {"x": 60, "y": 15, "w": 2, "h": 2}}
    for lot in m.meta["lots"].values():
        m.block(lot["x"] - 1, lot["y"] - 1, lot["w"] + 2, lot["h"] + 2)
    # sorties
    m.warp(63, 12, 1, 4, "village", "farm_east", 3)
    m.warp(27, 51, 4, 1, "forest", "farm_south", 1)
    m.spots = {"house_door": [28, 11], "village_in": [62, 13], "forest_in": [28, 50], "coop_door": [38, 9], "barn_door": [53, 18],
               "pet": [30, 12]}
    # zones à dégager / décor
    exits = [(x, y) for x in range(60, 64) for y in range(10, 18)] + [(x, y) for x in range(25, 33) for y in range(48, 52)]
    starter = [(x, y) for x in range(30, 40) for y in range(15, 21)]
    keep_clear = set(exits) | set(starter) | {(x, y) for x in range(24, 34) for y in range(8, 15)}

    def ok(x: int, y: int, margin: int = 0) -> bool:
        if (x, y) in keep_clear or not m.free_grass(x, y):
            return False
        for dx in range(-margin, margin + 1):
            for dy in range(-margin, margin + 1):
                if m.get(x + dx, y + dy) in "^~":
                    return False
        return True

    occupied = set()

    def put(t: str, x: int, y: int, w: int = 1, h: int = 1, **kw) -> bool:
        cells = [(x + i, y + j) for i in range(w) for j in range(h)]
        if any((c in occupied) or not ok(*c) for c in cells):
            return False
        occupied.update(cells)
        d = {"t": t, "x": x, "y": y}
        d.update(kw)
        m.objects.append(d)
        return True

    # forêt qui borde la ferme
    tree_kinds = ["oak", "oak", "birch", "pine", "pine"]
    for y in range(H):
        for x in range(W):
            edge = min(x, W - 1 - x, H - 1 - y)
            if edge <= 2 and r.random() < 0.85:
                put("tree", x, y, k=r.choice(tree_kinds), g=2)
            elif edge <= 6 and r.random() < 0.22 and (x < 20 or x > 44 or y > 40):
                put("tree", x, y, k=r.choice(tree_kinds), g=r.choice([1, 2, 2]))
    # le champ : rochers, souches, troncs, mauvaises herbes
    def scatter(n: int, fn) -> None:
        tries = 0
        while n > 0 and tries < 4000:
            tries += 1
            x, y = r.randint(3, W - 4), r.randint(5, H - 4)
            if fn(x, y):
                n -= 1

    scatter(4, lambda x, y: put("rock_big", x, y, 2, 2, hp=8))
    scatter(3, lambda x, y: put("big_log", x, y, 2, 1, hp=8))
    scatter(9, lambda x, y: put("stump", x, y, k=r.choice(["oak", "birch"]), hp=4))
    scatter(70, lambda x, y: put("rock", x, y, hp=2))
    scatter(26, lambda x, y: put("bush", x, y))
    scatter(130, lambda x, y: put("weed", x, y, v=r.randint(0, 2), hp=1))
    # herbes hautes (foin) à l'ouest de la route
    for _ in range(46):
        put("tall_grass", r.randint(3, 16), r.randint(13, 26), hp=1)
    return m


# ---------------------------------------------------------------------- intérieurs
def house(level: int) -> M:
    W, H = {1: (11, 9), 2: (14, 10), 3: (16, 12)}[level]
    m = M("farmhouse_%d" % level, W, H, " ", outdoor=False, interior="house", name="MAP_FARMHOUSE", music="")
    for x in range(W):
        m.set(x, 0, "W")
        m.set(x, 1, "w")
        for y in range(2, H - 1):
            m.set(x, y, "f")
    door = W // 2
    m.set(door, H - 1, "f")
    m.static("door_mat", door, H - 2, 1, 1, solid=False)
    m.warp(door, H - 1, 1, 1, "farm", "house_door", 0)
    m.spots["door"] = [door, H - 2]
    # fenêtres, lit, baromètre, cheminée
    for wx in ([3, 7] if level == 1 else [3, 6, 10] if level == 2 else [3, 7, 12]):
        m.static("window_in", wx, 1, 1, 1, solid=False)
    if level == 1:
        m.static("bed", 1, 2, 2, 2)
        m.zone(1, 2, 2, 2, "bed")
        m.spots["bed"] = [2, 4]
        m.static("fireplace", 8, 2, 2, 1)
        m.static("frog_jar", 5, 2, 1, 1)
        m.zone(5, 2, 1, 1, "forecast")
        m.static("big_table_cloth", 6, 4, 2, 1)
        m.static("stool", 5, 4, 1, 1)
        m.static("stool", 8, 4, 1, 1)
    elif level == 2:
        m.static("bed_double", 1, 2, 3, 2)
        m.zone(1, 2, 3, 2, "bed")
        m.spots["bed"] = [2, 4]
        m.static("kitchen", 10, 2, 3, 1)
        m.zone(10, 2, 3, 1, "kitchen")
        m.static("fireplace", 6, 2, 2, 1)
        m.static("frog_jar", 5, 2, 1, 1)
        m.zone(5, 2, 1, 1, "forecast")
        m.static("big_table_cloth", 8, 5, 2, 1)
        m.static("stool", 7, 5, 1, 1)
        m.static("stool", 10, 5, 1, 1)
        m.static("big_rug_red", 2, 6, 3, 2, solid=False, flat=True)
    else:
        m.static("bed_double", 1, 2, 3, 2)
        m.zone(1, 2, 3, 2, "bed")
        m.spots["bed"] = [2, 4]
        m.static("kitchen", 12, 2, 3, 1)
        m.zone(12, 2, 3, 1, "kitchen")
        m.static("fireplace", 7, 2, 2, 1)
        m.static("frog_jar", 5, 2, 1, 1)
        m.zone(5, 2, 1, 1, "forecast")
        m.static("shelf_books", 10, 1, 2, 1)
        m.static("desk", 1, 7, 2, 1)
        m.static("big_table_cloth", 9, 6, 2, 1)
        m.static("stool", 8, 6, 1, 1)
        m.static("stool", 11, 6, 1, 1)
        m.static("big_rug_blue", 3, 8, 3, 2, solid=False, flat=True)
    return m


# ------------------------------------------------------------------------- aperçu
def preview(m: M, path: str) -> None:
    from PIL import Image
    import random
    with open(os.path.join(ROOT, "data", "terrains.json"), encoding="utf-8") as f:
        terr = json.load(f)
    by_ch = {t["ch"]: t for t in terr.values()}
    with open(os.path.join(ROOT, "data", "atlas.json"), encoding="utf-8") as f:
        atlas = json.load(f)
    tiles = {}

    def sheet(name: str) -> "Image.Image":
        if name not in tiles:
            tiles[name] = Image.open(os.path.join(ROOT, "assets", "tiles", name + ".png")).convert("RGBA")
        return tiles[name]

    objsheet = Image.open(os.path.join(ROOT, "assets", "sprites", "objects.png")).convert("RGBA")

    def sheet_for(t: Dict) -> str:
        i = t["id"]
        if i == "grass":
            return "grass_spring"
        if i in ("floor", "wall", "wall_low"):
            st = m.meta.get("style", {})
            n = int(st.get("floor" if i == "floor" else "wall", 0))
            return {"floor": "floor_%d" % n, "wall": "wall_%d" % n, "wall_low": "wall_low_%d" % n}[i]
        return i

    img = Image.new("RGBA", (m.w * T, m.h * T), (0, 0, 0, 255))
    rnd = random.Random(1)
    for y in range(m.h):
        for x in range(m.w):
            t = by_ch.get(m.g[y][x], terr["void"])
            if t["id"] == "water":
                img.alpha_composite(sheet("water").crop((0, 0, T, T)), (x * T, y * T))
                continue
            mask, lows = 0, []
            for bit, (dx, dy) in ((1, (0, -1)), (2, (1, 0)), (4, (0, 1)), (8, (-1, 0))):
                nt = by_ch.get(m.get(x + dx, y + dy), terr["void"]) if m.inb(x + dx, y + dy) else t
                if nt["prio"] >= t["prio"]:
                    mask |= bit
                else:
                    lows.append(nt)
            if mask != 15:
                if lows:
                    u = min(lows, key=lambda q: q["prio"])
                else:
                    u = terr.get(t.get("under", t["id"]), t)
                if u["id"] == "water":
                    img.alpha_composite(sheet("water").crop((0, 0, T, T)), (x * T, y * T))
                else:
                    img.alpha_composite(sheet(sheet_for(u)).crop((0, 4 * T, T, 5 * T)), (x * T, y * T))
                s = sheet(sheet_for(t))
                img.alpha_composite(s.crop(((mask % 4) * T, (mask // 4) * T, (mask % 4) * T + T, (mask // 4) * T + T)), (x * T, y * T))
            else:
                v = rnd.randint(0, 3)
                img.alpha_composite(sheet(sheet_for(t)).crop((v * T, 4 * T, v * T + T, 5 * T)), (x * T, y * T))
    items = []
    for s in m.statics:
        if s.get("flag"):
            continue
        if s["s"] in atlas:
            items.append((s["s"], s["x"], s["y"], s["w"], s["h"], s.get("flat", False) or s["s"] in ("door_mat", "window_in")))
    for o in m.objects:
        nm = {"weed": "weed_%d" % o.get("v", 0), "rock": "rock_small", "rock_big": "rock_big", "big_log": "big_log",
              "stump": "stump_" + o.get("k", "oak"), "bush": "bush", "tall_grass": "tall_grass",
              "tree": "tree_%s_spring_%d" % (o.get("k", "oak"), o.get("g", 2))}.get(o["t"])
        if nm:
            items.append((nm, o["x"], o["y"], {"rock_big": 2, "big_log": 2}.get(o["t"], 1), {"rock_big": 2}.get(o["t"], 1), False))
    items.sort(key=lambda i: (i[5] is False, i[2] + i[4]))
    for nm, x, y, w, h, flat in items:
        a = atlas[nm]
        spr = objsheet.crop((a["x"], a["y"], a["x"] + a["w"], a["y"] + a["h"]))
        img.alpha_composite(spr, (int(x * T + w * T / 2 - a["w"] / 2), (y + h) * T - a["h"]))
    img.save(path)


def main() -> int:
    os.makedirs(OUT, exist_ok=True)
    from gen_maps_world import all_world_maps
    maps = [farm(), house(1), house(2), house(3)] + all_world_maps()
    index = []
    for m in maps:
        with open(os.path.join(OUT, m.id + ".json"), "w", encoding="utf-8", newline="\n") as f:
            json.dump(m.to_json(), f, ensure_ascii=False, separators=(",", ":"))
        index.append(m.id)
        cdir = os.path.join(ROOT, "assets", "contact")
        os.makedirs(cdir, exist_ok=True)
        if os.path.exists(os.path.join(ROOT, "assets", "sprites", "objects.png")):
            preview(m, os.path.join(cdir, "map_%s.png" % m.id))
    with open(os.path.join(OUT, "index.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(index, f)
    print("cartes : %s" % ", ".join("%s %dx%d (%d objets)" % (m.id, m.w, m.h, len(m.objects)) for m in maps))
    return 0


if __name__ == "__main__":
    sys.exit(main())
