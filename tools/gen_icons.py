"""Icônes d'objets 16×16, générées par gabarits paramétrés (forme + 2 couleurs).

La spécification d'icône de chaque objet (« gabarit:couleur:couleur2 ») vient
de tools/content/. Feuille : 16 colonnes, dans l'ordre du registre.
"""
import os
import sys
from typing import Callable, Dict, List

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "content"))
from registry import all_items  # noqa: E402
from palette import darker, lighter  # noqa: E402
from px import Canvas, save, sheet  # noqa: E402

S = 16
COLS = 16
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
T: Dict[str, Callable[[Canvas, str, str], None]] = {}


def tmpl(*names: str):
    def deco(fn):
        for n in names:
            T[n] = fn
        return fn
    return deco


def hl(c: Canvas, x: int, y: int, col: str) -> None:
    c.px(x, y, lighter(col) if lighter(col) != col else "white")


# --- outils -------------------------------------------------------------------
def _handle(c: Canvas, x0=3, y0=13, x1=11, y1=5) -> None:
    c.line(x0, y0, x1, y1, "wood")
    c.line(x0 + 1, y0, x1 + 1, y1, "bark")


@tmpl("tool_hoe")
def _(c, a, b):
    _handle(c)
    c.poly([(9, 3), (13, 3), (13, 5), (11, 7)], a)
    c.line(10, 3, 13, 3, lighter(a))


@tmpl("tool_can")
def _(c, a, b):
    c.rect(4, 6, 7, 7, a)
    c.vline(4, 6, 7, lighter(a))
    c.vline(10, 7, 6, darker(a))
    c.line(11, 9, 14, 5, a)
    c.px(14, 4, darker(a))
    c.px(13, 4, darker(a))
    c.frame(2, 7, 3, 5, darker(a))
    c.hline(5, 5, 5, darker(a))
    c.px(15, 6, "sky")
    c.px(14, 8, "sky")


@tmpl("tool_axe")
def _(c, a, b):
    _handle(c)
    c.poly([(8, 3), (12, 2), (14, 6), (11, 7), (10, 5)], a)
    c.line(12, 2, 14, 6, lighter(a))


@tmpl("tool_pick")
def _(c, a, b):
    _handle(c, 3, 13, 10, 6)
    c.line(6, 4, 9, 3, a)
    c.line(9, 3, 13, 5, a)
    c.line(13, 5, 14, 9, a)
    c.line(7, 5, 10, 4, darker(a))
    c.line(10, 4, 12, 6, darker(a))
    c.px(9, 3, lighter(a))


@tmpl("tool_scythe")
def _(c, a, b):
    _handle(c, 4, 14, 10, 3)
    c.line(10, 3, 4, 2, a)
    c.line(4, 2, 2, 5, a)
    c.line(9, 4, 5, 3, lighter(a))
    c.px(3, 4, darker(a))


@tmpl("tool_rod")
def _(c, a, b):
    c.line(2, 14, 12, 2, "wood")
    c.line(3, 14, 5, 12, "bark")
    c.px(12, 2, a)
    c.px(11, 3, a)
    c.rect(4, 10, 2, 2, a)
    c.vline(12, 3, 7, "stone_l")
    c.px(12, 10, "red")
    c.px(12, 11, "white")


@tmpl("tool_sword")
def _(c, a, b):
    c.line(5, 11, 12, 4, a)
    c.line(6, 11, 13, 4, lighter(a))
    c.line(5, 10, 11, 4, darker(a))
    c.px(13, 3, lighter(a))
    c.line(3, 9, 7, 13, "amber")
    c.line(3, 12, 4, 13, "bark")
    c.px(2, 14, "bark")
    c.px(3, 13, "wood")


# --- graines, pousses -----------------------------------------------------------
@tmpl("seed")
def _(c, a, b):
    c.rect(4, 3, 8, 11, "cream")
    c.rect(4, 3, 8, 2, "straw")
    c.vline(11, 5, 9, "sand")
    c.ellipse(7.5, 9, 2, 2, a)
    c.px(7, 8, b)
    c.px(7, 6, "leaf")
    c.px(8, 5, "leaf_l")


@tmpl("sapling")
def _(c, a, b):
    c.rect(5, 11, 6, 3, "soil")
    c.hline(5, 11, 6, "soil_l")
    c.vline(8, 5, 6, "bark")
    c.ellipse(8, 5, 3, 2.5, "leaf")
    c.px(7, 4, "leaf_l")
    c.px(9, 6, a)
    c.px(6, 5, a)


# --- récoltes -------------------------------------------------------------------
def _tuft(c: Canvas, x: int, y: int) -> None:
    c.line(x, y, x - 2, y - 3, "leaf")
    c.line(x, y, x, y - 4, "leaf_l")
    c.line(x, y, x + 2, y - 3, "leaf")


@tmpl("c_root")
def _(c, a, b):
    _tuft(c, 8, 6)
    c.ellipse(8, 10, 4, 3.5, a)
    c.ellipse(7, 12, 2.5, 1.5, b)
    c.px(8, 14, a)
    hl(c, 6, 8, a)


@tmpl("c_long_root")
def _(c, a, b):
    _tuft(c, 10, 5)
    c.poly([(8, 5), (12, 6), (5, 14), (4, 13)], a)
    c.line(9, 6, 5, 12, b)
    c.px(7, 9, darker(a))
    c.px(9, 8, darker(a))


