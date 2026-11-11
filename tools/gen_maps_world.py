"""Cartes de la phase P3 : village d'Ormelune, forêt, lac, plage et intérieurs (commerces, maisons)."""
import math
import os
import sys
from typing import Callable, Dict, List, Optional, Set, Tuple

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from mapkit import M  # noqa: E402
from px import rng_for  # noqa: E402


class Pop:
    """Placement d'objets modifiables sur de l'herbe libre."""

    def __init__(self, m: M, r, keep: Optional[Set[Tuple[int, int]]] = None):
        self.m, self.r, self.occ, self.keep = m, r, set(), keep or set()

    def ok(self, x: int, y: int) -> bool:
        return (x, y) not in self.keep and (x, y) not in self.occ and self.m.free_grass(x, y)

    def put(self, t: str, x: int, y: int, w: int = 1, h: int = 1, **kw) -> bool:
        cells = [(x + i, y + j) for i in range(w) for j in range(h)]
        if not all(self.ok(*c) for c in cells):
            return False
        self.occ.update(cells)
        d = {"t": t, "x": x, "y": y}
        d.update(kw)
        self.m.objects.append(d)
        return True

    def scatter(self, n: int, fn: Callable[[int, int], bool], x0: int, y0: int, x1: int, y1: int) -> None:
        tries = 0
        while n > 0 and tries < 6000:
            tries += 1
            if fn(self.r.randint(x0, x1), self.r.randint(y0, y1)):
                n -= 1

    def border_trees(self, kinds: List[str], depth: int, chance: float, gaps: List[Tuple[int, int, int, int]]) -> None:
        for y in range(self.m.h):
            for x in range(self.m.w):
                if any(gx0 <= x <= gx1 and gy0 <= y <= gy1 for gx0, gy0, gx1, gy1 in gaps):
                    continue
                edge = min(x, self.m.w - 1 - x, y, self.m.h - 1 - y)
                if edge < depth and self.r.random() < chance:
                    self.put("tree", x, y, k=self.r.choice(kinds), g=2)


def _rect_cells(x: int, y: int, w: int, h: int) -> Set[Tuple[int, int]]:
    return {(i, j) for i in range(x, x + w) for j in range(y, y + h)}


# --------------------------------------------------------------------------- village
VILLAGE_BUILDINGS = [
    # sprite, largeur, x, rangée (y du haut de l'emprise), intérieur, colonne de porte, commerce
    ("b_store", 7, 6, 17, "store", 3, "store"),
    ("b_forge", 6, 15, 17, "forge", 1, "forge"),
    ("b_carpenter", 6, 23, 17, "carpentry", 2, "carpentry"),
    ("b_clinic", 6, 48, 17, "clinic", 2, "clinic"),
    ("b_inn", 8, 56, 17, "inn", 3, "inn"),
    ("b_museum", 7, 66, 17, "museum", 3, ""),
    ("b_ranch", 6, 8, 41, "ranch_shop", 2, "ranch"),
    ("b_fish", 5, 17, 41, "fishshop", 2, "fishshop"),
    ("b_cottage", 5, 26, 41, "cottage", 2, ""),
]


