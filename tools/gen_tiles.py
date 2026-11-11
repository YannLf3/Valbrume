"""Tilesets de terrain.

Chaque terrain produit une feuille 64×80 :
  - lignes 0-3 : 16 tuiles de transition, indexées par masque (N=1, E=2, S=4, O=8 ;
    bit à 1 = le voisin de ce côté est du même terrain ou d'un terrain prioritaire) ;
    la tuile du masque m est en (m % 4, m // 4) ;
  - ligne 4 : 4 variantes pleines.
L'eau est une bande de 4 images d'animation. Les bords « doux » sont transparents :
le terrain inférieur apparaît dessous (deux couches côté moteur).
"""
import os
from typing import Callable, Dict, List, Optional, Tuple

from px import Canvas, rng_for, save

T = 16
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "tiles")

# Définition des terrains : symbole de carte, priorité de recouvrement, bloquant.
# (repris par build_data.py → data/terrains.json)
TERRAINS: List[Dict] = [
    {"id": "water", "ch": "~", "prio": 0, "solid": True, "anim": 4},
    {"id": "dirt", "ch": ",", "prio": 1, "solid": False, "under": "water"},
    {"id": "sand", "ch": ":", "prio": 2, "solid": False, "under": "water"},
    {"id": "path", "ch": "=", "prio": 3, "solid": False, "under": "dirt"},
    {"id": "cobble", "ch": "#", "prio": 4, "solid": False, "under": "dirt"},
    {"id": "wood", "ch": "_", "prio": 5, "solid": False, "under": "water"},
    {"id": "grass", "ch": ".", "prio": 6, "solid": False, "under": "dirt", "seasonal": True},
    {"id": "cliff", "ch": "^", "prio": 7, "solid": True, "under": "dirt"},
    {"id": "mine_floor_1", "ch": "a", "prio": 1, "solid": False, "under": "mine_floor_1"},
    {"id": "mine_floor_2", "ch": "b", "prio": 1, "solid": False, "under": "mine_floor_2"},
    {"id": "mine_floor_3", "ch": "c", "prio": 1, "solid": False, "under": "mine_floor_3"},
    {"id": "mine_wall_1", "ch": "A", "prio": 8, "solid": True, "under": "mine_floor_1"},
    {"id": "mine_wall_2", "ch": "B", "prio": 8, "solid": True, "under": "mine_floor_2"},
    {"id": "mine_wall_3", "ch": "C", "prio": 8, "solid": True, "under": "mine_floor_3"},
    {"id": "floor", "ch": "f", "prio": 1, "solid": False, "under": "floor", "styles": 4},
    {"id": "wall", "ch": "W", "prio": 9, "solid": True, "under": "void", "styles": 4},
    {"id": "wall_low", "ch": "w", "prio": 9, "solid": True, "under": "void", "styles": 4},
    {"id": "void", "ch": " ", "prio": 10, "solid": True, "under": "void"},
]
SEASONS = ["spring", "summer", "autumn", "winter"]

WOB = {
    1: [2, 1, 1, 2, 2, 1, 1, 1, 2, 2, 1, 1, 2, 1, 1, 2],
    2: [1, 2, 2, 1, 1, 1, 2, 1, 1, 2, 2, 1, 1, 2, 1, 1],
    4: [1, 1, 2, 1, 2, 2, 1, 1, 1, 2, 1, 1, 2, 2, 1, 1],
    8: [2, 1, 1, 1, 2, 1, 1, 2, 2, 1, 1, 2, 1, 1, 2, 1],
}


def _opaque_soft(mask: int) -> List[List[bool]]:
    """Forme d'une tuile à bords doux selon le masque."""
    op = [[True] * T for _ in range(T)]
    n, e, s, w = not mask & 1, not mask & 2, not mask & 4, not mask & 8
    for y in range(T):
        for x in range(T):
            if n and y < WOB[1][x]:
                op[y][x] = False
            if s and (T - 1 - y) < WOB[4][x]:
                op[y][x] = False
            if w and x < WOB[8][y]:
                op[y][x] = False
            if e and (T - 1 - x) < WOB[2][y]:
                op[y][x] = False
            if n and w and x + y < 5:
                op[y][x] = False
            if n and e and (T - 1 - x) + y < 5:
                op[y][x] = False
            if s and w and x + (T - 1 - y) < 5:
                op[y][x] = False
            if s and e and (T - 1 - x) + (T - 1 - y) < 5:
                op[y][x] = False
    return op