@tmpl("c_leafy", "leafy")
def _(c, a, b):
    c.ellipse(8, 9, 5, 4.5, darker(a))
    c.ellipse(6, 8, 3, 3.5, a)
    c.ellipse(10, 8, 3, 3.5, a)
    c.ellipse(8, 7, 2, 3, b)
    c.vline(8, 9, 5, darker(a))
    c.px(8, 14, b)


@tmpl("c_pod")
def _(c, a, b):
    c.line(3, 11, 7, 5, a)
    c.line(7, 5, 13, 4, a)
    c.line(4, 12, 8, 7, a)
    c.line(8, 7, 13, 5, a)
    c.line(4, 11, 7, 7, b)
    for x, y in ((5, 10), (7, 7), (10, 5)):
        c.px(x, y, b)
    c.px(2, 12, "leaf_d")
    c.px(14, 3, "leaf_d")


@tmpl("c_bulb")
def _(c, a, b):
    c.line(8, 9, 6, 2, b)
    c.line(8, 9, 9, 2, lighter(b))
    c.line(8, 9, 11, 3, b)
    c.ellipse(8, 11, 3, 3, a)
    c.px(7, 10, "frost")
    c.px(8, 14, "straw")
    c.px(7, 14, "straw")


@tmpl("c_flower", "flower")
def _(c, a, b):
    c.vline(8, 8, 7, "leaf")
    c.px(7, 11, "leaf_l")
    c.px(6, 10, "leaf_l")
    c.px(9, 12, "leaf_l")
    for dx, dy in ((0, -3), (-3, 0), (3, 0), (0, 3), (-2, -2), (2, -2), (-2, 2), (2, 2)):
        c.ellipse(8 + dx, 5 + dy * 0.8, 1.3, 1.3, a)
    c.ellipse(8, 5, 1.4, 1.4, b)


@tmpl("c_round")
def _(c, a, b):
    c.ellipse(8, 9, 5, 4.5, a)
    c.ellipse(9, 11, 3, 2, b)
    c.ellipse(6, 7, 1.5, 1.2, lighter(a))
    c.px(8, 4, "leaf")
    c.px(7, 4, "leaf_d")
    c.px(9, 3, "leaf")
    c.px(6, 5, "leaf_d")
    c.px(10, 5, "leaf_d")


@tmpl("c_long")
def _(c, a, b):
    c.poly([(3, 11), (5, 8), (11, 4), (13, 5), (12, 8), (6, 13), (4, 13)], a)
    c.line(5, 10, 11, 6, b)
    c.px(12, 4, "leaf")
    c.px(13, 3, "leaf_d")
    c.px(13, 4, "leaf_d")


