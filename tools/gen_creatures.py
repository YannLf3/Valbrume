"""Animaux de ferme (adulte + petit), compagnon et monstres de la mine.

Animaux : cellule 24×20, tournés vers la droite, colonnes repos / marche 1 / marche 2 / tête baissée ;
ligne 0 adulte, ligne 1 petit. Monstres : cellule 24×24, 3 images.
"""
import os
from typing import Dict, List

from palette import darker, lighter
from px import Canvas, save, sheet

AW, AH = 24, 20
MW, MH = 24, 24
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites", "creatures")


def _legs(c: Canvas, xs: List[int], top: int, length: int, col: str, hoof: str, frame: int) -> None:
    for i, x in enumerate(xs):
        ln = length
        dx = 0
        if frame == 1 and i % 2 == 0:
            ln -= 1
            dx = 1
        if frame == 2 and i % 2 == 1:
            ln -= 1
            dx = 1
        c.rect(x + dx, top, 2, ln, col if i % 2 == 0 else darker(col))
        c.rect(x + dx, top + ln - 1, 2, 1, hoof)


def quadruped(kind: str, frame: int, baby: bool) -> Canvas:
    c = Canvas(AW, AH)
    s = 0.62 if baby else 1.0
    spec = {
        "cow": dict(rx=8, ry=5, leg=5, hr=4, body="white", head="white", hoof="ink2"),
        "goat": dict(rx=6, ry=4, leg=5, hr=3, body="cream", head="cream", hoof="bark_d"),
        "sheep": dict(rx=7, ry=5, leg=4, hr=3, body="white", head="ink2", hoof="ink"),
        "dog": dict(rx=6, ry=3.5, leg=4, hr=3.2, body="wood_l", head="wood_l", hoof="wood"),
    }[kind]
    rx, ry = max(3.0, spec["rx"] * s), max(2.5, spec["ry"] * s)
    leg = max(2, int(round(spec["leg"] * (0.7 if baby else 1.0))))
    hr = max(2.4, spec["hr"] * (0.85 if baby else 1.0))
    ground = 18
    cx = 10
    cy = ground - leg - ry + 1
    body, head = spec["body"], spec["head"]
    eat = frame == 3
    hx = cx + rx + hr - 2.5
    hy = cy - ry * 0.4 + (ry + 2 if eat else 0)
    # pattes
    leg_col = body if kind != "sheep" else "ink2"
    _legs(c, [int(cx - rx + 1), int(cx - rx + 4), int(cx + rx - 5), int(cx + rx - 2)], int(cy + ry - 2), leg + 2, leg_col, spec["hoof"], frame)
    # queue
    tx = int(cx - rx)
    if kind == "cow":
        c.line(tx, int(cy - 1), tx - 2, int(cy + 4), "white")
        c.px(tx - 2, int(cy + 5), "bark")
    elif kind == "dog":
        c.line(tx, int(cy - 1), tx - 2, int(cy - 4 - (1 if frame == 1 else 0)), body)
    elif kind == "goat":
        c.px(tx - 1, int(cy - 2), body)
        c.px(tx - 1, int(cy - 3), body)
    # corps
    c.ellipse(cx, cy, rx, ry, body)
    if kind == "sheep":
        for i in range(-int(rx), int(rx) + 1, 3):
            c.ellipse(cx + i, cy - ry + 1, 2, 2, body)
            c.ellipse(cx + i + 1, cy + ry - 1, 2, 1.6, "silver")
        c.ellipse(cx - rx, cy, 2, 3, body)
    # ombre du ventre
    for x in range(int(cx - rx), int(cx + rx) + 1):
        y = int(cy + ry)
        while y > cy and c.get(x, y) == "void":
            y -= 1
        if c.get(x, y) == body:
            c.px(x, y, "silver" if body == "white" else darker(body))
    if kind == "cow":
        c.ellipse(cx - 3 * s, cy - 2 * s, 3 * s, 2 * s, "bark")
        c.ellipse(cx + 3 * s, cy + 1, 2.2 * s, 2 * s, "bark")
        if not baby:
            c.rect(int(cx - 3), int(cy + ry), 3, 2, "blush")
    if kind == "dog":
        c.ellipse(cx - 2, cy - 1, 3, 1.5, "wood")
    # tête
    c.ellipse(hx, hy, hr, hr, head)
    if kind == "cow":
        c.ellipse(hx + hr - 0.5, hy + 1.5, 2, 1.8, "blush")
        c.px(int(hx + hr), int(hy + 1), "wine")
        c.px(int(hx - 1), int(hy - hr - 1), "cream")
        c.px(int(hx + 2), int(hy - hr - 1), "cream")
        c.ellipse(hx - hr + 0.5, hy - 1.5, 1.4, 1, "bark")
    elif kind == "goat":
        c.ellipse(hx + hr - 0.5, hy + 1, 1.6, 1.4, head)
        c.line(int(hx - 1), int(hy - hr), int(hx - 3), int(hy - hr - 3), "stone_l")
        c.line(int(hx + 1), int(hy - hr), int(hx), int(hy - hr - 3), "stone_l")
        c.px(int(hx + hr - 1), int(hy + hr), "cream")
        c.px(int(hx + hr - 1), int(hy + hr + 1), "cream")
        c.px(int(hx - hr), int(hy - 1), "wood_l")
    elif kind == "sheep":
        c.ellipse(hx - 1, hy - hr + 0.5, 2.4, 1.6, "white")
        c.px(int(hx - hr), int(hy), "ink2")
    elif kind == "dog":
        c.ellipse(hx + hr - 0.5, hy + 1, 1.8, 1.4, "cream")
        c.px(int(hx + hr + 1), int(hy), "ink")
        c.rect(int(hx - hr), int(hy - hr), 2, 4, "bark")
        c.px(int(hx + hr - 1), int(hy + 2), "red") if frame == 1 else None
    ec = "white" if head in ("ink2", "ink") else "ink"
    c.px(int(hx + 1), int(hy - 1), ec)
    c.outline()
    return c