def soft_tile(texture: Canvas, mask: int, lip: str, lip2: Optional[str] = None) -> Canvas:
    c = Canvas(T, T)
    op = _opaque_soft(mask)
    for y in range(T):
        for x in range(T):
            if not op[y][x]:
                continue
            edge = False
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                xx, yy = x + dx, y + dy
                if 0 <= xx < T and 0 <= yy < T and not op[yy][xx]:
                    edge = True
            if edge:
                c.px(x, y, lip)
            else:
                c.px(x, y, texture.get(x, y))
    if lip2:
        # seconde rangée, côté bas uniquement : donne de l'épaisseur à la berge
        for y in range(T - 1):
            for x in range(T):
                if c.get(x, y) != lip and c.get(x, y) != "void" and c.get(x, y + 1) == lip and not op[min(T - 1, y + 2)][x]:
                    c.px(x, y, lip2)
    return c


def straight_tile(texture: Canvas, mask: int, border: str) -> Canvas:
    c = texture.copy()
    if not mask & 1:
        c.hline(0, 0, T, border)
    if not mask & 4:
        c.hline(0, T - 1, T, border)
    if not mask & 8:
        c.vline(0, 0, T, border)
    if not mask & 2:
        c.vline(T - 1, 0, T, border)
    return c


def wall_tile(top: Canvas, mask: int, rim: str, face: str, face_dark: str, crack: str, seed: str) -> Canvas:
    """Paroi rocheuse : dessus + face visible quand le sud est ouvert."""
    r = rng_for(seed + str(mask))
    c = top.copy()
    if not mask & 1:
        c.hline(0, 0, T, rim)
        c.hline(0, 1, T, rim) if r.random() < 0.0 else None
    if not mask & 8:
        c.vline(0, 0, T, rim)
    if not mask & 2:
        c.vline(T - 1, 0, T, rim)
    if not mask & 4:
        c.rect(0, 8, T, 8, face)
        c.hline(0, 8, T, rim)
        for x in range(T):
            if r.random() < 0.22:
                c.vline(x, 9 + r.randint(0, 2), r.randint(2, 4), crack)
        c.rect(0, 14, T, 2, face_dark)
        if not mask & 8:
            c.vline(0, 8, 8, face_dark)
        if not mask & 2:
            c.vline(T - 1, 8, 8, face_dark)
    return c


def speckled(name: str, base: str, specks: List[Tuple[str, float]], variant: int = 0,
             tufts: Optional[Tuple[str, int]] = None) -> Canvas:
    r = rng_for("%s#%d" % (name, variant))
    c = Canvas(T, T, base)
    for col, dens in specks:
        for y in range(T):
            for x in range(T):
                if r.random() < dens:
                    c.px(x, y, col)
    if tufts:
        col, n = tufts
        for _ in range(n):
            x, y = r.randint(1, T - 3), r.randint(2, T - 2)
            c.px(x, y, col)
            c.px(x + 1, y - 1, col)
            if r.random() < 0.5:
                c.px(x + 2, y, col)
    return c


def grass_texture(season: str, variant: int) -> Canvas:
    r = rng_for("grassdeco%s%d" % (season, variant))
    if season == "spring":
        c = speckled("grass_spring", "leaf_l", [("lime", 0.05)], variant, ("leaf", 5))
        if variant in (1, 3):
            for _ in range(2):
                x, y = r.randint(2, 13), r.randint(2, 13)
                c.px(x, y, r.choice(["white", "yellow", "rose"]))
                c.px(x, y + 1, "leaf")
    elif season == "summer":
        c = speckled("grass_summer", "leaf", [("leaf_d", 0.04)], variant, ("leaf_l", 6))
        if variant == 2:
            x, y = r.randint(2, 13), r.randint(2, 13)
            c.px(x, y, "yellow")
    elif season == "autumn":
        c = speckled("grass_autumn", "amber", [("straw", 0.30), ("leaf_l", 0.12)], variant, ("orange", 4))
        if variant in (1, 2, 3):
            for _ in range(variant):
                x, y = r.randint(1, 13), r.randint(1, 13)
                col = r.choice(["orange", "rust", "amber"])
                c.px(x, y, col)
                c.px(x + 1, y, col)
    else:
        c = speckled("grass_winter", "frost", [("white", 0.10)], variant, ("ice", 4))
    return c


GRASS_LIP = {"spring": ("leaf", "leaf_d"), "summer": ("leaf_d", "leaf_dd"),
             "autumn": ("orange", "rust"), "winter": ("ice", "sky")}


def cobble_texture(variant: int) -> Canvas:
    r = rng_for("cobble%d" % variant)
    c = Canvas(T, T, "stone")
    y = 0
    row = 0
    while y < T:
        h = 4
        x = -2 if row % 2 else 0
        while x < T:
            w = r.choice([4, 5, 5, 6])
            col = r.choice(["stone_l", "stone_l", "stone_l", "silver"])
            c.rect(x + 1, y + 1, w - 1, h - 1, col)
            c.px(x + 1, y + 1, "silver" if col == "stone_l" else "white")
            x += w
        y += h
        row += 1
    return c