def village() -> M:
    W, H = 80, 60
    m = M("village", W, H, ".", outdoor=True, forage="seasonal", name="MAP_VILLAGE", music="village")
    r = rng_for("village")
    m.rect(28, 22, 24, 17, "#")                       # place pavée
    for x in range(0, W - 3):
        for y in (20, 21):
            m.set(x, y, "=")                           # grand-rue
    for y in range(0, 20):
        for x in (30, 31):
            m.set(x, y, "=")                           # route du lac
    for y in range(39, H):
        for x in (38, 39):
            m.set(x, y, "=")                           # route de la plage
    for x in range(2, 62):
        for y in (44, 45):
            m.set(x, y, "=")                           # rue du sud
    # bâtiments
    for sprite, w, x0, y0, inner, door, shop in VILLAGE_BUILDINGS:
        m.static(sprite, x0, y0, w, 3, door=(x0 + door, y0 + 2))
        dx, dy = x0 + door, y0 + 2
        if shop:
            m.warp_ex(dx, dy, 1, 1, inner, "door", 1, shop=shop)
        else:
            m.warp(dx, dy, 1, 1, inner, "door", 1)
        m.spots["door_" + inner] = [dx, dy + 1]
    # le Carillon (beffroi) : sa porte ouvrira avec le fil rouge
    m.static("belfry", 38, 24, 4, 3)
    m.static("fountain", 39, 30, 3, 2)
    m.static("weather_harp", 46, 25, 1, 1)
    m.zone(46, 25, 1, 1, "forecast", text="FORECAST_HARP")
    m.static("notice_board", 33, 24, 2, 1)
    m.zone(33, 24, 2, 1, "quest_board")
    for x, y in ((29, 23), (50, 23), (29, 37), (50, 37), (36, 21), (44, 21), (20, 21), (60, 21), (36, 45), (42, 45)):
        m.static("lamppost", x, y, 1, 1, light=True)
    m.static("bench", 33, 36, 2, 1)
    m.static("bench", 46, 36, 2, 1)
    for x, y in ((5, 22), (56, 22), (13, 46), (35, 46)):
        m.static("barrel", x, y, 1, 1)
    m.static("crate_apples", 6, 22, 1, 1)
    m.static("crate_greens", 57, 22, 1, 1)
    m.static("stall_red", 31, 34, 3, 1, flag="bell_hearth")
    m.static("stall_blue", 47, 34, 3, 1, flag="bell_hearth")
    m.zone(31, 34, 3, 1, "shop", arg="market")
    m.zone(47, 34, 3, 1, "shop", arg="market")
    # passages
    m.warp(0, 20, 1, 2, "farm", "village_in", 2)
    m.warp(30, 0, 2, 1, "lake", "village_in", 1)
    m.warp_ex(38, 59, 2, 1, "beach", "village_in", 1, need_flag="bell_waves", msg="TOAST_COAST_CLOSED")
    m.spots.update({"farm_east": [1, 20], "lake_in": [30, 2], "beach_in": [38, 57],
                    "plaza_w": [31, 29], "plaza_e": [48, 29], "plaza_n": [35, 28], "fountain_s": [40, 34],
                    "bench_w": [33, 35], "bench_e": [46, 35], "street_w": [12, 22], "street_e": [60, 22],
                    "board": [34, 25], "harp": [46, 26], "inn_front": [59, 22], "forge_front": [16, 22],
                    "store_front": [9, 22], "cottage_front": [28, 46]})
    keep = (_rect_cells(0, 17, W, 6) | _rect_cells(28, 22, 24, 17) | _rect_cells(0, 40, 62, 7) | _rect_cells(28, 0, 6, 20)
            | _rect_cells(36, 38, 6, 22) | _rect_cells(0, 18, 4, 6))
    pop = Pop(m, r, keep)
    pop.border_trees(["oak", "oak", "birch", "pine"], 3, 0.85, [(29, 0, 32, 6), (37, 54, 40, 59), (0, 18, 3, 23)])
    pop.scatter(30, lambda x, y: pop.put("tree", x, y, k=r.choice(["oak", "birch"]), g=2), 2, 2, W - 3, H - 3)
    pop.scatter(24, lambda x, y: pop.put("bush", x, y), 2, 2, W - 3, H - 3)
    pop.scatter(18, lambda x, y: pop.put("rock", x, y, hp=2), 2, 2, W - 3, H - 3)
    return m