def bird(kind: str, frame: int, baby: bool) -> Canvas:
    c = Canvas(AW, AH)
    ground = 18
    if baby:
        col = "yellow"
        c.ellipse(11, 14, 3.2, 3, col)
        c.ellipse(13.5, 11.5 + (3 if frame == 3 else 0), 2.3, 2.3, col)
        c.px(16, 12 + (3 if frame == 3 else 0), "orange")
        c.px(14, 11 + (3 if frame == 3 else 0), "ink")
        c.px(9, 15, "amber")
        c.px(10 + (1 if frame == 1 else 0), 17, "orange")
        c.px(12 - (1 if frame == 2 else 0), 17, "orange")
        c.px(8, 13, "amber") if kind == "duck" else None
        c.outline()
        return c
    eat = frame == 3
    if kind == "chicken":
        body, wing, leg = "white", "silver", "amber"
    else:
        body, wing, leg = "cream", "straw", "orange"
    c.px(10 + (1 if frame == 1 else 0), 16, leg)
    c.px(10 + (1 if frame == 1 else 0), 17, leg)
    c.px(13 - (1 if frame == 2 else 0), 16, leg)
    c.px(13 - (1 if frame == 2 else 0), 17, leg)
    c.hline(10 + (1 if frame == 1 else 0), 18, 2, leg)
    c.hline(13 - (1 if frame == 2 else 0), 18, 2, leg)
    c.ellipse(11, 12, 5, 4, body)
    # queue
    c.poly([(6, 11), (4, 7), (7, 9)], body) if kind == "chicken" else c.poly([(6, 11), (4, 10), (6, 13)], body)
    c.ellipse(10, 12.5, 3, 2, wing)
    hy = 7 if not eat else 12
    hx = 15 if not eat else 16
    if kind == "duck":
        c.rect(14, 8, 2, 4, body) if not eat else None
        c.ellipse(hx, hy, 2.4, 2.2, "leaf_d")
        c.hline(hx - 2, hy + 2, 4, "white") if not eat else None
        c.rect(hx + 2, hy, 3, 2, "amber")
    else:
        c.rect(14, 8, 2, 3, body) if not eat else None
        c.ellipse(hx, hy, 2.3, 2.3, body)
        c.rect(hx - 1, hy - 4, 3, 2, "red")
        c.px(hx + 1, hy - 5, "red")
        c.px(hx + 3, hy, "amber")
        c.px(hx + 3, hy + 1, "orange")
        c.px(hx + 2, hy + 2, "red")
    c.px(hx + 1, hy - 1, "ink" if kind == "chicken" else "white")
    c.outline()
    return c