@tmpl("c_melon")
def _(c, a, b):
    c.ellipse(8, 9, 6, 5, a)
    for x in (4, 6, 8, 10, 12):
        c.line(x, 5 + abs(x - 8) // 2, x, 13 - abs(x - 8) // 2, b)
    c.px(8, 3, "leaf_d")
    c.px(9, 2, "leaf")


@tmpl("c_sprig", "sprig")
def _(c, a, b):
    for i, (x0, x1) in enumerate(((5, 4), (8, 8), (11, 12))):
        c.line(8, 14, x1, 3 + i % 2, "leaf" if b not in ("leaf", "leaf_d") else b)
        for k in range(5):
            c.px(x1 + (k % 2), 2 + i % 2 + k, a)
            c.px(x1 - 1 + (k % 2) * 2, 3 + i % 2 + k, lighter(a) if k % 2 else a)


@tmpl("c_pumpkin")
def _(c, a, b):
    c.ellipse(8, 9, 6.5, 5, a)
    c.ellipse(8, 9, 3, 5, lighter(a))
    c.ellipse(8, 9, 1, 5, a)
    c.line(3, 7, 3, 11, b)
    c.line(13, 7, 13, 11, b)
    c.rect(7, 2, 2, 3, "leaf_d")
    c.px(9, 2, "leaf")


@tmpl("c_leek")
def _(c, a, b):
    c.line(3, 13, 9, 7, a)
    c.line(4, 14, 10, 8, a)
    c.line(4, 13, 9, 8, "white")
    c.line(9, 7, 13, 2, b)
    c.line(10, 8, 14, 5, b)
    c.line(10, 7, 12, 3, lighter(b))
    c.px(2, 14, "straw")
    c.px(3, 15, "straw")


@tmpl("c_cluster", "cluster")
def _(c, a, b):
    c.line(8, 2, 8, 5, "bark")
    c.px(9, 3, "leaf" if b not in ("leaf", "leaf_d") else b)
    c.px(10, 2, "leaf" if b not in ("leaf", "leaf_d") else b)
    for i, (x, y) in enumerate(((6, 6), (9, 6), (4, 8), (7, 9), (10, 8), (6, 11), (9, 11), (7, 13))):
        c.ellipse(x + 0.5, y + 0.5, 1.6, 1.6, a if i % 3 else (b if b not in ("leaf", "leaf_d") else lighter(a)))
        c.px(x, y, lighter(a))


@tmpl("c_cabbage")
def _(c, a, b):
    c.ellipse(8, 9, 6.5, 5.5, "leaf_d")
    c.ellipse(8, 9, 5, 4.8, a)
    c.ellipse(7, 8, 3, 3, lighter(a))
    c.line(8, 4, 9, 13, b)
    c.line(5, 7, 8, 9, b)
    c.line(11, 7, 9, 10, b)


@tmpl("c_knob")
def _(c, a, b):
    c.ellipse(7, 9, 4, 3.5, a)
    c.ellipse(11, 7, 2.5, 2.5, a)
    c.ellipse(5, 12, 2, 1.8, darker(a))
    c.px(6, 8, b)
    c.px(11, 6, b)
    c.px(9, 10, darker(a))
    c.px(4, 6, darker(a))


def _fruit(c, a, stem=True):
    c.ellipse(8, 9, 4.5, 4.5, a)
    c.ellipse(6.5, 7.5, 1.5, 1.5, lighter(a))
    c.ellipse(9.5, 11, 2.5, 2, darker(a))
    if stem:
        c.line(8, 5, 9, 2, "bark")
        c.px(10, 3, "leaf")
        c.px(11, 3, "leaf_l")


@tmpl("fruit_apple")
def _(c, a, b):
    _fruit(c, a)
    c.px(8, 5, "bark_d")
    c.ellipse(10, 9, 2, 2.5, "red")


@tmpl("fruit_plum")
def _(c, a, b):
    _fruit(c, a)
    c.line(8, 6, 8, 12, "plum")


@tmpl("fruit_cherry")
def _(c, a, b):
    c.line(5, 10, 8, 3, "leaf_d")
    c.line(11, 10, 8, 3, "leaf_d")
    c.px(9, 3, "leaf")
    c.px(10, 2, "leaf")
    c.ellipse(5, 11, 2.6, 2.6, a)
    c.ellipse(11, 11, 2.6, 2.6, a)
    c.px(4, 10, "rose")
    c.px(10, 10, "rose")


@tmpl("fruit_medlar")
def _(c, a, b):
    _fruit(c, a, False)
    for x in (6, 8, 10):
        c.px(x, 4, "bark")
    c.hline(6, 5, 5, "bark")
    c.px(8, 6, "bark_d")


# --- poissons -------------------------------------------------------------------
def _fish(c, back, belly, cx, cy, rx, ry, tail=3, fin=True):
    c.poly([(cx - rx, cy), (cx - rx - tail, cy - tail), (cx - rx - tail, cy + tail)], back)
    c.ellipse(cx, cy, rx, ry, back)
    for x in range(int(cx - rx), int(cx + rx) + 1):
        for y in range(int(cy), int(cy + ry) + 1):
            if c.get(x, y) == back and y > cy:
                c.px(x, y, belly)
    c.px(int(cx + rx - 2), int(cy - 1), "ink")
    c.px(int(cx + rx - 2), int(cy - 2), "white") if ry > 2.5 else None
    if fin:
        c.px(int(cx), int(cy - ry - 1), back)
        c.px(int(cx - 1), int(cy - ry - 1), back)
        c.px(int(cx - 1), int(cy + 1), darker(belly))
    c.line(cx - rx + 1, cy - 1, cx + 1, cy - ry + 1, lighter(back))


@tmpl("fish_small")
def _(c, a, b): _fish(c, a, b, 9, 9, 4, 2, 2)


@tmpl("fish_normal")
def _(c, a, b): _fish(c, a, b, 9, 8, 5, 3)


@tmpl("fish_tall")
def _(c, a, b):
    _fish(c, a, b, 9, 8, 4.5, 4.5)
    for x in (7, 9):
        c.vline(x, 5, 4, darker(a))


@tmpl("fish_round")
def _(c, a, b): _fish(c, a, b, 9, 9, 5, 4, 3)


@tmpl("fish_long")
def _(c, a, b):
    _fish(c, a, b, 9, 8, 6, 2.2, 2)
    c.px(14, 9, darker(a))


@tmpl("fish_big")
def _(c, a, b):
    _fish(c, a, b, 9, 8, 6, 4, 2)
    c.poly([(8, 4), (10, 1), (11, 4)], a)
    c.px(7, 12, "yellow")
    c.px(5, 5, "yellow")


@tmpl("fish_eel")
def _(c, a, b):
    pts = [(2, 12), (4, 10), (6, 11), (8, 9), (10, 10), (12, 7), (13, 5)]
    for i in range(len(pts) - 1):
        c.line(pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], a)
        c.line(pts[i][0], pts[i][1] + 1, pts[i + 1][0], pts[i + 1][1] + 1, b)
    c.ellipse(13, 5, 1.6, 1.6, a)
    c.px(14, 4, "ink")


@tmpl("fish_flat")
def _(c, a, b):
    c.ellipse(8, 9, 6, 3.5, a)
    c.ellipse(8, 9, 4, 2, b)
    c.poly([(2, 9), (0, 7), (0, 11)], a)
    c.px(11, 8, "ink")
    c.px(12, 9, "ink")
    for x in (5, 7, 9):
        c.px(x, 9, darker(a))


@tmpl("fish_moon")
def _(c, a, b):
    c.ellipse(8, 8, 5.5, 5.5, a)
    c.ellipse(10, 7, 4.5, 4.5, b)
    c.ellipse(11, 6.5, 3.5, 3.5, "void") if False else None
    c.poly([(3, 8), (0, 5), (1, 11)], a)
    c.px(11, 6, "ink")
    c.px(7, 4, "white")
    c.px(5, 11, "violet")
    c.px(13, 12, "yellow")
    c.px(2, 2, "yellow")