# --------------------------------------------------------------------------- forêt
def forest() -> M:
    W, H = 56, 48
    m = M("forest", W, H, ".", outdoor=True, forage="seasonal", name="MAP_FOREST", music="season", gem_biome="1")
    r = rng_for("forest")
    m.ellipse(41, 33, 7.0, 5.5, ":")
    m.ellipse(41, 33, 5.2, 3.8, "~")
    for y in range(0, 15):
        for x in (27, 28):
            m.set(x, y, "=")
    m.rect(22, 15, 12, 9, ",")                          # clairière en terre battue
    m.ellipse(28, 20, 7.0, 5.0, ",")
    m.warp(27, 0, 3, 1, "farm", "forest_in", 1)
    m.spots.update({"farm_south": [28, 2], "glade": [28, 20], "pond": [41, 28], "mushrooms": [13, 35], "glade_w": [24, 20], "glade_e": [33, 20]})
    keep = _rect_cells(26, 0, 4, 16) | {(x, y) for x in range(21, 36) for y in range(15, 26)}
    pop = Pop(m, r, keep)
    kinds = ["oak", "oak", "birch", "pine", "pine", "pine"]
    pop.border_trees(kinds, 4, 0.92, [(26, 0, 30, 3)])
    pop.scatter(240, lambda x, y: pop.put("tree", x, y, k=r.choice(kinds), g=r.choice([1, 2, 2, 2])), 3, 3, W - 4, H - 4)
    pop.scatter(14, lambda x, y: pop.put("stump", x, y, k=r.choice(["oak", "birch"]), hp=4), 3, 3, W - 4, H - 4)
    pop.scatter(6, lambda x, y: pop.put("big_log", x, y, 2, 1, hp=8), 3, 3, W - 4, H - 4)
    pop.scatter(5, lambda x, y: pop.put("rock_big", x, y, 2, 2, hp=8), 3, 3, W - 4, H - 4)
    pop.scatter(34, lambda x, y: pop.put("rock", x, y, hp=2), 3, 3, W - 4, H - 4)
    pop.scatter(40, lambda x, y: pop.put("bush", x, y), 3, 3, W - 4, H - 4)
    pop.scatter(30, lambda x, y: pop.put("weed", x, y, v=r.randint(0, 2), hp=1), 3, 3, W - 4, H - 4)
    for _ in range(30):
        pop.put("tall_grass", r.randint(5, 14), r.randint(28, 40), hp=1)
    return m


# --------------------------------------------------------------------------- lac
def lake() -> M:
    W, H = 56, 44
    m = M("lake", W, H, ".", outdoor=True, forage="seasonal", name="MAP_LAKE", music="season", gem_biome="1")
    r = rng_for("lake")
    for x in range(W):
        d = 5 + int(round(1.4 * math.sin(x * 0.4) + 1.0 * math.sin(x * 0.13 + 2.0)))
        for y in range(max(4, min(7, d))):
            m.set(x, y, "^")
    m.ellipse(28, 24, 19.5, 12.0, ":")
    m.ellipse(28, 24, 17.5, 10.0, "~")
    for y in range(8, H):
        for x in (27, 28):
            if m.get(x, y) not in "~:":
                m.set(x, y, "=")
    for y in range(31, 39):
        for x in (27, 28):
            m.set(x, y, "_")                            # le ponton
    for y in range(7, 14):
        for x in (26, 27, 28):
            m.set(x, y, "=")
    m.static("mine_entrance", 26, 6, 3, 2, door=(27, 7))
    m.warp_ex(27, 7, 1, 1, "mine", "entrance", 1, need_flag="mine_open", msg="TOAST_PATH_CLOSED")
    m.static("boat", 38, 36, 3, 1)
    m.warp(27, 43, 2, 1, "village", "lake_in", 1)
    m.warp_ex(55, 20, 1, 3, "alpage", "village_in", 3, need_flag="bell_flocks", msg="TOAST_ALPAGE_LOCKED")
    m.spots.update({"village_in": [28, 41], "shore_w": [10, 26], "shore_e": [46, 26], "dock": [28, 33], "mine_door": [27, 9],
                    "shore_n": [28, 11]})
    keep = _rect_cells(24, 4, 8, 12) | _rect_cells(26, 36, 4, 8) | _rect_cells(52, 18, 4, 7)
    pop = Pop(m, r, keep)
    pop.border_trees(["oak", "birch", "pine"], 3, 0.8, [(26, 38, 29, 43), (52, 18, 55, 24)])
    pop.scatter(40, lambda x, y: pop.put("tree", x, y, k=r.choice(["oak", "birch", "pine"]), g=2), 2, 8, W - 3, H - 3)
    pop.scatter(18, lambda x, y: pop.put("rock", x, y, hp=2), 2, 8, W - 3, H - 3)
    pop.scatter(3, lambda x, y: pop.put("rock_big", x, y, 2, 2, hp=8), 2, 8, W - 3, H - 3)
    pop.scatter(20, lambda x, y: pop.put("bush", x, y), 2, 8, W - 3, H - 3)
    return m


