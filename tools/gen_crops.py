"""Cultures (24 × 6 stades) et arbres (4 saisons, 3 tailles, souche, arbres fruitiers).

Feuille des cultures : cellule 16×32 ancrée en bas, une ligne par culture,
colonnes 0-4 = croissance (graine → mûr), colonne 5 = après récolte (repousse).
"""
import os
import sys
from typing import Dict, List, Tuple

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "content"))
from items import CROPS, FRUIT_TREES  # noqa: E402
from palette import darker, lighter  # noqa: E402
from px import Canvas, rng_for, save, sheet  # noqa: E402

CW, CH = 16, 32
STAGES = 6
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
G = 30  # ligne du sol dans la cellule


def _seed(c: Canvas) -> None:
    c.px(6, G - 1, "straw")
    c.px(9, G, "straw")
    c.px(8, G - 2, "wood_l")


def _sprout(c: Canvas, col: str = "leaf_l") -> None:
    c.vline(8, G - 3, 4, "leaf")
    c.px(7, G - 4, col)
    c.px(9, G - 3, col)
    c.px(6, G - 5, col)


def crop_frame(shape: str, col: str, col2: str, stage: int, name: str) -> Canvas:
    c = Canvas(CW, CH)
    r = rng_for("crop" + name + str(stage))
    if stage == 0:
        _seed(c)
        c.outline()
        return c
    if stage == 1:
        _sprout(c)
        c.outline()
        return c
    grown = stage >= 4          # 4 = mûr, 5 = après récolte (pas de fruit)
    fruit = stage == 4
    k = min(stage, 4)           # taille 2..4
    if shape == "root":
        h = 2 + k * 2
        for i, dx in enumerate((-3, -1, 1, 3)):
            c.line(8, G - 1, 8 + dx, G - h + abs(dx) // 2, "leaf" if i % 2 else "leaf_l")
        c.line(8, G - 1, 8, G - h - 1, "leaf")
        if fruit:
            c.ellipse(8, G, 3, 1.6, col)
            c.px(7, G - 1, col2)
    elif shape == "leafy":
        rr = 1.5 + k * 1.3
        c.ellipse(8, G - rr * 0.7, rr, rr * 0.8, darker(col) if grown else col)
        c.ellipse(7.5, G - rr * 0.9, rr * 0.7, rr * 0.55, col)
        c.ellipse(7, G - rr * 1.0, rr * 0.35, rr * 0.3, col2)
        if grown:
            c.line(8, G - 1, 8, int(G - rr), darker(col))
    elif shape == "trellis":
        c.vline(4, G - 20, 21, "wood")
        c.vline(11, G - 20, 21, "wood")
        c.hline(4, G - 18, 8, "wood")
        c.hline(4, G - 10, 8, "wood")
        top = G - 3 - k * 4
        for y in range(G - 1, top, -1):
            x = 4 + int((G - y) * 0.9) % 8
            c.px(x, y, "leaf")
            if r.random() < 0.55:
                c.px(x + r.choice((-1, 1)), y, "leaf_l" if r.random() < 0.5 else "leaf")
            if r.random() < 0.35:
                c.px(15 - x, y, "leaf_d")
        if stage >= 3:
            for y in range(G - 2, top, -2):
                c.px(3 + r.randint(0, 9), y, "leaf_l")
        if fruit:
            for i in range(6):
                x, y = 4 + r.randint(0, 8), top + 2 + r.randint(0, max(1, G - top - 6))
                c.px(x, y, col)
                c.px(x, y + 1, col)
                c.px(x + 1, y + 1, col2)
    elif shape == "bush":
        h = 3 + k * 3
        c.vline(8, G - h, h + 1, "leaf_d")
        c.vline(12, G - h - 1, h + 2, "wood") if stage >= 3 else None
        for i in range(k * 3):
            y = G - 2 - r.randint(0, h - 1)
            w = 1 + (y - (G - h)) // 3 + 1
            x = 8 + r.randint(-w, w)
            c.px(x, y, r.choice(["leaf", "leaf", "leaf_l"]))
            c.px(x + 1, y, "leaf")
        c.ellipse(8, G - h * 0.6, 2 + k * 0.6, h * 0.35, "leaf")
        c.ellipse(7, G - h * 0.7, 1 + k * 0.4, h * 0.2, "leaf_l")
        if fruit:
            for x, y in ((5, -3), (10, -5), (7, -8), (11, -9), (5, -10)):
                if -y < h + 1:
                    c.rect(x, G + y, 2, 2, col)
                    c.px(x, G + y, col2 if col2 != col else lighter(col))
    elif shape == "vine":
        w = 1 + k * 1.5
        for i in range(int(w * 2)):
            x = int(8 - w + i)
            y = G - 1 - (1 if i % 3 == 0 else 0)
            c.px(x, y, "leaf_d")
            if i % 2 == 0:
                c.px(x, y - 1, "leaf")
                c.px(x + 1, y - 2, "leaf_l")
        c.ellipse(5, G - 3, k * 0.9, k * 0.6, "leaf")
        c.ellipse(11, G - 2 - k * 0.3, k * 0.9, k * 0.6, "leaf")
        c.px(5, G - 4, "leaf_l")
        if stage >= 3 and not fruit:
            c.px(8, G - 3, "yellow")
        if fruit:
            if col in ("orange", "amber"):
                c.ellipse(8, G - 3, 4.5, 3.6, col)
                c.ellipse(7, G - 4, 2, 1.5, col2 if col == "amber" else "amber")
                c.vline(8, G - 6, 5, darker(col)) if col == "orange" else None
                c.px(8, G - 7, "leaf_d")
            else:
                c.poly([(4, G - 2), (6, G - 5), (11, G - 5), (12, G - 3), (10, G - 1), (5, G - 1)], col)
                c.hline(6, G - 4, 4, col2)
    elif shape == "flower":
        h = 2 + k * 2
        c.vline(8, G - h, h + 1, "leaf")
        c.px(7, G - h // 2, "leaf_l")
        c.px(9, G - h // 2 - 1, "leaf_l")
        c.px(6, G - h // 2 - 1, "leaf_l") if stage >= 3 else None
        if stage == 3:
            c.px(8, G - h - 1, col2)
        if fruit:
            y = G - h - 2
            if name == "lavender":
                for i in range(5):
                    c.px(8 + (i % 2) - (1 if i % 3 == 0 else 0), y - 2 + i, col if i % 2 else col2)
                    c.px(8, y - 2 + i, col)
                c.vline(5, G - 7, 6, "leaf")
                c.vline(11, G - 6, 5, "leaf")
                for i in range(3):
                    c.px(5, G - 9 + i, col)
                    c.px(11, G - 8 + i, col2)
            elif name == "snowdrop":
                c.line(8, G - h, 10, G - h - 2, "leaf")
                c.rect(10, G - h - 1, 2, 3, col)
                c.px(10, G - h + 2, col2)
            elif name == "belltulip":
                c.rect(6, y, 5, 4, col)
                c.px(6, y - 1, col)
                c.px(8, y - 1, col)
                c.px(10, y - 1, col)
                c.vline(10, y, 4, col2)
            else:
                for dx, dy in ((0, -2), (-2, 0), (2, 0), (0, 2), (-1, -1), (1, -1), (-1, 1), (1, 1)):
                    c.px(8 + dx, y + 1 + dy, col)
                c.px(8, y + 1, col2)
                c.px(8, y, col2)
    elif shape == "stalk":
        h = 2 + k * 3
        for dx, lean in ((-2, -1), (0, 0), (2, 1)):
            c.line(8 + dx // 2, G, 8 + dx + lean, G - h + abs(dx), "leaf" if dx else "leaf_l")
        if name == "sunchoke" and stage >= 3:
            c.px(8, G - h - 1, "yellow")
            c.px(7, G - h, "yellow")
            c.px(9, G - h, "yellow")
        if grown and name != "sunchoke":
            c.rect(7, G - 2, 3, 3, col)
            c.px(7, G - 2, lighter(col))
        if fruit and name == "sunchoke":
            c.px(6, G, col)
            c.px(10, G, col)
    elif shape == "cabbage":
        rr = 1.5 + k * 1.4
        c.ellipse(8, G - rr * 0.6, rr + 1.5, rr * 0.7, "leaf_d")
        c.ellipse(5, G - rr * 0.5, 2, 2, "leaf")
        c.ellipse(11, G - rr * 0.5, 2, 2, "leaf")
        if stage >= 3:
            c.ellipse(8, G - rr * 0.8, rr * 0.7, rr * 0.7, col2 if not fruit else col)
            if fruit:
                c.ellipse(7, G - rr * 1.0, rr * 0.35, rr * 0.3, "lilac")
                c.line(8, int(G - rr * 1.4), 9, G - 2, col2)
    if stage == 5:
        # après récolte : on garde le plant, sans fruit (déjà géré par `fruit`)
        pass
    c.outline()
    return c


def crops_sheet() -> Canvas:
    cells: List[Canvas] = []
    for row in CROPS:
        cid, shape, col, col2 = row[0], row[8], row[9], row[10]
        for s in range(STAGES):
            cells.append(crop_frame(shape, col, col2, s, cid))
    return sheet(cells, STAGES, CW, CH)


def dead_crop() -> Canvas:
    c = Canvas(CW, CH)
    c.line(8, G, 7, G - 6, "wood")
    c.line(7, G - 4, 4, G - 6, "wood")
    c.line(8, G - 3, 11, G - 7, "wood_l")
    c.px(4, G - 7, "bark")
    c.px(11, G - 8, "bark")
    c.outline()
    return c


# --- arbres ------------------------------------------------------------------

LEAVES = {
    "spring": ("leaf", "leaf_l", "lime", "leaf_d"),
    "summer": ("leaf_d", "leaf", "leaf_l", "leaf_dd"),
    "autumn": ("orange", "amber", "yellow", "rust"),
    "winter": (None, None, None, None),
}


def broadleaf(season: str, size: int, kind: str, fruit: str = "") -> Canvas:
    """size 0 pousse, 1 jeune, 2 adulte. Cellule 32×48, ancrée en bas au centre."""
    w, h = 32, 48
    c = Canvas(w, h)
    r = rng_for("tree%s%s%d%s" % (kind, season, size, fruit))
    base, hi, hi2, lo = LEAVES[season]
    trunk, trunk_l = ("silver", "white") if kind == "birch" else ("bark", "wood")
    g = h - 2
    if size == 0:
        c.vline(16, g - 6, 7, trunk)
        if base:
            c.ellipse(16, g - 8, 3, 3, base)
            c.px(15, g - 9, hi)
        else:
            c.px(14, g - 6, trunk)
            c.px(18, g - 7, trunk)
        c.outline()
        return c
    th = 12 if size == 1 else 18
    tw = 2 if size == 1 else 4
    c.rect(16 - tw // 2, g - th, tw, th + 1, trunk)
    c.vline(16 - tw // 2, g - th, th, trunk_l)
    if kind == "birch":
        for y in range(g - th + 2, g, 4):
            c.px(16 - tw // 2 + r.randint(0, tw - 1), y, "ink2")
    if size == 2:
        c.px(16 - tw // 2 - 1, g, trunk)
        c.px(16 + tw // 2, g, trunk)
    cy = g - th - (5 if size == 1 else 9)
    rx, ry = (8, 7) if size == 1 else (13, 12)
    if base is None:
        # hiver : branches nues + neige
        for dx in (-1, 1):
            c.line(16, g - th + 2, 16 + dx * rx * 0.8, cy - 2, trunk)
            c.line(16 + dx * 3, cy + 4, 16 + dx * (rx - 1), cy + 5, trunk)
            c.line(16 + dx * 2, cy, 16 + dx * 4, cy - ry + 2, trunk)
        c.line(16, g - th, 16, cy - ry + 3, trunk)
        for _ in range(10 if size == 2 else 5):
            x, y = 16 + r.randint(-rx, rx), cy + r.randint(-ry, 5)
            if c.get(x, y + 1) != "void":
                c.hline(x - 1, y, 3, "white")
        c.outline()
        return c
    blobs = [(0, 0, rx, ry * 0.8), (-rx * 0.45, ry * 0.25, rx * 0.6, ry * 0.55), (rx * 0.45, ry * 0.2, rx * 0.6, ry * 0.55),
             (0, -ry * 0.45, rx * 0.65, ry * 0.55)]
    for bx, by, brx, bry in blobs:
        c.ellipse(16 + bx, cy + by, brx, bry, base)
    for bx, by, brx, bry in blobs:
        c.ellipse(16 + bx - brx * 0.25, cy + by - bry * 0.3, brx * 0.55, bry * 0.5, hi)
    c.ellipse(16 - rx * 0.4, cy - ry * 0.5, rx * 0.25, ry * 0.2, hi2)
    for _ in range(14 if size == 2 else 6):
        x, y = 16 + r.randint(-rx, rx), cy + r.randint(int(-ry * 0.3), int(ry * 0.8))
        if c.get(x, y) in (base, hi):
            c.px(x, y, lo)
            c.px(x + 1, y, lo)
    if season == "spring" and kind in ("oak", "fruit"):
        for _ in range(8 if size == 2 else 3):
            x, y = 16 + r.randint(-rx + 1, rx - 1), cy + r.randint(-ry + 2, int(ry * 0.6))
            if c.get(x, y) != "void":
                c.px(x, y, "blush" if kind == "fruit" else "lime")
    if fruit and size == 2:
        for _ in range(7):
            x, y = 16 + r.randint(-rx + 2, rx - 3), cy + r.randint(-ry + 4, int(ry * 0.7))
            if c.get(x, y) != "void":
                c.rect(x, y, 2, 2, fruit)
                c.px(x, y, lighter(fruit))
    c.outline()
    return c


def pine(season: str, size: int) -> Canvas:
    w, h = 32, 48
    c = Canvas(w, h)
    g = h - 2
    snow = season == "winter"
    base, hi = ("leaf_dd", "leaf_d") if season != "spring" else ("leaf_d", "leaf")
    if size == 0:
        c.poly([(16, g - 9), (13, g - 1), (19, g - 1)], base)
        c.px(15, g - 5, hi)
        c.outline()
        return c
    tiers = 3 if size == 1 else 5
    th = 4
    c.rect(15, g - th, 3 if size == 2 else 2, th + 1, "bark")
    top = g - th - tiers * (5 if size == 1 else 7) + 2
    for i in range(tiers):
        y0 = top + i * (5 if size == 1 else 7)
        hw = 3 + i * (2 if size == 1 else 2.6)
        y1 = y0 + (7 if size == 1 else 10)
        c.poly([(16, y0), (int(16 - hw), y1), (int(16 + hw), y1)], base)
        c.line(16, y0 + 1, int(16 - hw * 0.6), y1 - 1, hi)
        if snow:
            c.line(16, y0, int(16 - hw * 0.7), y0 + int((y1 - y0) * 0.7), "white")
            c.px(16, y0, "white")
            c.px(int(16 + hw * 0.4), y0 + 4, "frost")
    c.outline()
    return c


def stump(kind: str) -> Canvas:
    c = Canvas(16, 16)
    t, tl = ("silver", "white") if kind == "birch" else ("bark", "wood")
    c.rect(4, 8, 8, 6, t)
    c.vline(4, 8, 6, tl)
    c.ellipse(7.5, 8, 4, 2, "wood_l")
    c.ellipse(7.5, 8, 2, 1, "straw")
    c.px(3, 14, t)
    c.px(12, 14, t)
    c.outline()
    return c


TREE_KINDS = ["oak", "birch", "pine"]


def generate() -> Tuple[Canvas, Dict[str, Canvas]]:
    named: Dict[str, Canvas] = {"crop_dead": dead_crop()}
    for kind in TREE_KINDS:
        named["stump_" + kind] = stump(kind)
        for s in LEAVES:
            for size in range(3):
                named["tree_%s_%s_%d" % (kind, s, size)] = pine(s, size) if kind == "pine" else broadleaf(s, size, kind)
    for row in FRUIT_TREES:
        fid, season, col = row[0], row[3], row[6]
        for s in LEAVES:
            for size in range(3):
                named["ftree_%s_%s_%d" % (fid, s, size)] = broadleaf(s, size, "fruit")
        named["ftree_%s_fruit" % fid] = broadleaf(season if season != "winter" else "autumn", 2, "fruit", col)
        if season == "winter":
            # le néflier garde ses fruits sur branches nues
            c = broadleaf("winter", 2, "fruit")
            r = rng_for("medlarfruit")
            for _ in range(8):
                x, y = 16 + r.randint(-10, 10), 10 + r.randint(0, 14)
                if c.get(x, y + 1) != "void" or c.get(x, y - 1) != "void":
                    c.rect(x, y, 2, 2, col)
            named["ftree_%s_fruit" % fid] = c
    return crops_sheet(), named


if __name__ == "__main__":
    sh, named = generate()
    save(sh, os.path.join(OUT, "crops.png"))
    print("cultures : %d images, arbres : %d" % (len(CROPS) * STAGES, len(named)))