@tmpl("pot_crab")
def _(c, a, b):
    c.ellipse(8, 10, 4.5, 3, a)
    c.ellipse(8, 9, 3, 1.5, lighter(a))
    for x in (3, 13):
        c.ellipse(x, 6, 1.8, 1.8, a)
        c.px(x, 6, "ink2")
    c.line(4, 9, 3, 7, a)
    c.line(12, 9, 13, 7, a)
    for x in (4, 6, 10, 12):
        c.px(x, 13, darker(a))
    c.px(7, 8, "ink")
    c.px(9, 8, "ink")


@tmpl("pot_crayfish")
def _(c, a, b):
    c.ellipse(8, 9, 2.5, 4, a)
    c.poly([(6, 13), (10, 13), (8, 15)], darker(a))
    c.line(6, 6, 3, 3, a)
    c.line(10, 6, 13, 3, a)
    c.ellipse(3, 3, 1.5, 1.5, a)
    c.ellipse(13, 3, 1.5, 1.5, a)
    for y in (8, 10, 12):
        c.hline(6, y, 5, darker(a))
    c.px(7, 6, "ink")
    c.px(9, 6, "ink")


@tmpl("pot_shrimp")
def _(c, a, b):
    for i, (x, y) in enumerate(((11, 5), (9, 4), (6, 5), (4, 7), (4, 10), (6, 12), (9, 12))):
        c.ellipse(x, y, 2, 2, a if i % 2 else lighter(a))
    c.line(12, 5, 15, 2, darker(a))
    c.px(11, 4, "ink")
    c.poly([(10, 12), (13, 11), (13, 14)], a)


@tmpl("pot_whelk", "spiral")
def _(c, a, b):
    c.ellipse(8, 9, 5.5, 5, a)
    c.ellipse(8, 9, 3.5, 3.2, darker(a) if b == "cream" else b)
    c.ellipse(8, 9, 2, 1.8, a)
    c.px(8, 9, darker(a))
    c.px(5, 6, "white")
    c.poly([(11, 12), (14, 14), (10, 14)], lighter(a))


# --- génériques -------------------------------------------------------------------
@tmpl("mushroom")
def _(c, a, b):
    c.rect(7, 8, 3, 6, b)
    c.vline(9, 9, 5, darker(b))
    c.ellipse(8, 6, 5.5, 3.5, a)
    c.rect(3, 7, 11, 2, a)
    c.hline(4, 9, 9, darker(a))
    c.px(5, 5, lighter(a))
    c.px(6, 4, lighter(a))
    c.px(10, 6, lighter(a))


@tmpl("nut")
def _(c, a, b):
    c.ellipse(8, 10, 4.5, 4, a)
    c.ellipse(8, 6.5, 4, 2, b)
    c.px(8, 4, darker(b))
    c.px(6, 9, lighter(a))
    c.px(8, 14, darker(a))