# --------------------------------------------------------------------------- plage
def beach() -> M:
    W, H = 56, 34
    m = M("beach", W, H, ".", outdoor=True, forage="beach", name="MAP_BEACH", music="season")
    r = rng_for("beach")
    for x in range(W):
        top = 6 + int(round(1.2 * math.sin(x * 0.3)))
        edge = 23 + int(round(1.6 * math.sin(x * 0.27 + 1.0)))
        for y in range(top, H):
            m.set(x, y, "~" if y >= edge else ":")
    for y in range(0, 4):
        for x in (27, 28, 29):
            m.set(x, y, "=")
    for y in range(18, 28):
        for x in (36, 37):
            m.set(x, y, "_")                            # le ponton
    m.static("boat", 18, 20, 3, 1)
    m.warp(27, 0, 4, 1, "village", "beach_in", 1)
    m.spots.update({"village_in": [28, 2], "sand_w": [12, 14], "sand_e": [46, 14], "dock": [36, 21], "boat": [20, 22], "shore": [30, 20]})
    keep = _rect_cells(26, 0, 6, 8) | _rect_cells(16, 18, 7, 6)
    pop = Pop(m, r, keep)
    pop.border_trees(["oak", "pine"], 2, 0.5, [(26, 0, 30, 6)])
    for _ in range(14):
        x, y = r.randint(2, W - 3), r.randint(7, 20)
        if m.get(x, y) == ":" and (x, y) not in keep and (x, y) not in pop.occ:
            pop.occ.add((x, y))
            m.objects.append({"t": "rock", "x": x, "y": y, "hp": 2})
    return m


# --------------------------------------------------------------------------- intérieurs
def room(id_: str, w: int, h: int, wall: int, floor: int) -> M:
    m = M(id_, w, h, " ", outdoor=False, interior="room", style={"wall": wall, "floor": floor}, name="MAP_" + id_.upper(), music="")
    for x in range(w):
        m.set(x, 0, "W")
        m.set(x, 1, "w")
        for y in range(2, h - 1):
            m.set(x, y, "f")
    d = w // 2
    m.set(d, h - 1, "f")
    m.static("door_mat", d, h - 2, 1, 1, solid=False)
    m.warp(d, h - 1, 1, 1, "village", "door_" + id_, 0)
    m.spots["door"] = [d, h - 2]
    for x in range(3, w - 2, 5):
        m.static("window_in", x, 1, 1, 1, solid=False)
    return m