def wood_texture(variant: int, base: str = "wood", line: str = "bark", hi: str = "wood_l") -> Canvas:
    r = rng_for("wood%d%s" % (variant, base))
    c = Canvas(T, T, base)
    for y in range(0, T, 4):
        c.hline(0, y + 3, T, line)
        for x in range(T):
            if r.random() < 0.18:
                c.px(x, y + 1, hi)
        j = r.randint(0, T - 1) if variant % 2 == 0 else (y * 3 + 5) % T
        c.vline(j, y, 3, line)
        c.px((j + 1) % T, y + 1, hi)
    return c


def water_frames() -> Canvas:
    out = Canvas(T * 4, T)
    r = rng_for("water")
    dashes = [(r.randint(0, 15), r.randint(1, 14), r.randint(2, 4)) for _ in range(5)]
    for f in range(4):
        c = Canvas(T, T, "sky")
        rr = rng_for("waterbase")
        for y in range(T):
            for x in range(T):
                if rr.random() < 0.08:
                    c.px(x, y, "blue")
        for (x, y, n) in dashes:
            xx = (x + f * 2) % T
            for i in range(n):
                c.px((xx + i) % T, y, "ice")
            c.px((xx + n) % T, (y + 1) % T, "blue")
        if f % 2 == 0:
            c.px((3 + f * 4) % T, 7, "frost")
        out.blit(c, f * T, 0)
    return out


def tilled_texture(wet: bool, variant: int) -> Canvas:
    base, hi, lo = ("bark_d", "soil_d", "ink2") if wet else ("soil_d", "soil", "bark_d")
    r = rng_for("tilled%d%d" % (wet, variant))
    c = Canvas(T, T, base)
    for y in range(1, T, 4):
        c.hline(0, y, T, hi)
        c.hline(0, y + 2, T, lo)
        for x in range(T):
            if r.random() < 0.2:
                c.px(x, y, base)
            if wet and r.random() < 0.05:
                c.px(x, y + 1, "navy")
    return c


def floor_texture(style: int, variant: int) -> Canvas:
    if style == 0:
        return wood_texture(variant, "wood_l", "wood", "straw")
    if style == 1:
        return wood_texture(variant, "bark", "bark_d", "wood")
    r = rng_for("floor%d%d" % (style, variant))
    a, b, g = ("orange", "rust", "bark") if style == 2 else ("stone", "stone_l", "stone_d")
    c = Canvas(T, T, g)
    for j in range(2):
        for i in range(2):
            col = a if (i + j) % 2 == 0 else b
            c.rect(i * 8, j * 8, 7, 7, col)
            if r.random() < 0.5:
                c.px(i * 8 + r.randint(1, 5), j * 8 + r.randint(1, 5), b if col == a else a)
    return c


WALLPAPER = [("cream", "straw", "sand"), ("sky", "blue", "ice"), ("leaf_l", "leaf", "lime"), ("blush", "rose", "cream")]