@tmpl("cone")
def _(c, a, b):
    c.poly([(8, 2), (12, 9), (10, 14), (6, 14), (4, 9)], a)
    for y in range(4, 14, 2):
        for x in range(5 + (y // 2) % 2, 12, 2):
            if c.get(x, y) == a:
                c.px(x, y, b)
    c.px(8, 1, darker(a))


@tmpl("shell")
def _(c, a, b):
    c.poly([(8, 13), (2, 8), (4, 4), (8, 3), (12, 4), (14, 8)], a)
    for x in (4, 6, 8, 10, 12):
        c.line(8, 13, x, 4 + abs(x - 8) // 3, b)
    c.rect(6, 13, 5, 1, darker(a))


@tmpl("log")
def _(c, a, b):
    c.poly([(2, 9), (11, 4), (14, 7), (5, 13)], a)
    c.line(3, 9, 11, 5, b)
    c.ellipse(12.5, 5.5, 1.8, 2, "straw")
    c.px(12, 5, "wood")
    c.line(5, 11, 11, 8, darker(a))


@tmpl("rock")
def _(c, a, b):
    c.poly([(3, 12), (2, 8), (6, 4), (11, 4), (14, 9), (12, 13)], a)
    c.poly([(5, 7), (7, 5), (10, 5), (8, 8)], b)
    c.line(11, 7, 12, 12, darker(a))
    c.line(4, 12, 11, 13, darker(a))


@tmpl("fiber")
def _(c, a, b):
    for i, x in enumerate((4, 6, 8, 10, 12)):
        c.line(8, 13, x, 2 + (i % 2) * 2, a if i % 2 else b)
    c.rect(6, 10, 5, 2, "straw")
    c.hline(6, 11, 5, "wood_l")


@tmpl("drop")
def _(c, a, b):
    c.poly([(8, 2), (12, 9), (8, 14), (4, 9)], a)
    c.ellipse(8, 10, 4, 3.5, a)
    c.px(6, 9, b)
    c.px(7, 7, b)
    c.px(6, 10, "white")


@tmpl("hay")
def _(c, a, b):
    c.rect(2, 6, 12, 8, a)
    c.rect(2, 6, 12, 1, lighter(a))
    c.vline(6, 6, 8, "bark")
    c.vline(10, 6, 8, "bark")
    for x, y in ((3, 8), (8, 9), (12, 11), (4, 12), (8, 12), (12, 7)):
        c.px(x, y, b)
    c.px(1, 9, a)
    c.px(14, 8, a)
    c.px(14, 12, a)


@tmpl("sack")
def _(c, a, b):
    c.poly([(4, 14), (3, 8), (6, 5), (10, 5), (13, 8), (12, 14)], a)
    c.rect(6, 3, 4, 2, a)
    c.hline(6, 5, 4, "bark")
    c.ellipse(8, 10, 2, 2, b)
    c.vline(12, 8, 6, darker(a))
    c.px(5, 8, lighter(a))


@tmpl("ore")
def _(c, a, b):
    c.poly([(3, 12), (2, 8), (5, 4), (11, 3), (14, 8), (12, 13)], b)
    c.line(11, 5, 13, 11, darker(b))
    for x, y in ((5, 6), (9, 5), (7, 9), (11, 9), (5, 11)):
        c.rect(x, y, 2, 2, a)
        c.px(x, y, lighter(a))


@tmpl("gem")
def _(c, a, b):
    c.poly([(8, 2), (13, 6), (8, 14), (3, 6)], a)
    c.poly([(8, 2), (10, 6), (6, 6)], b)
    c.hline(3, 6, 11, darker(a))
    c.line(6, 6, 8, 14, darker(a))
    c.line(10, 6, 8, 14, darker(a))
    c.px(7, 4, "white")


@tmpl("ingot")
def _(c, a, b):
    c.poly([(2, 10), (5, 6), (13, 6), (14, 10), (14, 12), (2, 12)], a)
    c.poly([(5, 6), (13, 6), (12, 8), (4, 8)], b)
    c.hline(2, 12, 13, darker(a))
    c.px(6, 7, "white")


@tmpl("egg")
def _(c, a, b):
    c.ellipse(8, 9, 4, 5, a)
    c.ellipse(8, 7, 3, 3, a)
    c.ellipse(6.5, 7, 1.5, 2, b)
    c.ellipse(9.5, 11.5, 2, 1.5, "straw" if a == "cream" else "sky")


@tmpl("feather")
def _(c, a, b):
    c.poly([(4, 13), (5, 7), (10, 2), (12, 4), (10, 9)], a)
    c.line(3, 14, 11, 3, "stone_l")
    c.line(6, 9, 8, 9, b)
    c.line(8, 6, 10, 6, b)


@tmpl("bottle")
def _(c, a, b):
    c.rect(5, 6, 6, 8, a)
    c.rect(7, 2, 2, 4, "ice")
    c.rect(7, 2, 2, 1, "wood")
    c.px(6, 5, a)
    c.px(9, 5, a)
    c.rect(5, 9, 6, 2, b)
    c.vline(6, 7, 6, "white")
    c.vline(10, 7, 7, darker(a))


@tmpl("wool")
def _(c, a, b):
    for x, y in ((5, 7), (9, 6), (11, 9), (6, 11), (9, 11), (4, 9)):
        c.ellipse(x, y, 2.6, 2.4, a)
    for x, y in ((7, 12), (11, 11), (10, 8)):
        c.px(x, y, b)
    c.px(5, 6, "white")


@tmpl("jar")
def _(c, a, b):
    c.rect(4, 6, 8, 8, a)
    c.rect(5, 3, 6, 2, "cream")
    c.hline(5, 5, 6, "red")
    c.vline(5, 7, 6, b)
    c.vline(11, 7, 7, darker(a))
    c.rect(6, 9, 4, 3, "cream")
    c.px(7, 10, a)


@tmpl("bigjar")
def _(c, a, b):
    c.rect(3, 5, 10, 9, a)
    c.rect(4, 3, 8, 2, "wood")
    c.rect(4, 8, 8, 5, b)
    c.vline(4, 6, 7, "white")
    c.px(7, 10, darker(b))
    c.px(9, 11, darker(b))
    c.px(6, 12, lighter(b))


@tmpl("cheese")
def _(c, a, b):
    c.poly([(2, 11), (9, 5), (14, 8), (14, 12), (2, 13)], a)
    c.poly([(9, 5), (14, 8), (2, 11)], b)
    c.px(6, 12, darker(a))
    c.px(10, 11, darker(a))
    c.px(12, 12, darker(a))


@tmpl("block")
def _(c, a, b):
    c.poly([(3, 8), (6, 5), (13, 5), (13, 10), (10, 13), (3, 13)], a)
    c.poly([(3, 8), (6, 5), (13, 5), (10, 8)], b)
    c.vline(10, 8, 5, darker(a))


@tmpl("cloth")
def _(c, a, b):
    c.rect(3, 5, 10, 9, a)
    c.rect(3, 5, 10, 2, lighter(a))
    for y in (8, 10, 12):
        c.hline(3, y, 10, b)
    c.vline(12, 6, 8, darker(a))
    c.ellipse(13, 5, 1.5, 1.5, lighter(a))


@tmpl("fishdish")
def _(c, a, b):
    c.ellipse(8, 11, 7, 3, "white")
    c.ellipse(8, 11, 5.5, 2, "frost")
    c.ellipse(8, 9, 4.5, 2, a)
    c.poly([(3, 9), (1, 7), (1, 11)], a)
    c.hline(5, 9, 6, b)
    c.px(11, 8, "ink")
    c.px(13, 12, "leaf")
    c.px(12, 13, "yellow")


@tmpl("bait")
def _(c, a, b):
    for i, (x, y) in enumerate(((4, 10), (6, 8), (8, 9), (10, 7), (12, 8))):
        c.rect(x, y, 2, 2, a if i % 2 else b)
    c.px(13, 7, "ink")
    c.line(3, 4, 6, 3, "stone_l")
    c.line(6, 3, 7, 6, "stone_l")


@tmpl("plate")
def _(c, a, b):
    c.ellipse(8, 10, 7, 4, "white")
    c.ellipse(8, 10, 5.5, 2.8, "frost")
    c.ellipse(8, 8.5, 4.5, 2.5, a)
    c.ellipse(7, 8, 2, 1, lighter(a))
    c.px(10, 9, b)
    c.px(6, 9, b)
    c.px(9, 7, b)


@tmpl("bowl")
def _(c, a, b):
    c.poly([(2, 8), (14, 8), (12, 13), (4, 13)], "wood_l")
    c.hline(5, 13, 7, "wood")
    c.ellipse(8, 8, 6, 2, a)
    c.px(6, 8, b)
    c.px(9, 7, b)
    c.px(10, 8, b)
    c.px(7, 4, "silver")
    c.px(8, 3, "silver")
    c.px(10, 5, "silver")


@tmpl("pie")
def _(c, a, b):
    c.ellipse(8, 10, 7, 3.5, "wood_l")
    c.ellipse(8, 9, 6, 2.8, a)
    for x in (4, 7, 10):
        c.line(x, 7, x + 2, 11, "wood_l")
    c.px(6, 9, b)
    c.px(9, 8, b)
    c.px(11, 10, b)
    c.hline(3, 12, 11, "wood")


@tmpl("bread")
def _(c, a, b):
    c.ellipse(8, 9, 6.5, 4, a)
    c.ellipse(8, 8, 5, 2.5, b)
    for x in (5, 8, 11):
        c.line(x, 6, x + 1, 9, "wood")
    c.hline(3, 12, 11, "wood")


@tmpl("cup")
def _(c, a, b):
    c.rect(4, 6, 7, 7, "white")
    c.hline(4, 6, 7, a)
    c.hline(5, 7, 5, b)
    c.frame(11, 8, 3, 4, "white")
    c.hline(3, 13, 10, "stone_l")
    c.px(6, 3, "silver")
    c.px(8, 2, "silver")
    c.px(7, 4, "silver")


@tmpl("bell", "clapper")
def _(c, a, b):
    c.poly([(8, 3), (11, 5), (12, 11), (13, 12), (3, 12), (4, 11), (5, 5)], a)
    c.vline(6, 5, 6, b)
    c.rect(7, 1, 2, 2, darker(a))
    c.rect(7, 13, 2, 2, darker(a))
    c.hline(3, 12, 11, darker(a))


@tmpl("whistle")
def _(c, a, b):
    c.ellipse(7, 9, 4.5, 3.5, a)
    c.rect(10, 6, 4, 3, a)
    c.px(13, 6, b)
    c.rect(6, 7, 2, 2, "ink2")
    c.px(5, 11, darker(a))
    c.px(4, 8, b)
    c.line(3, 5, 5, 3, "stone_l")


@tmpl("charge")
def _(c, a, b):
    c.rect(5, 6, 6, 8, a)
    c.rect(5, 8, 6, 2, b)
    c.vline(10, 6, 8, darker(a))
    c.line(8, 5, 10, 2, "bark")
    c.px(11, 1, "yellow")
    c.px(12, 2, "orange")
    c.px(10, 0, "orange")


@tmpl("ladder")
def _(c, a, b):
    c.vline(5, 1, 14, a)
    c.vline(10, 1, 14, a)
    for y in (3, 6, 9, 12):
        c.hline(5, y, 6, b)


@tmpl("bouquet")
def _(c, a, b):
    c.poly([(6, 14), (10, 14), (11, 8), (5, 8)], "cream")
    c.hline(6, 11, 5, "red")
    for i, (x, y) in enumerate(((5, 6), (8, 4), (11, 6), (7, 7), (10, 8))):
        c.ellipse(x, y, 1.8, 1.8, a if i % 2 == 0 else b)
        c.px(x, y, "yellow")
    c.px(3, 8, "leaf")
    c.px(13, 8, "leaf")
    c.px(8, 8, "leaf")


@tmpl("ring")
def _(c, a, b):
    c.ellipse(8, 9, 5, 5, a)
    c.ellipse(8, 9, 2.6, 2.6, "void")
    for y in range(6, 13):
        for x in range(5, 12):
            if ((x - 8) / 2.6) ** 2 + ((y - 9) / 2.6) ** 2 <= 1.0:
                c.a[y, x] = 0
    c.px(5, 6, "white")
    c.rect(7, 3, 3, 2, b)
    c.px(8, 3, "white")


@tmpl("chest", "basket")
def _(c, a, b):
    c.rect(2, 6, 12, 8, a)
    c.rect(2, 4, 12, 3, lighter(a))
    c.hline(2, 7, 12, darker(a))
    c.rect(7, 6, 2, 3, b)
    c.vline(2, 4, 10, darker(a))
    c.vline(13, 4, 10, darker(a))
    c.px(4, 5, "white")


@tmpl("scarecrow", "soldier")
def _(c, a, b):
    c.vline(8, 4, 11, "wood")
    c.hline(3, 7, 11, "wood")
    c.rect(5, 6, 7, 6, b)
    c.ellipse(8, 3.5, 2.5, 2.5, a)
    c.px(7, 3, "ink")
    c.px(9, 3, "ink")
    c.rect(6, 0, 5, 1, darker(b))
    c.px(3, 8, "amber")
    c.px(13, 8, "amber")
    c.px(3, 9, "yellow")
    c.px(13, 9, "yellow")


@tmpl("sprinkler")
def _(c, a, b):
    c.rect(6, 9, 4, 5, a)
    c.rect(4, 13, 8, 1, darker(a))
    c.rect(5, 7, 6, 2, lighter(a))
    c.px(8, 6, darker(a))
    for x, y in ((3, 5), (2, 8), (13, 5), (14, 8), (8, 3), (5, 3), (11, 3)):
        c.px(x, y, b)


@tmpl("furnace")
def _(c, a, b):
    c.rect(3, 4, 10, 10, a)
    c.rect(3, 4, 10, 1, lighter(a))
    c.rect(5, 1, 3, 3, darker(a))
    c.rect(5, 8, 6, 5, "ink")
    c.rect(6, 10, 4, 3, b)
    c.px(7, 9, "yellow")
    c.px(8, 11, "yellow")
    c.vline(12, 5, 9, darker(a))


@tmpl("machine")
def _(c, a, b):
    c.rect(3, 6, 10, 8, a)
    c.rect(3, 6, 10, 1, lighter(a))
    c.rect(6, 2, 4, 4, darker(a))
    c.rect(5, 1, 6, 1, "stone")
    c.rect(5, 9, 6, 3, b)
    c.px(6, 9, "white")
    c.vline(12, 7, 7, darker(a))
    c.rect(2, 14, 12, 1, darker(a))


@tmpl("churn")
def _(c, a, b):
    c.poly([(5, 14), (4, 6), (12, 6), (11, 14)], a)
    c.hline(4, 8, 9, "stone")
    c.hline(4, 12, 8, "stone")
    c.vline(8, 1, 5, "wood_l")
    c.rect(6, 5, 5, 1, b)
    c.px(5, 7, lighter(a))


@tmpl("loom")
def _(c, a, b):
    c.frame(2, 3, 12, 11, a)
    c.vline(3, 3, 11, lighter(a))
    for x in range(4, 12, 2):
        c.vline(x, 4, 9, "cream")
    c.rect(4, 9, 8, 4, b)
    c.hline(4, 10, 8, lighter(b))
    c.rect(1, 14, 14, 1, darker(a))


@tmpl("hive")
def _(c, a, b):
    for i, (y, w) in enumerate(((3, 4), (5, 8), (7, 10), (9, 10), (11, 10))):
        c.rect(8 - w // 2, y, w, 2, a if i % 2 else b)
    c.rect(7, 10, 2, 2, "ink")
    c.rect(2, 13, 12, 1, "wood")
    c.px(13, 4, "yellow")
    c.px(14, 5, "ink")


@tmpl("pot")
def _(c, a, b):
    c.frame(2, 5, 12, 9, a)
    for x in range(4, 13, 2):
        c.vline(x, 5, 9, a)
    c.hline(2, 9, 12, lighter(a))
    c.rect(6, 3, 4, 2, b)
    c.line(8, 3, 11, 0, "straw")


@tmpl("fence")
def _(c, a, b):
    for x in (3, 8, 12):
        c.rect(x, 3, 2, 11, a)
        c.px(x, 3, b)
    c.hline(1, 6, 14, b)
    c.hline(1, 10, 14, b)
    c.hline(1, 7, 14, darker(a))


@tmpl("tile", "rug")
def _(c, a, b):
    c.rect(2, 4, 12, 9, a)
    c.frame(2, 4, 12, 9, darker(a))
    c.frame(4, 6, 8, 5, b)
    c.px(7, 8, b)
    c.px(8, 8, lighter(a))


@tmpl("lantern")
def _(c, a, b):
    c.rect(7, 1, 2, 2, a)
    c.poly([(5, 4), (11, 4), (12, 6), (4, 6)], a)
    c.rect(5, 6, 6, 6, b)
    c.vline(5, 6, 6, a)
    c.vline(10, 6, 6, a)
    c.px(7, 8, "white")
    c.rect(4, 12, 8, 2, a)
    c.px(8, 9, "orange")


@tmpl("sign")
def _(c, a, b):
    c.rect(7, 8, 2, 7, a)
    c.rect(2, 3, 12, 6, lighter(a))
    c.frame(2, 3, 12, 6, darker(a))
    c.hline(4, 5, 8, b)
    c.hline(4, 7, 5, b)


@tmpl("birdhouse")
def _(c, a, b):
    c.rect(7, 10, 2, 5, "wood")
    c.rect(4, 5, 8, 6, a)
    c.poly([(2, 5), (8, 1), (14, 5)], b)
    c.ellipse(8, 7.5, 1.5, 1.5, "ink")
    c.px(8, 10, "bark")


@tmpl("bench")
def _(c, a, b):
    c.rect(1, 7, 14, 3, a)
    c.rect(1, 7, 14, 1, b)
    c.rect(2, 10, 3, 4, darker(a))
    c.rect(11, 10, 3, 4, darker(a))


@tmpl("table")
def _(c, a, b):
    c.poly([(1, 6), (4, 3), (14, 3), (14, 6), (11, 8), (1, 8)], b)
    c.hline(1, 8, 11, a)
    c.rect(2, 9, 2, 5, a)
    c.rect(9, 9, 2, 5, a)
    c.rect(12, 7, 2, 5, darker(a))


@tmpl("chair")
def _(c, a, b):
    c.rect(4, 1, 2, 13, a)
    c.rect(4, 2, 7, 5, b)
    c.rect(4, 8, 8, 3, b)
    c.hline(4, 8, 8, lighter(b))
    c.rect(10, 11, 2, 3, a)
    c.rect(4, 11, 2, 3, a)


@tmpl("shelf")
def _(c, a, b):
    c.rect(3, 1, 10, 14, a)
    c.frame(3, 1, 10, 14, darker(a))
    for y in (2, 6, 10):
        c.rect(4, y, 8, 3, "bark_d")
        for i, x in enumerate(range(4, 12, 2)):
            c.rect(x, y, 2 if i % 3 else 1, 3, [b, "blue", "leaf", "amber"][(i + y) % 4])


@tmpl("painting", "page", "tablet")
def _(c, a, b):
    c.rect(2, 3, 12, 10, "wood" if a == "sky" else a)
    c.rect(3, 4, 10, 8, a)
    if a == "sky":
        c.rect(3, 9, 10, 3, b)
        c.poly([(5, 9), (8, 5), (11, 9)], "stone_l")
        c.px(11, 5, "yellow")
    else:
        for y in (5, 7, 9):
            c.hline(4, y, 7 - (y % 3), b)
        c.px(11, 10, b)
        c.px(10, 6, b)


@tmpl("potplant")
def _(c, a, b):
    c.poly([(5, 14), (4, 9), (12, 9), (11, 14)], b if b != "wood" else "rust")
    c.hline(4, 9, 9, "orange")
    for x, y in ((8, 5), (5, 6), (11, 6), (6, 3), (10, 3)):
        c.ellipse(x, y, 2, 2, a if a != "rose" else "leaf")
    if a == "rose":
        for x, y in ((5, 4), (8, 2), (11, 5), (7, 6)):
            c.px(x, y, a)
            c.px(x + 1, y, "red")
    else:
        c.px(7, 4, lighter(a))


@tmpl("chime")
def _(c, a, b):
    c.hline(3, 2, 10, "wood")
    c.px(8, 1, "bark")
    for i, x in enumerate((4, 6, 8, 10, 12)):
        c.vline(x, 3, 2, "stone_l")
        c.vline(x, 5, 4 + (i * 3) % 5, a)
    c.px(8, 13, b)
    c.px(8, 14, b)


@tmpl("clock")
def _(c, a, b):
    c.rect(4, 1, 8, 14, a)
    c.frame(4, 1, 8, 14, darker(a))
    c.ellipse(8, 5, 2.6, 2.6, b)
    c.px(8, 5, "ink")
    c.px(8, 4, "ink")
    c.px(9, 5, "ink")
    c.vline(8, 9, 4, "amber")
    c.ellipse(8, 13, 1.2, 1.2, "yellow")


@tmpl("roll")
def _(c, a, b):
    c.poly([(3, 12), (10, 4), (13, 7), (6, 15)], a)
    c.line(5, 11, 11, 5, b)
    c.line(7, 13, 12, 8, b)
    c.ellipse(11.5, 5.5, 2, 2, lighter(a))
    c.px(11, 5, darker(a))


@tmpl("key")
def _(c, a, b):
    c.ellipse(5, 5, 3, 3, a)
    c.ellipse(5, 5, 1.2, 1.2, "void")
    c.a[5, 5] = 0
    c.a[4, 5] = 0
    c.a[5, 4] = 0
    c.line(7, 7, 13, 13, a)
    c.px(12, 11, b)
    c.px(13, 12, a)
    c.px(11, 13, a)
    c.px(10, 12, a)


@tmpl("coin")
def _(c, a, b):
    c.ellipse(8, 8.5, 5.5, 5.5, a)
    c.ellipse(8, 8.5, 4, 4, b)
    c.poly([(8, 6), (10, 8), (10, 10), (6, 10), (6, 8)], a)
    c.px(8, 11, darker(a))
    c.px(5, 5, "white")


@tmpl("bead")
def _(c, a, b):
    c.line(2, 4, 13, 12, "straw")
    c.ellipse(8, 8, 3.6, 3.6, a)
    c.ellipse(7, 7, 1.4, 1.4, b)
    c.px(9, 10, darker(a))


def render(spec: str) -> Canvas:
    parts = spec.split(":")
    name = parts[0]
    a = parts[1] if len(parts) > 1 else "stone"
    b = parts[2] if len(parts) > 2 else a
    c = Canvas(S, S)
    if name not in T:
        raise KeyError("gabarit d'icône inconnu : %s" % name)
    T[name](c, a, b)
    c.outline()
    return c


def generate() -> Canvas:
    return sheet([render(o["icon_spec"]) for o in all_items()], COLS, S, S)


if __name__ == "__main__":
    save(generate(), os.path.join(OUT, "icons.png"))
    print("icônes : %d" % len(all_items()))