def counter(m: M, x: int, y: int, n: int, shop: str) -> None:
    for i in range(n):
        part = "l" if i == 0 else ("r" if i == n - 1 else "m")
        m.static("counter_" + part, x + i, y, 1, 1)
    m.zone(x, y, n, 1, "shop", arg=shop)
    m.spots["clerk"] = [x + n // 2, y - 1]


def interiors() -> List[M]:
    out: List[M] = []
    m = room("store", 14, 10, 0, 0)
    for x in (1, 3, 9, 11):
        m.static("shelf_store", x, 2, 2, 1)
    counter(m, 5, 4, 4, "store")
    m.static("crate_apples", 1, 6, 1, 1)
    m.static("crate_greens", 2, 6, 1, 1)
    m.static("barrel", 12, 6, 1, 1)
    m.spots.update({"home": [11, 7], "play": [3, 7], "sleep": [12, 8]})
    out.append(m)

    m = room("forge", 12, 10, 3, 3)
    m.static("forge_fire", 8, 2, 2, 1)
    m.static("workbench", 1, 2, 2, 1)
    m.static("shelf_tools", 3, 2, 2, 1)
    m.static("anvil", 8, 5, 1, 1)
    counter(m, 3, 4, 3, "forge")
    m.spots.update({"work": [8, 6], "home": [10, 7]})
    out.append(m)

    m = room("carpentry", 12, 10, 2, 0)
    m.static("workbench", 1, 2, 2, 1)
    m.static("shelf_tools", 3, 2, 2, 1)
    m.static("barrel", 10, 3, 1, 1)
    m.static("crate", 10, 6, 1, 1)
    counter(m, 6, 4, 3, "carpentry")
    m.spots.update({"work": [3, 5], "home": [9, 7]})
    out.append(m)

    m = room("ranch_shop", 12, 10, 0, 1)
    m.static("shelf_ranch", 1, 2, 2, 1)
    m.static("shelf_ranch", 3, 2, 2, 1)
    m.static("barrel", 10, 3, 1, 1)
    m.static("crate", 10, 6, 1, 1)
    counter(m, 5, 4, 3, "ranch")
    m.spots.update({"home": [9, 6], "stool": [3, 6]})
    out.append(m)

    m = room("fishshop", 11, 9, 1, 0)
    m.static("shelf_fish", 1, 2, 2, 1)
    m.static("shelf_fish", 3, 2, 2, 1)
    m.static("barrel", 9, 3, 1, 1)
    counter(m, 6, 4, 3, "fishshop")
    m.spots.update({"home": [8, 6]})
    out.append(m)

    m = room("clinic", 12, 10, 1, 3)
    m.static("hospital_bed", 1, 2, 2, 2)
    m.static("hospital_bed", 4, 2, 2, 2)
    m.static("shelf_med", 8, 2, 2, 1)
    m.zone(1, 2, 2, 2, "heal_bed")
    m.zone(4, 2, 2, 2, "heal_bed")
    m.static("desk", 6, 4, 2, 1)
    m.zone(6, 4, 2, 1, "shop", arg="clinic")
    m.spots.update({"clerk": [7, 3], "home": [9, 7], "bed": [3, 4]})
    out.append(m)

    m = room("inn", 18, 12, 0, 2)
    m.static("kitchen", 1, 2, 3, 1)
    m.static("fireplace", 14, 2, 2, 1)
    counter(m, 7, 4, 5, "inn")
    for x in (3, 8, 13):
        m.static("big_table_cloth", x, 8, 2, 1)
        m.static("stool", x - 1, 8, 1, 1)
        m.static("stool", x + 2, 8, 1, 1)
    m.spots.update({"kitchen": [2, 3], "home": [16, 9], "table_w": [4, 9], "table_e": [14, 9]})
    out.append(m)

    m = room("museum", 16, 12, 0, 3)
    m.static("shelf_books", 1, 2, 2, 1)
    m.static("shelf_books", 3, 2, 2, 1)
    m.static("shelf_books", 5, 2, 2, 1)
    m.static("desk", 11, 3, 2, 1)
    m.static("display_minerals", 3, 6, 2, 1)
    m.static("display_artifacts", 7, 6, 2, 1)
    m.static("display_fish", 11, 6, 2, 1)
    m.zone(3, 6, 2, 1, "museum", arg="minerals")
    m.zone(7, 6, 2, 1, "museum", arg="artifacts")
    m.zone(11, 6, 2, 1, "museum", arg="fish")
    m.static("big_rug_blue", 5, 8, 3, 2, solid=False, flat=True)
    m.spots.update({"desk": [12, 4], "home": [14, 8], "reading": [4, 4]})
    out.append(m)

    m = room("cottage", 10, 8, 3, 0)
    m.static("bed", 1, 2, 2, 2)
    m.static("fireplace", 6, 2, 2, 1)
    m.static("big_table", 4, 4, 2, 1)
    m.static("stool", 3, 4, 1, 1)
    m.static("stool", 6, 4, 1, 1)
    m.static("big_rug_red", 2, 5, 3, 2, solid=False, flat=True)
    m.spots.update({"home": [7, 5], "bed": [2, 4], "hearth": [7, 4]})
    out.append(m)
    return out


def all_world_maps() -> List[M]:
    return [village(), forest(), lake(), beach()] + interiors()