def wall_textures(style: int) -> Tuple[Canvas, Canvas]:
    base, pat, hi = WALLPAPER[style]
    up = Canvas(T, T, base)
    low = Canvas(T, T, base)
    for c in (up, low):
        if style == 0:
            for x in range(1, T, 4):
                c.vline(x, 0, T, pat)
        elif style == 1:
            for y in range(1, T, 4):
                for x in range((y // 4 % 2) * 2 + 1, T, 4):
                    c.px(x, y, pat)
                    c.px(x, y + 1, hi)
        elif style == 2:
            for y in range(0, T, 8):
                for x in range(0, T, 8):
                    c.px(x + 3, y + 1, pat)
                    c.px(x + 2, y + 2, pat)
                    c.px(x + 4, y + 2, pat)
                    c.px(x + 3, y + 3, hi)
        else:
            for y in range(2, T, 6):
                for x in range((y // 6 % 2) * 4, T, 8):
                    c.px(x + 1, y, pat)
                    c.px(x, y + 1, pat)
                    c.px(x + 2, y + 1, pat)
                    c.px(x + 1, y + 1, hi)
                    c.px(x + 1, y + 2, pat)
    up.hline(0, 0, T, "ink2")
    up.hline(0, 1, T, "bark")
    up.hline(0, 2, T, "wood")
    low.rect(0, 11, T, 5, "wood")
    low.hline(0, 11, T, "wood_l")
    low.hline(0, 15, T, "bark_d")
    low.hline(0, 14, T, "bark")
    return up, low


def build_sheet(mask_fn: Callable[[int], Canvas], variant_fn: Callable[[int], Canvas]) -> Canvas:
    out = Canvas(T * 4, T * 5)
    for m in range(16):
        out.blit(mask_fn(m), (m % 4) * T, (m // 4) * T)
    for v in range(4):
        out.blit(variant_fn(v), v * T, 4 * T)
    return out


def generate() -> Dict[str, Canvas]:
    sheets: Dict[str, Canvas] = {}
    sheets["water"] = water_frames()

    dirt = lambda v: speckled("dirt", "soil_l", [("soil", 0.07), ("sand", 0.02)], v)
    sheets["dirt"] = build_sheet(lambda m: soft_tile(dirt(m % 4), m, "soil", "soil_d"), dirt)
    sand = lambda v: speckled("sand", "sand", [("cream", 0.08), ("soil_l", 0.02)], v)
    sheets["sand"] = build_sheet(lambda m: soft_tile(sand(m % 4), m, "soil_l"), sand)
    path = lambda v: speckled("path", "wood_l", [("straw", 0.10), ("wood", 0.04)], v)
    sheets["path"] = build_sheet(lambda m: soft_tile(path(m % 4), m, "wood"), path)
    sheets["cobble"] = build_sheet(lambda m: straight_tile(cobble_texture(m % 4), m, "stone_d"), cobble_texture)
    sheets["wood"] = build_sheet(lambda m: straight_tile(wood_texture(m % 4), m, "bark_d"), wood_texture)
    for s in SEASONS:
        lip, lip2 = GRASS_LIP[s]
        sheets["grass_" + s] = build_sheet(
            (lambda s_, lip_, lip2_: lambda m: soft_tile(grass_texture(s_, m % 4), m, lip_, lip2_))(s, lip, lip2),
            (lambda s_: lambda v: grass_texture(s_, v))(s))

    cliff_top = lambda v: speckled("cliff", "stone", [("stone_l", 0.08), ("stone_d", 0.04)], v)
    sheets["cliff"] = build_sheet(
        lambda m: wall_tile(cliff_top(m % 4), m, "stone_l", "stone_d", "ink2", "ink2", "cliff"), cliff_top)

    mine = [
        ("soil", [("soil_d", 0.08), ("soil_l", 0.03)], "bark_d", [("soil_d", 0.10)], "soil", "soil_d", "bark_d", "ink"),
        ("stone_l", [("ice", 0.08), ("stone", 0.05)], "stone_d", [("stone", 0.08), ("navy", 0.04)], "ice", "stone", "stone_d", "navy"),
        ("plum", [("ink2", 0.10), ("violet", 0.03)], "ink", [("ink2", 0.10), ("plum", 0.03)], "violet", "ink2", "ink", "plum"),
    ]
    for i, (fb, fs, wb, ws, rim, face, face_d, crack) in enumerate(mine, start=1):
        fl = (lambda fb_, fs_, i_: lambda v: speckled("minefloor%d" % i_, fb_, fs_, v))(fb, fs, i)
        sheets["mine_floor_%d" % i] = build_sheet(fl, fl)
        wt = (lambda wb_, ws_, i_: lambda v: speckled("minewall%d" % i_, wb_, ws_, v))(wb, ws, i)
        sheets["mine_wall_%d" % i] = build_sheet(
            (lambda wt_, rim_, face_, fd_, cr_, i_: lambda m: wall_tile(wt_(m % 4), m, rim_, face_, fd_, cr_, "mine%d" % i_))(wt, rim, face, face_d, crack, i),
            wt)

    for wet in (False, True):
        name = "tilled_wet" if wet else "tilled"
        sheets[name] = build_sheet(
            (lambda wet_: lambda m: soft_tile(tilled_texture(wet_, m % 4), m, "ink2" if wet_ else "bark_d"))(wet),
            (lambda wet_: lambda v: tilled_texture(wet_, v))(wet))

    for st in range(4):
        fl2 = (lambda st_: lambda v: floor_texture(st_, v))(st)
        sheets["floor_%d" % st] = build_sheet(fl2, fl2)
        up, low = wall_textures(st)
        sheets["wall_%d" % st] = build_sheet(lambda m, up_=up: up_, lambda v, up_=up: up_)
        sheets["wall_low_%d" % st] = build_sheet(lambda m, low_=low: low_, lambda v, low_=low: low_)
    void = Canvas(T, T, "ink")
    sheets["void"] = build_sheet(lambda m: void, lambda v: void)
    return sheets


def main() -> int:
    sheets = generate()
    for name, c in sheets.items():
        save(c, os.path.join(OUT, name + ".png"))
    return sum((c.w // T) * (c.h // T) for c in sheets.values())


if __name__ == "__main__":
    print("tuiles : %d" % main())
