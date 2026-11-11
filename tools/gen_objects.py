"""Décor du monde : nature, mine, clôtures, bâtiments, mobilier de village et d'intérieur.

Chaque sprite est nommé ; atlas.py les assemble en feuilles et écrit data/atlas.json.
Convention : ancrage en bas à gauche de l'emprise au sol.
"""
from typing import Dict, List, Optional, Tuple

from palette import darker, lighter
from px import Canvas, rng_for

T = 16


# --- nature -----------------------------------------------------------------
def rock(seed: str, w: int, h: int, base: str = "stone", hi: str = "stone_l", lo: str = "stone_d",
         spots: Optional[str] = None) -> Canvas:
    r = rng_for("rock" + seed)
    c = Canvas(w, h)
    g = h - 2
    pts = [(1, g), (1 + r.randint(0, 1), g - h * 0.45), (w * 0.3, 2 + r.randint(0, 2)), (w * 0.65, 1 + r.randint(0, 2)),
           (w - 2, g - h * 0.5), (w - 2, g)]
    c.poly(pts, base)
    c.poly([(w * 0.3, 3 + h * 0.1), (w * 0.6, 3), (w * 0.5, h * 0.45), (w * 0.25, h * 0.5)], hi)
    c.line(w * 0.7, h * 0.3, w - 3, g - 1, lo)
    c.line(3, g, w - 3, g, lo)
    if spots:
        for _ in range(max(3, w // 4)):
            x, y = r.randint(3, w - 5), r.randint(4, h - 5)
            if c.get(x, y) != "void":
                c.rect(x, y, 2, 2, spots)
                c.px(x, y, lighter(spots))
    c.outline()
    return c


def weed(i: int) -> Canvas:
    c = Canvas(T, T)
    cols = [("leaf", "leaf_l"), ("leaf_d", "leaf"), ("wood_l", "straw")][i % 3]
    for k, x in enumerate((4, 6, 8, 10, 12)):
        c.line(8, 14, x, 6 + (k * 3) % 4, cols[k % 2])
    if i == 0:
        c.px(6, 6, "yellow")
    c.outline()
    return c


def bush(berries: Optional[str] = None, snow: bool = False) -> Canvas:
    c = Canvas(T, T)
    c.ellipse(8, 10, 6.5, 4.5, "leaf_d")
    c.ellipse(6, 8, 4, 3.5, "leaf")
    c.ellipse(10, 9, 3.5, 3, "leaf")
    c.ellipse(6, 7, 2, 1.5, "leaf_l")
    if berries:
        for x, y in ((4, 10), (8, 8), (11, 11), (7, 12)):
            c.px(x, y, berries)
    if snow:
        c.ellipse(7, 6.5, 4, 1.5, "white")
        c.px(11, 8, "white")
    c.outline()
    return c


def flowers(col: str) -> Canvas:
    c = Canvas(T, T)
    for x, y in ((4, 11), (8, 8), (12, 12)):
        c.vline(x, y, 3, "leaf")
        c.px(x - 1, y, col)
        c.px(x + 1, y, col)
        c.px(x, y - 1, col)
        c.px(x, y, "yellow")
    c.outline()
    return c


def dig_spot() -> Canvas:
    c = Canvas(T, T)
    c.ellipse(8, 11, 5, 2.5, "soil")
    c.ellipse(7, 10, 3, 1.5, "soil_l")
    c.px(5, 12, "soil_d")
    c.px(10, 12, "soil_d")
    c.px(8, 6, "yellow")
    c.px(8, 5, "white")
    c.px(7, 6, "white")
    c.px(9, 6, "white")
    c.px(8, 7, "white")
    return c


def tall_grass() -> Canvas:
    c = Canvas(T, T)
    for k, x in enumerate((2, 4, 6, 8, 10, 12, 14)):
        c.line(x, 15, x + (k % 3) - 1, 5 + (k * 5) % 4, "leaf" if k % 2 else "leaf_l")
    c.px(5, 5, "straw")
    c.px(11, 4, "straw")
    c.outline()
    return c


def big_log() -> Canvas:
    c = Canvas(32, T)
    c.rect(2, 5, 26, 9, "bark")
    c.rect(2, 5, 26, 2, "wood")
    c.ellipse(27, 9.5, 3, 4.5, "wood_l")
    c.ellipse(27, 9.5, 1.5, 2.5, "straw")
    for x in (7, 14, 20):
        c.vline(x, 8, 4, "bark_d")
    c.px(10, 4, "leaf")
    c.px(11, 3, "leaf_l")
    c.outline()
    return c


# --- mine ---------------------------------------------------------------------
def ladder(down: bool) -> Canvas:
    c = Canvas(T, T)
    if down:
        c.ellipse(8, 9, 6.5, 5, "ink")
        c.ellipse(8, 8, 6.5, 4.5, "ink2")
        c.ellipse(8, 9, 5, 3.5, "ink")
    c.vline(5, 1 if not down else 4, 13 if not down else 9, "wood_l")
    c.vline(10, 1 if not down else 4, 13 if not down else 9, "wood_l")
    for y in range(3 if not down else 5, 13, 3):
        c.hline(5, y, 6, "wood")
    if not down:
        c.outline()
    return c


def elevator() -> Canvas:
    c = Canvas(32, 40)
    c.rect(2, 4, 28, 34, "stone_d")
    c.rect(4, 8, 24, 30, "ink")
    c.frame(2, 4, 28, 34, "bark")
    c.rect(2, 2, 28, 4, "wood")
    c.rect(6, 12, 20, 24, "bark")
    c.frame(6, 12, 20, 24, "wood_l")
    for x in range(9, 25, 4):
        c.vline(x, 13, 22, "wood")
    c.vline(15, 4, 8, "stone_l")
    c.vline(16, 4, 8, "stone_l")
    c.rect(13, 0, 6, 3, "stone")
    c.px(28, 20, "amber")
    c.px(28, 21, "yellow")
    c.outline()
    return c


def mine_entrance() -> Canvas:
    c = Canvas(48, 48)
    c.poly([(2, 46), (4, 18), (14, 6), (34, 6), (44, 18), (46, 46)], "stone")
    c.poly([(8, 20), (16, 9), (30, 9), (24, 16)], "stone_l")
    c.poly([(14, 46), (14, 26), (19, 19), (29, 19), (34, 26), (34, 46)], "ink")
    c.rect(12, 24, 3, 22, "wood")
    c.rect(33, 24, 3, 22, "wood")
    c.rect(11, 20, 26, 4, "wood_l")
    c.hline(11, 23, 26, "bark")
    c.px(24, 14, "amber")
    c.rect(22, 15, 4, 4, "yellow")
    c.frame(21, 14, 6, 6, "bark")
    c.line(38, 30, 42, 44, "stone_d")
    c.line(6, 28, 9, 40, "stone_d")
    c.outline()
    return c


def chest_sprite(opened: bool, col: str = "wood") -> Canvas:
    c = Canvas(T, T)
    c.rect(2, 7, 12, 7, col)
    c.vline(2, 7, 7, darker(col))
    c.vline(13, 7, 7, darker(col))
    if opened:
        c.rect(2, 2, 12, 4, darker(col))
        c.rect(3, 6, 10, 2, "ink")
        c.px(6, 6, "yellow")
        c.px(9, 6, "amber")
    else:
        c.rect(2, 4, 12, 4, lighter(col))
        c.hline(2, 7, 12, darker(col))
        c.rect(7, 6, 2, 3, "amber")
    c.outline()
    return c


def crystal(col: str) -> Canvas:
    c = Canvas(T, T)
    c.poly([(5, 14), (4, 7), (6, 3), (8, 7), (8, 14)], col)
    c.poly([(9, 14), (9, 9), (11, 6), (13, 10), (12, 14)], darker(col))
    c.line(5, 7, 6, 4, lighter(col))
    c.px(11, 8, lighter(col))
    c.outline()
    return c


# --- clôture ------------------------------------------------------------------
def fence(mask: int) -> Canvas:
    c = Canvas(T, 24)
    oy = 8
    if mask & 8:
        c.rect(0, oy + 5, 7, 2, "wood_l")
        c.rect(0, oy + 10, 7, 2, "wood")
    if mask & 2:
        c.rect(9, oy + 5, 7, 2, "wood_l")
        c.rect(9, oy + 10, 7, 2, "wood")
    if mask & 1:
        c.rect(7, 0, 2, oy + 3, "wood")
    if mask & 4:
        c.rect(7, oy + 12, 2, 4, "wood")
    c.rect(6, oy + 1, 4, 14, "wood")
    c.vline(6, oy + 1, 14, "wood_l")
    c.hline(6, oy + 1, 4, "straw")
    c.vline(9, oy + 2, 13, "bark")
    c.outline()
    return c


# --- bâtiments ------------------------------------------------------------------
def _shingles(c: Canvas, x0: int, y0: int, w: int, h: int, col: str, slope: int = 0) -> None:
    """Toit en pente vue de face : rangées de tuiles, bord inférieur ombré."""
    for j in range(h):
        inset = int(slope * (h - 1 - j) / max(1, h - 1))
        row = j // 4
        for i in range(x0 + inset, x0 + w - inset):
            col_px = col
            if j % 4 == 3:
                col_px = darker(col)
            elif (i + row * 3) % 6 == 0:
                col_px = darker(col)
            elif j % 4 == 0 and (i + row * 3) % 6 == 2:
                col_px = lighter(col)
            c.px(i, y0 + j, col_px)


def _window(c: Canvas, x: int, y: int, shutters: Optional[str] = None, w: int = 10, h: int = 11) -> None:
    c.rect(x, y, w, h, "bark")
    c.rect(x + 1, y + 1, w - 2, h - 2, "sky")
    c.rect(x + 1, y + 1, w - 2, 2, "ice")
    c.vline(x + w // 2, y + 1, h - 2, "bark")
    c.hline(x + 1, y + h // 2, w - 2, "bark")
    c.hline(x - 1, y + h, w + 2, "wood_l")
    if shutters:
        c.rect(x - 3, y, 3, h, shutters)
        c.rect(x + w, y, 3, h, shutters)
        c.vline(x - 2, y + 2, h - 4, darker(shutters))
        c.vline(x + w + 1, y + 2, h - 4, darker(shutters))


def _door(c: Canvas, x: int, y: int, col: str = "wood", w: int = 12, h: int = 20) -> None:
    c.rect(x - 1, y - 1, w + 2, h + 1, "bark_d")
    c.rect(x, y, w, h, col)
    c.vline(x + w // 2, y, h, darker(col))
    c.rect(x + 2, y + 2, w // 2 - 3, 6, lighter(col))
    c.rect(x + w // 2 + 2, y + 2, w // 2 - 3, 6, lighter(col))
    c.px(x + w - 3, y + h // 2 + 1, "amber")
    c.px(x + w - 3, y + h // 2 + 2, "yellow")


SIGNS = {
    "basket": [(2, 4, 6, 4, "straw"), (2, 4, 6, 1, "wood"), (4, 2, 2, 2, "wood"), (3, 5, 1, 1, "red"), (6, 6, 1, 1, "leaf")],
    "anvil": [(1, 3, 8, 2, "stone_d"), (3, 5, 4, 2, "stone_d"), (2, 7, 6, 2, "stone_d"), (1, 3, 2, 1, "stone_l")],
    "saw": [(1, 3, 7, 3, "silver"), (8, 2, 2, 5, "wood"), (1, 6, 1, 1, "silver"), (3, 6, 1, 1, "silver"), (5, 6, 1, 1, "silver")],
    "bell": [(3, 2, 4, 5, "amber"), (2, 6, 6, 2, "amber"), (4, 8, 2, 1, "bark"), (4, 3, 1, 3, "yellow")],
    "fish": [(2, 4, 5, 3, "sky"), (7, 3, 2, 5, "sky"), (3, 5, 1, 1, "ink")],
    "cross": [(4, 2, 2, 7, "red"), (2, 4, 6, 2, "red")],
    "mug": [(2, 3, 5, 6, "straw"), (7, 4, 2, 3, "straw"), (2, 3, 5, 2, "white")],
    "eye": [(1, 4, 8, 3, "white"), (4, 4, 2, 3, "violet"), (2, 3, 6, 1, "plum"), (2, 7, 6, 1, "plum")],
}


def _sign(c: Canvas, x: int, y: int, kind: str) -> None:
    c.rect(x + 4, y - 3, 1, 3, "ink2")
    c.rect(x + 9, y - 3, 1, 3, "ink2")
    c.rect(x, y, 14, 13, "bark_d")
    c.rect(x + 1, y + 1, 12, 11, "cream")
    for rx, ry, rw, rh, col in SIGNS[kind]:
        c.rect(x + 2 + rx, y + 1 + ry, rw, rh, col)


def house(wt: int, wall_h: int = 34, roof_h: int = 30, wall: str = "cream", beam: str = "bark", roof: str = "rust",
          door: Optional[float] = None, windows: Tuple[float, ...] = (), shutters: Optional[str] = None,
          chimney: bool = True, sign: Optional[str] = None, gable: bool = False, awning: Optional[str] = None,
          base: str = "stone", upper_windows: Tuple[float, ...] = (), door_col: str = "wood", seed: str = "") -> Canvas:
    w = wt * T
    h = wall_h + roof_h + 8
    c = Canvas(w, h)
    door = int(door) if door is not None else None   # la porte occupe exactement une case
    wy = h - wall_h          # haut du mur
    ry = wy - roof_h + 6     # haut du toit
    r = rng_for("house" + seed + str(wt))
    # mur
    c.rect(2, wy, w - 4, wall_h, wall)
    for x in range(3, w - 3):
        for y in range(wy + 1, h - 5):
            if r.random() < 0.03:
                c.px(x, y, darker(wall))
    c.rect(2, h - 5, w - 4, 5, base)
    for x in range(4, w - 4, 7):
        c.vline(x, h - 5, 5, darker(base))
    c.hline(2, h - 5, w - 4, lighter(base))
    # colombages
    posts = [2, w - 4] + [int(w * k / (wt // 2 + 1)) for k in range(1, wt // 2 + 1)]
    for x in posts:
        c.rect(x, wy, 2, wall_h - 5, beam)
    c.rect(2, wy, w - 4, 2, beam)
    c.rect(2, wy + wall_h // 2 - 2, w - 4, 2, beam)
    ps = sorted(posts)
    for i in range(len(ps) - 1):
        if i % 2 == 0 and ps[i + 1] - ps[i] > 10:
            c.line(ps[i] + 2, wy + wall_h // 2 - 2, ps[i + 1] - 1, wy + 2, beam)
    # toit
    if gable:
        apex = w // 2
        c.poly([(0, wy + 2), (apex, ry - 4), (w - 1, wy + 2)], wall)
        c.line(4, wy, apex, ry, beam)
        c.line(w - 5, wy, apex, ry, beam)
        c.vline(apex, ry, wy - ry, beam)
        c.hline(apex - (wy - ry) // 2, wy - (wy - ry) // 2, wy - ry, beam)
        for k in range(4):
            c.line(0 - 1, wy + 2 - k, apex, ry - 4 - k, roof if k < 3 else darker(roof))
            c.line(w, wy + 2 - k, apex, ry - 4 - k, darker(roof) if k < 3 else darker(roof))
        c.line(0, wy + 3, apex, ry - 3, darker(roof, 2))
        c.line(w - 1, wy + 3, apex, ry - 3, darker(roof, 2))
    else:
        _shingles(c, 0, ry, w, roof_h - 2, roof, slope=6)
        c.hline(6, ry, w - 12, lighter(roof))
        c.hline(0, ry + roof_h - 3, w, darker(roof, 2))
    if chimney:
        cx = w - 22 if not gable else w - 18
        cyy = ry - 6 if not gable else ry + 8
        c.rect(cx, cyy, 8, 14, "stone")
        c.rect(cx - 1, cyy, 10, 3, "stone_l")
        c.vline(cx + 7, cyy + 3, 11, "stone_d")
        c.px(cx + 2, cyy + 6, "stone_d")
        c.px(cx + 4, cyy + 10, "stone_d")
    # ouvertures
    for wx in windows:
        _window(c, int(wx * T) + 3, wy + wall_h // 2 + 2, shutters)
    for wx in upper_windows:
        if gable:
            _window(c, int(wx * T) + 3, wy - 14, shutters, 10, 10)
        else:
            _window(c, int(wx * T) + 3, wy + 4, shutters, 10, 9)
    if door is not None:
        dx = int(door * T) + 2
        _door(c, dx, h - 21, door_col)
        if awning:
            for i in range(-4, 18):
                c.vline(dx + i, h - 28, 4 + (1 if i % 4 < 2 else 0), awning if i % 4 < 2 else "white")
            c.hline(dx - 4, h - 29, 22, darker(awning))
        if sign:
            _sign(c, dx + 16 if dx + 32 < w else dx - 18, h - 34, sign)
    c.outline()
    return c


def coop(level: int) -> Canvas:
    w, h = (64, 60) if level == 1 else (80, 66)
    c = Canvas(w, h)
    wy = h - 30
    c.rect(2, wy, w - 4, 30, "rust")
    for x in range(6, w - 4, 5):
        c.vline(x, wy, 30, "wine")
    c.rect(2, wy, w - 4, 2, "cream")
    c.rect(2, h - 3, w - 4, 3, "stone")
    _shingles(c, 0, wy - 22, w, 22, "wood", slope=8)
    c.hline(8, wy - 22, w - 16, "wood_l")
    c.hline(0, wy - 1, w, "bark_d")
    c.rect(34, h - 18, 12, 18, "bark_d")      # porte centrée sur la case n° 2
    c.rect(35, h - 17, 10, 17, "wood_l")
    c.line(35, h - 17, 44, h - 1, "wood")
    c.rect(8, h - 9, 8, 9, "ink")
    c.frame(7, h - 10, 10, 10, "cream")
    c.poly([(8, h - 1), (16, h - 1), (20, h + 2), (4, h + 2)], "wood")
    _window(c, w - 20, wy + 8, None, 10, 9)
    c.ellipse(w // 2, wy - 9, 4, 4, "cream")
    c.ellipse(w // 2, wy - 9, 2.5, 2.5, "amber")
    c.outline()
    return c


def barn(level: int) -> Canvas:
    w, h = (80, 72) if level == 1 else (112, 78)
    c = Canvas(w, h)
    wy = h - 36
    c.rect(2, wy, w - 4, 36, "red")
    for x in range(7, w - 4, 6):
        c.vline(x, wy, 36, "wine")
    c.rect(2, h - 3, w - 4, 3, "stone")
    apex = w // 2
    c.poly([(0, wy + 1), (10, wy - 16), (apex, wy - 30), (w - 11, wy - 16), (w - 1, wy + 1)], "red")
    for x in range(7, w - 4, 6):
        c.vline(x, wy - 14, 15, "wine")
    for k in range(4):
        c.line(-1, wy + 1 - k, 10, wy - 16 - k, "stone_d")
        c.line(10, wy - 16 - k, apex, wy - 30 - k, "stone_d" if k < 3 else "stone")
        c.line(w, wy + 1 - k, w - 11, wy - 16 - k, "ink2")
        c.line(w - 11, wy - 16 - k, apex, wy - 30 - k, "ink2")
    dw = 26
    c.rect(apex - dw // 2 - 1, h - 27, dw + 2, 27, "cream")
    c.rect(apex - dw // 2, h - 26, dw, 26, "wine")
    c.line(apex - dw // 2, h - 26, apex + dw // 2 - 1, h - 1, "cream")
    c.line(apex + dw // 2 - 1, h - 26, apex - dw // 2, h - 1, "cream")
    c.vline(apex, h - 26, 26, "cream")
    c.rect(apex - 5, wy - 18, 10, 9, "cream")
    c.rect(apex - 4, wy - 17, 8, 7, "ink")
    c.hline(apex - 4, wy - 14, 8, "cream")
    _window(c, 8, wy + 10, None, 9, 9)
    _window(c, w - 18, wy + 10, None, 9, 9)
    c.outline()
    return c


def silo() -> Canvas:
    w, h = 32, 72
    c = Canvas(w, h)
    c.rect(5, 18, 22, 52, "stone_l")
    c.rect(5, 18, 5, 52, "silver")
    c.rect(22, 18, 5, 52, "stone")
    for y in range(24, 70, 9):
        c.hline(5, y, 22, "stone_d")
    c.ellipse(16, 18, 11, 9, "red")
    c.ellipse(13, 15, 5, 4, "rose")
    c.rect(5, 18, 22, 2, "wine")
    c.rect(12, 54, 8, 16, "bark")
    c.rect(13, 55, 6, 15, "wood")
    c.px(16, 6, "stone_d")
    c.vline(16, 3, 6, "stone_d")
    c.outline()
    return c


def greenhouse(ruined: bool = False) -> Canvas:
    w, h = 96, 72
    c = Canvas(w, h)
    wy = h - 34
    glass, glass2 = ("ice", "frost") if not ruined else ("stone", "stone_l")
    c.rect(2, wy, w - 4, 34, glass)
    c.rect(2, h - 6, w - 4, 6, "stone")
    c.poly([(0, wy), (14, wy - 26), (w - 15, wy - 26), (w - 1, wy)], glass)
    for x in range(2, w - 2, 12):
        c.vline(x, wy, 28, "white" if not ruined else "stone_d")
        c.line(x, wy, min(max(14, x + (7 if x < w // 2 else -7)), w - 15), wy - 26, "white" if not ruined else "stone_d")
        if not ruined:
            c.line(x + 3, wy + 4, x + 6, wy + 14, glass2)
    c.hline(0, wy, w, "white" if not ruined else "stone_d")
    c.hline(14, wy - 26, w - 28, "white" if not ruined else "stone_d")
    c.hline(2, wy + 14, w - 4, "white" if not ruined else "stone_d")
    if ruined:
        r = rng_for("ruin")
        for _ in range(9):
            x, y = r.randint(6, w - 12), r.randint(wy - 20, h - 12)
            c.rect(x, y, r.randint(3, 6), r.randint(3, 6), "ink2")
        for x in (8, 30, 70, 84):
            c.line(x, h - 6, x + 3, h - 20, "leaf_d")
            c.px(x + 4, h - 21, "leaf")
    else:
        for x in (10, 26, 62, 78):
            c.rect(x, h - 14, 8, 4, "rust")
            c.ellipse(x + 4, h - 17, 4, 3, "leaf")
            c.px(x + 3, h - 18, "rose")
    _door(c, 50, h - 20, "wood_l")
    c.outline()
    return c


def shipping_bin() -> Canvas:
    c = Canvas(32, 28)
    c.rect(2, 10, 28, 16, "wood")
    for x in (8, 15, 22):
        c.vline(x, 10, 16, "bark")
    c.rect(1, 6, 30, 5, "wood_l")
    c.hline(1, 10, 30, "bark")
    c.rect(1, 6, 30, 1, "straw")
    c.rect(2, 24, 28, 2, "bark")
    c.poly([(16, 13), (20, 17), (17, 17), (17, 21), (15, 21), (15, 17), (12, 17)], "amber")
    c.outline()
    return c


def well() -> Canvas:
    c = Canvas(32, 44)
    c.rect(5, 26, 22, 16, "stone")
    for y in (30, 36):
        c.hline(5, y, 22, "stone_d")
    for x in (10, 17, 23):
        c.vline(x, 26, 16, "stone_d")
    c.ellipse(16, 26, 11, 4, "stone_l")
    c.ellipse(16, 26, 8, 2.5, "navy")
    c.rect(6, 8, 2, 18, "wood")
    c.rect(24, 8, 2, 18, "wood")
    c.poly([(2, 10), (16, 1), (30, 10)], "rust")
    c.line(3, 10, 16, 2, "orange")
    c.hline(8, 14, 16, "bark")
    c.vline(16, 14, 8, "straw")
    c.rect(14, 21, 5, 4, "wood_l")
    c.outline()
    return c


def mailbox() -> Canvas:
    c = Canvas(T, 24)
    c.rect(7, 10, 2, 13, "wood")
    c.rect(3, 4, 10, 7, "blue")
    c.rect(3, 4, 10, 2, "sky")
    c.rect(11, 2, 2, 4, "red")
    c.hline(5, 8, 5, "navy")
    c.outline()
    return c


def belfry() -> Canvas:
    """Le Carillon d'Ormelune : tour de pierre à chambre de cloches ouverte."""
    w, h = 64, 136
    c = Canvas(w, h)
    c.rect(8, 56, 48, 78, "stone_l")
    r = rng_for("belfry")
    for y in range(58, 132, 6):
        c.hline(8, y, 48, "stone")
        for x in range(10 + (y // 6 % 2) * 5, 56, 10):
            c.vline(x, y, 6, "stone")
    c.rect(8, 56, 5, 78, "silver")
    c.rect(50, 56, 6, 78, "stone")
    c.rect(4, 128, 56, 6, "stone_d")
    c.rect(6, 52, 52, 5, "stone_d")
    # chambre des cloches
    c.rect(8, 26, 48, 26, "ink2")
    for x in (8, 22, 38, 52):
        c.rect(x, 24, 4, 28, "stone_l")
        c.vline(x + 3, 24, 28, "stone")
    c.rect(6, 22, 52, 4, "stone_d")
    for x0 in (12, 26, 42):
        c.rect(x0, 26, 10, 2, "bark")
    # flèche
    c.poly([(2, 23), (32, -6), (61, 23)], "navy")
    for k in range(0, 24, 4):
        c.hline(4 + k, 22 - k, 56 - 2 * k, "blue")
    c.line(4, 22, 32, -4, "sky")
    c.vline(32, 0, 3, "amber")
    # porte et cadran
    c.rect(24, 104, 16, 30, "bark_d")
    c.rect(26, 106, 12, 28, "wood")
    c.ellipse(32, 106, 7, 5, "bark_d")
    c.ellipse(32, 107, 5.5, 4, "wood")
    c.vline(32, 104, 30, "bark")
    c.ellipse(32, 78, 9, 9, "cream")
    c.ellipse(32, 78, 9, 9, "bark_d") if False else None
    for a in range(12):
        import math
        c.px(32 + 7 * math.cos(a * math.pi / 6), 78 + 7 * math.sin(a * math.pi / 6), "ink2")
    c.line(32, 78, 32, 72, "ink")
    c.line(32, 78, 36, 80, "ink")
    c.outline()
    return c


def bell_small(lit: bool) -> Canvas:
    c = Canvas(10, 12)
    a, b = ("amber", "yellow") if lit else ("stone_d", "stone")
    c.rect(4, 0, 2, 2, "bark")
    c.poly([(5, 2), (7, 4), (8, 9), (1, 9), (2, 4)], a)
    c.vline(3, 4, 4, b)
    c.hline(1, 9, 8, darker(a))
    c.px(5, 10, darker(a))
    c.outline()
    return c


def lamppost() -> Canvas:
    c = Canvas(T, 40)
    c.rect(7, 12, 2, 26, "ink2")
    c.rect(5, 36, 6, 2, "stone_d")
    c.rect(5, 4, 6, 8, "yellow")
    c.frame(5, 4, 6, 8, "ink2")
    c.poly([(3, 4), (8, 0), (13, 4)], "ink2")
    c.px(7, 7, "white")
    c.px(8, 8, "amber")
    c.outline()
    return c


def bench() -> Canvas:
    c = Canvas(32, 20)
    c.rect(2, 4, 28, 6, "wood")
    c.hline(2, 6, 28, "bark")
    c.rect(2, 11, 28, 3, "wood_l")
    c.rect(3, 14, 2, 5, "bark")
    c.rect(27, 14, 2, 5, "bark")
    c.rect(2, 3, 2, 10, "bark")
    c.rect(28, 3, 2, 10, "bark")
    c.outline()
    return c


def notice_board() -> Canvas:
    c = Canvas(32, 34)
    c.rect(3, 6, 26, 18, "wood")
    c.rect(5, 8, 22, 14, "straw")
    c.rect(4, 22, 3, 11, "bark")
    c.rect(25, 22, 3, 11, "bark")
    c.poly([(1, 7), (16, 1), (31, 7)], "rust")
    for x, y, col in ((7, 10, "white"), (14, 9, "cream"), (20, 11, "white"), (9, 16, "cream"), (17, 16, "blush")):
        c.rect(x, y, 5, 5, col)
        c.px(x + 2, y, "red")
        c.hline(x + 1, y + 2, 3, "stone")
    c.outline()
    return c


def weather_harp() -> Canvas:
    """La Harpe des vents : le support de prévision météo du village."""
    c = Canvas(T, 40)
    c.rect(7, 22, 2, 16, "bark")
    c.rect(4, 36, 8, 2, "stone_d")
    c.poly([(3, 22), (3, 6), (8, 2), (13, 6), (13, 22)], "wood")
    c.poly([(5, 20), (5, 7), (8, 4), (11, 7), (11, 20)], "ink")
    for x in (6, 8, 10):
        c.vline(x, 6, 14, "silver")
    c.px(8, 0, "amber")
    c.rect(6, 23, 4, 4, "cream")
    c.px(7, 24, "sky")
    c.outline()
    return c


def fountain() -> Canvas:
    c = Canvas(48, 44)
    c.ellipse(24, 32, 22, 9, "stone")
    c.ellipse(24, 30, 22, 8, "stone_l")
    c.ellipse(24, 30, 18, 5.5, "sky")
    c.ellipse(20, 29, 6, 1.5, "ice")
    c.rect(21, 12, 6, 18, "stone")
    c.vline(21, 12, 18, "stone_l")
    c.ellipse(24, 12, 8, 3, "stone_l")
    c.ellipse(24, 11, 6, 2, "sky")
    c.rect(23, 4, 2, 7, "ice")
    c.px(22, 6, "frost")
    c.px(26, 7, "frost")
    c.px(18, 20, "ice")
    c.px(30, 22, "ice")
    c.outline()
    return c


def barrel() -> Canvas:
    c = Canvas(T, 20)
    c.rect(3, 4, 10, 14, "wood")
    c.rect(2, 7, 12, 8, "wood")
    c.vline(4, 4, 14, "wood_l")
    c.vline(11, 4, 14, "bark")
    c.hline(3, 6, 10, "stone_d")
    c.hline(3, 15, 10, "stone_d")
    c.ellipse(8, 4, 5, 1.5, "wood_l")
    c.outline()
    return c


def crate(top: Optional[str] = None) -> Canvas:
    c = Canvas(T, 18)
    c.rect(2, 5, 12, 12, "wood_l")
    c.frame(2, 5, 12, 12, "wood")
    c.line(3, 6, 12, 15, "wood")
    if top:
        for x, y in ((4, 4), (7, 3), (10, 4), (6, 5), (9, 5)):
            c.ellipse(x, y, 1.6, 1.6, top)
    c.outline()
    return c


def stall(col: str) -> Canvas:
    c = Canvas(48, 44)
    c.rect(3, 24, 42, 18, "wood")
    c.rect(3, 24, 42, 3, "wood_l")
    for x in (12, 24, 36):
        c.vline(x, 27, 15, "bark")
    c.rect(4, 6, 2, 20, "bark")
    c.rect(42, 6, 2, 20, "bark")
    for i in range(48):
        c.vline(i, 2, 8 + (2 if i % 8 < 4 else 0), col if i % 8 < 4 else "white")
    c.hline(0, 2, 48, darker(col))
    for x, col2 in ((8, "red"), (16, "amber"), (28, "leaf"), (38, "violet")):
        c.ellipse(x, 22, 3, 2.2, col2)
    c.outline()
    return c


def boat() -> Canvas:
    c = Canvas(48, 22)
    c.poly([(2, 8), (46, 8), (40, 20), (8, 20)], "blue")
    c.poly([(2, 8), (46, 8), (44, 11), (4, 11)], "cream")
    c.hline(8, 20, 33, "navy")
    c.rect(10, 5, 28, 3, "wood")
    c.rect(20, 0, 2, 6, "bark")
    c.outline()
    return c


def bunting() -> Canvas:
    c = Canvas(48, T)
    c.line(0, 2, 24, 6, "bark")
    c.line(24, 6, 47, 2, "bark")
    cols = ["red", "amber", "sky", "leaf_l", "rose", "violet"]
    for i in range(6):
        x = 3 + i * 8
        y = 3 + (2 if 1 <= i <= 4 else 0) + (1 if i in (2, 3) else 0)
        c.poly([(x, y), (x + 5, y), (x + 2, y + 6)], cols[i])
    return c


def snowman() -> Canvas:
    c = Canvas(T, 28)
    c.ellipse(8, 20, 6, 6, "white")
    c.ellipse(8, 10, 4.5, 4.5, "white")
    c.ellipse(10, 22, 3, 3, "frost")
    c.px(6, 9, "ink")
    c.px(9, 9, "ink")
    c.px(8, 11, "orange")
    c.px(9, 11, "orange")
    c.hline(4, 14, 9, "red")
    c.rect(5, 2, 6, 4, "ink2")
    c.hline(3, 6, 10, "ink2")
    c.px(8, 18, "ink2")
    c.px(8, 21, "ink2")
    c.outline()
    return c


def target() -> Canvas:
    c = Canvas(T, T)
    c.ellipse(8, 8, 7, 7, "white")
    c.ellipse(8, 8, 5, 5, "sky")
    c.ellipse(8, 8, 3, 3, "white")
    c.ellipse(8, 8, 1.2, 1.2, "red")
    c.outline()
    return c


def ribbon(col: str) -> Canvas:
    c = Canvas(T, T)
    c.ellipse(8, 6, 3, 3, col)
    c.px(8, 6, lighter(col))
    c.poly([(6, 8), (4, 14), (7, 12), (8, 9)], darker(col))
    c.poly([(10, 8), (12, 14), (9, 12), (8, 9)], col)
    c.outline()
    return c


# --- intérieur -----------------------------------------------------------------
def bed(double: bool, cover: str = "blue") -> Canvas:
    w = 48 if double else 32
    c = Canvas(w, 38)
    c.rect(2, 2, w - 4, 34, "wood")
    c.rect(2, 2, w - 4, 6, "bark")
    c.rect(4, 8, w - 8, 26, "white")
    for i in range(2 if double else 1):
        px_ = 6 + i * 20 if double else w // 2 - 8
        c.rect(px_, 9, 16, 7, "cream")
        c.hline(px_, 15, 16, "sand")
    c.rect(4, 18, w - 8, 16, cover)
    c.rect(4, 18, w - 8, 3, lighter(cover))
    c.vline(w - 5, 21, 13, darker(cover))
    c.rect(2, 34, w - 4, 2, "bark")
    c.outline()
    return c


def counter(part: str) -> Canvas:
    c = Canvas(T, 22)
    c.rect(0, 6, T, 16, "wood")
    c.rect(0, 2, T, 5, "wood_l")
    c.hline(0, 2, T, "straw")
    c.hline(0, 6, T, "bark")
    c.vline(7, 8, 13, "bark")
    if part == "l":
        c.vline(0, 2, 20, "bark_d")
    if part == "r":
        c.vline(15, 2, 20, "bark_d")
    c.hline(0, 21, T, "bark_d")
    return c


def goods_shelf(kind: str) -> Canvas:
    c = Canvas(32, 40)
    c.rect(1, 2, 30, 36, "bark")
    c.rect(3, 4, 26, 32, "bark_d")
    for y in (13, 24, 35):
        c.hline(3, y, 26, "wood")
    r = rng_for("shelf" + kind)
    pal = {"store": ["red", "amber", "leaf", "cream", "rose", "sky"], "tools": ["stone_l", "stone", "orange", "silver", "wood_l"],
           "fish": ["sky", "teal", "ice", "blue", "straw"], "books": ["red", "blue", "leaf_d", "plum", "amber", "cream"],
           "med": ["white", "ice", "rose", "teal", "frost"], "ranch": ["straw", "cream", "white", "wood_l", "amber"]}[kind]
    for row, y in enumerate((5, 16, 27)):
        x = 4
        while x < 27:
            col = r.choice(pal)
            if kind == "books":
                wd = r.choice([2, 2, 3])
                c.rect(x, y, wd, 8, col)
                c.px(x, y + 2, lighter(col))
            else:
                wd = r.choice([3, 4, 5])
                hh = r.choice([4, 5, 6, 7])
                c.rect(x, y + 8 - hh, wd, hh, col)
                c.px(x, y + 8 - hh, lighter(col))
            x += wd + 1
    c.outline()
    return c


def anvil() -> Canvas:
    c = Canvas(T, 18)
    c.rect(2, 4, 13, 4, "stone_d")
    c.rect(0, 5, 3, 2, "stone_d")
    c.rect(5, 8, 7, 3, "ink2")
    c.rect(3, 11, 11, 3, "stone_d")
    c.rect(4, 14, 9, 3, "bark")
    c.hline(2, 4, 13, "stone_l")
    c.outline()
    return c


def forge_fire() -> Canvas:
    c = Canvas(32, 44)
    c.rect(2, 14, 28, 28, "stone")
    for y in (20, 28, 36):
        c.hline(2, y, 28, "stone_d")
    for x in (9, 16, 23):
        c.vline(x, 14, 28, "stone_d")
    c.rect(7, 24, 18, 16, "ink")
    c.ellipse(16, 24, 9, 6, "ink")
    c.ellipse(16, 36, 7, 4, "orange")
    c.ellipse(16, 35, 4, 3, "amber")
    c.ellipse(16, 34, 2, 2, "yellow")
    c.px(12, 30, "orange")
    c.px(19, 28, "amber")
    c.poly([(6, 14), (10, 2), (22, 2), (26, 14)], "stone_d")
    c.rect(11, 0, 10, 3, "ink2")
    c.outline()
    return c


def workbench() -> Canvas:
    c = Canvas(32, 24)
    c.rect(1, 6, 30, 5, "wood_l")
    c.hline(1, 6, 30, "straw")
    c.rect(3, 11, 3, 12, "wood")
    c.rect(26, 11, 3, 12, "wood")
    c.hline(6, 18, 20, "wood")
    c.rect(6, 2, 8, 4, "silver")
    c.rect(13, 3, 3, 2, "wood")
    c.rect(20, 3, 6, 3, "straw")
    c.px(8, 5, "stone")
    c.outline()
    return c


def big_table(cloth: Optional[str] = None) -> Canvas:
    c = Canvas(32, 26)
    c.rect(1, 4, 30, 12, cloth or "wood_l")
    c.rect(1, 4, 30, 2, lighter(cloth) if cloth else "straw")
    c.rect(1, 16, 30, 3, darker(cloth) if cloth else "wood")
    c.rect(3, 19, 3, 6, "bark")
    c.rect(26, 19, 3, 6, "bark")
    if cloth:
        for x in range(3, 30, 6):
            c.px(x, 10, "white")
    c.outline()
    return c


def stool() -> Canvas:
    c = Canvas(T, T)
    c.ellipse(8, 7, 5, 3, "wood_l")
    c.ellipse(8, 6, 4, 2, "straw")
    c.rect(4, 9, 2, 6, "bark")
    c.rect(10, 9, 2, 6, "bark")
    c.outline()
    return c


def fireplace() -> Canvas:
    c = Canvas(32, 44)
    c.rect(1, 12, 30, 30, "stone_l")
    for y in (18, 26, 34):
        c.hline(1, y, 30, "stone")
    c.rect(0, 9, 32, 4, "wood")
    c.hline(0, 9, 32, "wood_l")
    c.rect(7, 22, 18, 20, "ink")
    c.ellipse(16, 22, 9, 5, "ink")
    c.rect(10, 38, 12, 3, "bark")
    c.poly([(11, 38), (13, 30), (15, 35), (17, 28), (20, 38)], "orange")
    c.poly([(13, 38), (15, 33), (17, 32), (18, 38)], "yellow")
    c.rect(6, 0, 20, 9, "stone")
    c.rect(4, 5, 4, 4, "amber")
    c.rect(24, 4, 3, 5, "leaf")
    c.outline()
    return c


def kitchen() -> Canvas:
    c = Canvas(48, 40)
    c.rect(0, 16, 48, 24, "wood")
    c.rect(0, 12, 48, 5, "stone_l")
    c.hline(0, 12, 48, "silver")
    for x in (16, 32):
        c.vline(x, 17, 23, "bark")
    c.rect(2, 4, 12, 9, "ink2")
    c.rect(4, 6, 8, 3, "stone_d")
    c.ellipse(5, 13, 2, 1, "ink")
    c.ellipse(11, 13, 2, 1, "ink")
    c.rect(4, 22, 8, 12, "ink")
    c.rect(5, 26, 6, 6, "orange")
    c.px(7, 28, "yellow")
    c.rect(20, 13, 9, 3, "ice")
    c.rect(24, 6, 2, 7, "stone")
    c.rect(22, 6, 4, 2, "stone")
    c.rect(36, 6, 3, 7, "leaf")
    c.rect(41, 8, 4, 5, "red")
    c.px(22, 26, "amber")
    c.px(38, 26, "amber")
    c.outline()
    return c


def frog_jar() -> Canvas:
    """La rainette-baromètre : le bulletin météo de la maison."""
    c = Canvas(T, 24)
    c.rect(3, 7, 10, 15, "ice")
    c.rect(3, 7, 2, 15, "frost")
    c.rect(4, 4, 8, 3, "wood")
    c.rect(3, 18, 10, 4, "sky")
    c.vline(9, 9, 12, "wood_l")
    for y in (11, 14, 17):
        c.hline(8, y, 3, "wood_l")
    c.ellipse(7, 13, 2.2, 1.8, "leaf_l")
    c.px(6, 12, "ink")
    c.px(8, 12, "ink")
    c.px(5, 15, "leaf")
    c.outline()
    return c


def display_case(col: str) -> Canvas:
    c = Canvas(32, 28)
    c.rect(1, 12, 30, 15, "bark")
    c.rect(1, 12, 30, 2, "wood")
    c.rect(2, 3, 28, 10, "ice")
    c.frame(2, 3, 28, 10, "wood_l")
    c.line(5, 5, 9, 11, "frost")
    for i, x in enumerate((7, 14, 21)):
        c.rect(x, 8, 4, 4, [col, lighter(col), darker(col)][i])
        c.px(x, 8, "white")
    c.outline()
    return c


def desk() -> Canvas:
    c = Canvas(32, 24)
    c.rect(1, 6, 30, 5, "wood")
    c.hline(1, 6, 30, "wood_l")
    c.rect(2, 11, 9, 12, "wood")
    c.rect(21, 11, 9, 12, "wood")
    c.px(6, 15, "amber")
    c.px(25, 15, "amber")
    c.rect(6, 2, 7, 4, "white")
    c.hline(7, 3, 5, "stone")
    c.rect(20, 1, 3, 5, "blue")
    c.rect(24, 3, 4, 3, "amber")
    c.outline()
    return c


def hospital_bed() -> Canvas:
    c = Canvas(32, 34)
    c.rect(2, 4, 28, 28, "stone_l")
    c.rect(4, 6, 24, 24, "white")
    c.rect(8, 7, 16, 6, "frost")
    c.rect(4, 16, 24, 14, "ice")
    c.rect(4, 16, 24, 2, "frost")
    c.rect(2, 2, 28, 3, "stone")
    c.outline()
    return c


def window_in() -> Canvas:
    c = Canvas(T, T)
    c.rect(2, 3, 12, 10, "wood")
    c.rect(3, 4, 10, 8, "sky")
    c.rect(3, 4, 10, 3, "ice")
    c.vline(8, 4, 8, "wood")
    c.hline(3, 8, 10, "wood")
    c.hline(1, 13, 14, "wood_l")
    return c


def door_mat() -> Canvas:
    c = Canvas(T, T)
    c.rect(1, 9, 14, 6, "rust")
    c.frame(1, 9, 14, 6, "wine")
    c.hline(4, 12, 8, "amber")
    return c


def big_rug(col: str) -> Canvas:
    c = Canvas(48, 32)
    c.rect(1, 1, 46, 30, col)
    c.frame(1, 1, 46, 30, darker(col))
    c.frame(4, 4, 40, 24, lighter(col))
    for x in range(10, 40, 8):
        c.poly([(x, 16), (x + 3, 12), (x + 6, 16), (x + 3, 20)], lighter(col))
    return c


def trough(full: bool) -> Canvas:
    c = Canvas(32, T)
    c.rect(1, 6, 30, 8, "wood")
    c.rect(2, 5, 28, 3, "bark_d")
    if full:
        c.rect(3, 4, 26, 3, "straw")
        for x in range(4, 28, 3):
            c.px(x, 3, "amber")
    c.rect(2, 14, 3, 2, "bark")
    c.rect(27, 14, 3, 2, "bark")
    c.outline()
    return c


def straw_pile() -> Canvas:
    c = Canvas(T, T)
    c.ellipse(8, 11, 7, 4, "straw")
    c.ellipse(7, 9, 4, 2.5, "yellow")
    for x, y in ((3, 12), (9, 13), (12, 10), (6, 11)):
        c.px(x, y, "amber")
    c.outline()
    return c


def scarecrow_big() -> Canvas:
    c = Canvas(T, 32)
    c.rect(7, 8, 2, 23, "wood")
    c.rect(1, 13, 14, 2, "wood")
    c.rect(4, 12, 8, 10, "red")
    c.rect(4, 12, 8, 2, "rose")
    c.rect(4, 20, 8, 2, "wine")
    c.ellipse(8, 7, 3.5, 3.5, "straw")
    c.px(6, 6, "ink")
    c.px(9, 6, "ink")
    c.hline(6, 9, 4, "bark")
    c.poly([(3, 4), (8, 0), (13, 4)], "bark")
    c.hline(2, 4, 12, "wood")
    for x in (1, 14):
        c.px(x, 15, "amber")
        c.px(x, 16, "yellow")
    c.outline()
    return c


def furnace_lit() -> Canvas:
    import gen_icons
    c = gen_icons.render("furnace:stone:yellow")
    c.px(6, 0, "stone_l")
    c.px(7, 0, "silver")
    return c


def generate() -> Dict[str, Canvas]:
    s: Dict[str, Canvas] = {}
    s["rock_small"] = rock("s", 16, 16)
    s["rock_small_2"] = rock("s2", 16, 14)
    s["rock_big"] = rock("b", 32, 28)
    s["node_coal"] = rock("coal", 16, 16, spots="ink")
    s["node_copper"] = rock("cu", 16, 16, spots="orange")
    s["node_iron"] = rock("fe", 16, 16, "stone_d", "stone", "ink2", "silver")
    s["node_silver"] = rock("ag", 16, 16, spots="ice")
    s["node_brumite"] = rock("br", 16, 16, "ink2", "stone_d", "ink", "lilac")
    s["node_gem"] = rock("gem", 16, 16, spots="rose")
    s["mine_rock_1"] = rock("m1", 16, 16, "soil_l", "sand", "soil")
    s["mine_rock_2"] = rock("m2", 16, 16, "stone_l", "frost", "stone")
    s["mine_rock_3"] = rock("m3", 16, 16, "plum", "violet", "ink2")
    for i in range(3):
        s["weed_%d" % i] = weed(i)
    s["bush"] = bush()
    s["bush_berry"] = bush("plum")
    s["bush_snow"] = bush(snow=True)
    for col in ("rose", "white", "violet"):
        s["flowers_" + col] = flowers(col)
    s["big_log"] = big_log()
    s["dig_spot"] = dig_spot()
    s["tall_grass"] = tall_grass()
    s["ladder_down"] = ladder(True)
    s["ladder_up"] = ladder(False)
    s["elevator"] = elevator()
    s["mine_entrance"] = mine_entrance()
    s["chest_closed"] = chest_sprite(False)
    s["chest_open"] = chest_sprite(True)
    s["treasure_closed"] = chest_sprite(False, "plum")
    s["treasure_open"] = chest_sprite(True, "plum")
    for col in ("ice", "violet", "amber"):
        s["crystal_" + col] = crystal(col)
    for m in range(16):
        s["fence_%d" % m] = fence(m)
    # ferme
    s["house_1"] = house(5, 32, 30, door=2.1, windows=(0.4, 3.6), shutters="blue", roof="rust", seed="farm1")
    s["house_2"] = house(6, 34, 32, door=2.6, windows=(0.5, 4.5), shutters="blue", roof="rust", upper_windows=(), gable=False, seed="farm2", awning=None)
    s["house_3"] = house(7, 36, 38, door=3.1, windows=(0.5, 1.7, 5.5), shutters="blue", roof="rust", gable=True, upper_windows=(3.0,), seed="farm3")
    for lv in (1, 2):
        s["coop_%d" % lv] = coop(lv)
        s["barn_%d" % lv] = barn(lv)
    s["silo"] = silo()
    s["greenhouse"] = greenhouse(False)
    s["greenhouse_ruin"] = greenhouse(True)
    s["shipping_bin"] = shipping_bin()
    s["well"] = well()
    s["mailbox"] = mailbox()
    s["scarecrow_big"] = scarecrow_big()
    s["furnace_lit"] = furnace_lit()
    # village
    s["b_store"] = house(7, 36, 32, door=3.1, windows=(0.6, 5.3), shutters="leaf", roof="rust", sign="basket", awning="red", seed="store")
    s["b_forge"] = house(6, 34, 30, wall="stone_l", beam="stone_d", roof="stone_d", door=1.2, windows=(3.8,), sign="anvil", base="stone_d", seed="forge", door_col="bark")
    s["b_carpenter"] = house(6, 34, 34, wall="wood_l", beam="bark", roof="leaf_d", door=2.6, windows=(0.5, 4.5), sign="saw", gable=True, upper_windows=(2.5,), seed="carp")
    s["b_ranch"] = house(6, 32, 30, wall="cream", beam="rust", roof="wine", door=2.6, windows=(0.5, 4.5), shutters="rust", sign="bell", seed="ranch")
    s["b_fish"] = house(5, 30, 26, wall="ice", beam="blue", roof="navy", door=2.1, windows=(0.4,), sign="fish", chimney=False, base="wood", seed="fish")
    s["b_clinic"] = house(6, 34, 30, wall="white", beam="stone", roof="teal_d", door=2.6, windows=(0.5, 4.5), shutters="teal", sign="cross", seed="clinic")
    s["b_inn"] = house(8, 38, 38, wall="straw", beam="bark_d", roof="wine", door=3.6, windows=(0.5, 1.8, 5.6, 6.9), shutters="wine", sign="mug", gable=True, upper_windows=(3.5,), seed="inn")
    s["b_museum"] = house(7, 38, 30, wall="silver", beam="stone_d", roof="plum", door=3.1, windows=(0.6, 1.8, 4.6, 5.8), sign="eye", base="stone_d", seed="museum", door_col="bark")
    s["b_cottage"] = house(5, 30, 30, wall="blush", beam="bark", roof="wood", door=2.1, windows=(0.4, 3.6), shutters="rose", seed="cottage")
    s["belfry"] = belfry()
    s["bell_off"] = bell_small(False)
    s["bell_on"] = bell_small(True)
    s["lamppost"] = lamppost()
    s["bench"] = bench()
    s["notice_board"] = notice_board()
    s["weather_harp"] = weather_harp()
    s["fountain"] = fountain()
    s["barrel"] = barrel()
    s["crate"] = crate()
    s["crate_apples"] = crate("red")
    s["crate_greens"] = crate("leaf_l")
    s["stall_red"] = stall("red")
    s["stall_blue"] = stall("blue")
    s["boat"] = boat()
    s["bunting"] = bunting()
    s["snowman"] = snowman()
    s["target"] = target()
    for col in ("red", "amber", "sky"):
        s["ribbon_" + col] = ribbon(col)
    # intérieurs
    s["bed"] = bed(False)
    s["bed_double"] = bed(True, "wine")
    for p in "lmr":
        s["counter_" + p] = counter(p)
    for k in ("store", "tools", "fish", "books", "med", "ranch"):
        s["shelf_" + k] = goods_shelf(k)
    s["anvil"] = anvil()
    s["forge_fire"] = forge_fire()
    s["workbench"] = workbench()
    s["big_table"] = big_table()
    s["big_table_cloth"] = big_table("red")
    s["stool"] = stool()
    s["fireplace"] = fireplace()
    s["kitchen"] = kitchen()
    s["frog_jar"] = frog_jar()
    s["display_minerals"] = display_case("violet")
    s["display_artifacts"] = display_case("amber")
    s["display_fish"] = display_case("sky")
    s["desk"] = desk()
    s["hospital_bed"] = hospital_bed()
    s["window_in"] = window_in()
    s["door_mat"] = door_mat()
    s["big_rug_red"] = big_rug("red")
    s["big_rug_blue"] = big_rug("blue")
    s["trough_empty"] = trough(False)
    s["trough_full"] = trough(True)
    s["straw_pile"] = straw_pile()
    return s