ANIMALS = ["chicken", "duck", "cow", "goat", "sheep", "dog"]


def animal_sheet(kind: str) -> Canvas:
    cells: List[Canvas] = []
    for baby in (False, True):
        for f in range(4):
            cells.append(bird(kind, f, baby) if kind in ("chicken", "duck") else quadruped(kind, f, baby))
    return sheet(cells, 4, AW, AH)


# --- monstres --------------------------------------------------------------

def monster(kind: str, f: int) -> Canvas:
    c = Canvas(MW, MH)
    g = 21
    if kind == "pebbler":            # Gravillon : caillou vivant, avance en roulant des épaules
        dy = 1 if f == 1 else 0
        c.poly([(6, g - 1), (5, g - 6 + dy), (8, g - 11 + dy), (14, g - 12 + dy), (18, g - 8 + dy), (18, g - 1)], "stone")
        c.poly([(8, g - 9 + dy), (10, g - 11 + dy), (13, g - 11 + dy), (11, g - 8 + dy)], "stone_l")
        c.line(15, g - 9 + dy, 17, g - 5 + dy, "stone_d")
        c.line(7, g - 3, 12, g - 2, "stone_d")
        c.rect(9, g - 7 + dy, 2, 2, "amber")
        c.rect(14, g - 7 + dy, 2, 2, "amber")
        c.px(10, g - 6 + dy, "ink")
        c.px(15, g - 6 + dy, "ink")
        c.rect(7 - (1 if f == 2 else 0), g, 3, 1, "stone_d")
        c.rect(14 + (1 if f == 2 else 0), g, 3, 1, "stone_d")
    elif kind == "mosshop":          # Sautemousse : boule de mousse à ressort
        sq = [0, 2, -3][f]
        ry = 6 - sq * 0.6
        rx = 7 + sq * 0.5
        cy = g - ry - (6 if f == 2 else 0)
        c.ellipse(12, cy, rx, ry, "leaf")
        c.ellipse(10, cy - ry * 0.4, rx * 0.5, ry * 0.4, "leaf_l")
        for x, y in ((7, 1), (15, 2), (11, 3), (16, -1)):
            c.px(x, int(cy + y), "leaf_d")
        c.poly([(7, int(cy - ry)), (5, int(cy - ry - 4)), (9, int(cy - ry + 1))], "leaf_l")
        c.poly([(16, int(cy - ry)), (19, int(cy - ry - 4)), (14, int(cy - ry + 1))], "leaf_l")
        c.rect(9, int(cy - 1), 2, 3, "white")
        c.rect(14, int(cy - 1), 2, 3, "white")
        c.px(10, int(cy), "ink")
        c.px(15, int(cy), "ink")
        c.hline(11, int(cy + 3), 3, "leaf_dd")
        if f == 2:
            c.rect(9, g - 3, 2, 3, "leaf_d")
            c.rect(14, g - 3, 2, 3, "leaf_d")
    elif kind == "emberbat":         # Chauve-braise : vole en zigzag, ailes de cendre
        wy = [-4, 0, 4][f]
        c.poly([(11, 11), (3, 9 + wy), (2, 13 + wy // 2), (6, 12 + wy // 2), (8, 14)], "wine")
        c.poly([(13, 11), (21, 9 + wy), (22, 13 + wy // 2), (18, 12 + wy // 2), (16, 14)], "wine")
        c.line(4, 10 + wy, 9, 12, "rust")
        c.line(20, 10 + wy, 15, 12, "rust")
        c.ellipse(12, 12, 3.5, 4, "rust")
        c.ellipse(12, 13.5, 2, 2, "orange")
        c.px(12, 14, "yellow")
        c.poly([(9, 9), (9, 5), (11, 8)], "rust")
        c.poly([(15, 9), (15, 5), (13, 8)], "rust")
        c.px(10, 11, "yellow")
        c.px(14, 11, "yellow")
        c.px(11, 16, "white")
        c.px(13, 16, "white")
    elif kind == "frostspit":        # Crachegivre : bulbe de glace enraciné qui crache des éclats
        open_ = f == 2
        c.poly([(8, g), (6, g - 3), (10, g - 4), (12, g - 2), (14, g - 4), (18, g - 3), (16, g)], "navy")
        c.rect(11, g - 9, 2, 6, "blue")
        c.ellipse(12, g - 12 - (1 if f == 1 else 0), 6, 5, "sky")
        c.ellipse(10, g - 14 - (1 if f == 1 else 0), 3, 2, "ice")
        c.px(9, g - 15 - (1 if f == 1 else 0), "frost")
        for x, y in ((6, -15), (18, -15), (12, -18), (8, -17), (16, -17)):
            c.line(12 + (x - 12) // 2, g + y + 3, x, g + y, "ice")
        yy = g - 12 - (1 if f == 1 else 0)
        c.px(10, yy - 1, "ink")
        c.px(14, yy - 1, "ink")
        if open_:
            c.ellipse(12, yy + 2, 2.2, 1.8, "navy")
            c.px(12, yy + 2, "frost")
        else:
            c.hline(11, yy + 2, 3, "navy")
    elif kind == "glowmite":         # Lucimite : petite, rapide, en essaim, abdomen lumineux
        dx = [0, 1, 0][f]
        c.ellipse(10, 15, 3.5, 3, "yellow")
        c.ellipse(9, 14, 1.5, 1.2, "white")
        c.ellipse(14, 15, 2.5, 2.5, "plum")
        c.ellipse(16.5, 15, 1.8, 1.8, "violet")
        c.px(17, 14, "white")
        c.line(17, 13, 19, 11 - dx, "plum")
        c.line(16, 13, 16, 10 + dx, "plum")
        for i, x in enumerate((9, 12, 15)):
            o = 1 if (i + f) % 2 == 0 else 0
            c.line(x, 17, x - 1 + o * 2, 19, "ink2")
        if f != 1:
            c.px(7, 12, "yellow")
            c.px(6, 17, "amber")
    else:                            # Carapierre : cuirassé qui prend son élan puis charge
        lean = [0, -2, 2][f]
        c.rect(6 + (1 if f == 2 else 0), g - 3, 3, 4, "stone_d")
        c.rect(15 + (1 if f == 2 else 0), g - 3, 3, 4, "stone_d")
        c.ellipse(11, g - 9, 8, 7, "plum")
        c.ellipse(11, g - 10, 8, 6, "violet")
        for i in range(3):
            c.line(5 + i * 5, g - 15 + abs(i - 1) * 2, 4 + i * 5, g - 5, "plum")
        c.ellipse(8, g - 13, 3, 1.5, "lilac")
        c.ellipse(18 + lean, g - 7, 3.5, 3.5, "stone")
        c.poly([(20 + lean, g - 9), (23 + lean, g - 12), (21 + lean, g - 6)], "silver")
        c.px(19 + lean, g - 8, "red" if f else "amber")
        c.hline(18 + lean, g - 5, 3, "stone_d")
        if f == 1:
            c.px(3, g - 1, "stone_l")
            c.px(1, g - 2, "stone_l")
    c.outline()
    return c


MONSTERS = ["pebbler", "mosshop", "emberbat", "frostspit", "glowmite", "shellcharger"]


def generate() -> Dict[str, Canvas]:
    out: Dict[str, Canvas] = {}
    for a in ANIMALS:
        out["animal_" + a] = animal_sheet(a)
    for m in MONSTERS:
        out["monster_" + m] = sheet([monster(m, f) for f in range(3)], 3, MW, MH)
    return out


def main() -> int:
    n = 0
    for name, c in generate().items():
        save(c, os.path.join(OUT, name + ".png"))
        n += 8 if name.startswith("animal") else 3
    return n


if __name__ == "__main__":
    print("créatures : %d images" % main())
