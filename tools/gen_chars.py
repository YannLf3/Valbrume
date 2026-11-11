"""Personnages : joueur (3 tenues), 10 PNJ, portraits 48×48 × 3 expressions.

Cellule 16×24. Feuille joueur : 15 colonnes × 4 lignes (bas, haut, droite, gauche)
  0 repos · 1-4 marche · 5-7 outil · 8-9 pêche · 10 port (repos) · 11-14 port (marche)
Feuille PNJ : 5 colonnes (repos + 4 marche) × 4 lignes.
"""
import os
from typing import Dict, List, Optional

from palette import darker, lighter
from px import Canvas, save, sheet

W, H = 16, 24
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites", "chars")
PLAYER_COLS = 15
NPC_COLS = 5


class Look:
    def __init__(self, skin="skin_l", hair="bark", style="short", shirt="blue", pants="navy", shoes="bark_d",
                 hat=None, hat_color="straw", apron=None, glasses=False, beard=False, moustache=False,
                 skirt=False, blush=False, scarf=None, child=False, bg="cream"):
        self.skin, self.hair, self.style = skin, hair, style
        self.shirt, self.pants, self.shoes = shirt, pants, shoes
        self.hat, self.hat_color, self.apron = hat, hat_color, apron
        self.glasses, self.beard, self.moustache = glasses, beard, moustache
        self.skirt, self.blush, self.scarf, self.child, self.bg = skirt, blush, scarf, child, bg
        self.leg = 3 if child else 4
        self.torso = 5 if child else 6


PLAYER_OUTFITS: List[Look] = [
    Look(skin="skin_l", hair="bark", style="short", shirt="blue", pants="bark", shoes="bark_d", scarf="amber"),
    Look(skin="skin", hair="ink2", style="ponytail", shirt="red", pants="navy", shoes="bark_d", scarf="cream"),
    Look(skin="skin_d", hair="ink", style="curly", shirt="leaf", pants="soil_d", shoes="ink2", scarf="yellow"),
]

NPCS: Dict[str, Look] = {
    "capucine": Look("skin_l", "orange", "bun", "leaf_l", "rust", apron="cream", skirt=True, blush=True, bg="lime"),
    "bastien": Look("skin", "ink2", "short", "stone_d", "navy", apron="bark", beard=True, bg="stone_l"),
    "isaure": Look("skin_l", "straw", "ponytail", "red", "blue", shoes="bark", blush=True, bg="sand"),
    "theodule": Look("skin", "silver", "bald", "cream", "leaf_d", hat="straw", hat_color="straw", beard=True, bg="leaf_l"),
    "maiwenn": Look("skin_d", "ink", "long", "teal", "teal_d", shoes="yellow", hat="rain", hat_color="yellow", bg="ice"),
    "hyacinthe": Look("skin_l", "stone_l", "bun", "white", "plum", glasses=True, bg="frost"),
    "gaspard": Look("skin", "rust", "curly", "wine", "bark", apron="cream", moustache=True, bg="straw"),
    "corentin": Look("skin_d", "bark", "long", "violet", "stone_d", glasses=True, scarf="amber", bg="lilac"),
    "roseline": Look("skin_l", "silver", "bun", "lilac", "plum", skirt=True, scarf="rose", bg="blush"),
    "pim": Look("skin_l", "amber", "pigtails", "yellow", "sky", child=True, blush=True, bg="yellow"),
}


def _hair_front(c: Canvas, L: Look, ht: int, tt: int) -> None:
    h = L.hair
    if L.style == "bald":
        c.vline(4, ht + 3, 3, h)
        c.vline(11, ht + 3, 3, h)
        return
    c.hline(5, ht, 6, h)
    c.rect(4, ht + 1, 8, 2, h)
    c.px(4, ht + 3, h)
    c.px(11, ht + 3, h)
    c.px(5, ht + 3, h)
    c.px(6, ht + 1, lighter(h))
    c.px(7, ht + 1, lighter(h))
    if L.style in ("short", "ponytail", "bun"):
        c.px(10, ht + 3, h)
        c.px(4, ht + 4, h)
        c.px(11, ht + 4, h)
    if L.style == "bun":
        c.rect(6, ht - 2, 4, 2, h)
        c.px(6, ht - 2, lighter(h))
    if L.style == "long":
        c.vline(4, ht + 3, 6, h)
        c.vline(11, ht + 3, 6, h)
        c.vline(3, ht + 4, 7, h)
        c.vline(12, ht + 4, 7, h)
    if L.style == "curly":
        for x, y in ((3, 1), (3, 3), (12, 1), (12, 3), (4, 4), (11, 4), (6, -1), (9, -1), (5, 3), (10, 3)):
            c.px(x, ht + y, h)
    if L.style == "pigtails":
        c.rect(2, ht + 3, 2, 4, h)
        c.rect(12, ht + 3, 2, 4, h)
        c.px(3, ht + 2, "red")
        c.px(12, ht + 2, "red")


def _hat(c: Canvas, L: Look, ht: int, view: str) -> None:
    if not L.hat:
        return
    col = L.hat_color
    if L.hat == "straw":
        c.rect(5, ht - 1, 6, 2, col)
        c.hline(5, ht + 1, 6, "rust")
        c.hline(2, ht + 2, 12, col)
        c.hline(3, ht + 2, 3, lighter(col))
    elif L.hat == "rain":
        c.rect(5, ht - 1, 6, 3, col)
        c.px(6, ht - 1, lighter(col))
        if view == "down":
            c.hline(3, ht + 2, 10, col)
        elif view == "up":
            c.hline(3, ht + 2, 10, col)
            c.hline(4, ht + 3, 8, darker(col))
        else:
            c.hline(3, ht + 2, 10, col)
            c.px(2, ht + 3, col)


def human(L: Look, view: str, arms: str = "down", legs: str = "stand", bob: int = 0) -> Canvas:
    c = Canvas(W, H)
    shoe_y = 22
    leg_top = shoe_y - L.leg
    tt = leg_top - L.torso + bob          # haut du torse
    ht = tt - 9                            # haut de la tête (ligne des cheveux)
    sk, sh, pa = L.skin, L.shirt, L.pants
    sh_d, pa_d = darker(sh), darker(pa)

    if view in ("down", "up"):
        # --- jambes
        lift_l = 1 if legs == "stepR" else 0
        lift_r = 1 if legs == "stepL" else 0
        if L.skirt:
            c.rect(4, leg_top, 8, L.leg - 1, pa)
            c.vline(11, leg_top, L.leg - 1, pa_d)
            c.rect(5, shoe_y - 1 - lift_l, 2, 1, sk)
            c.rect(9, shoe_y - 1 - lift_r, 2, 1, sk)
        else:
            c.rect(5, leg_top, 3, L.leg - lift_l, pa)
            c.rect(8, leg_top, 3, L.leg - lift_r, pa)
            c.vline(8, leg_top + 1, L.leg - 1 - lift_r, pa_d)
        c.rect(5, shoe_y - lift_l, 3, 1, L.shoes)
        c.rect(8, shoe_y - lift_r, 3, 1, L.shoes)
        # --- torse
        c.rect(5, tt, 6, leg_top - tt, sh)
        c.vline(10, tt + 1, leg_top - tt - 1, sh_d)
        if L.apron and view == "down":
            c.rect(6, tt + 2, 4, leg_top - tt - 2 + (1 if not L.skirt else 2), L.apron)
            c.px(6, tt + 1, L.apron)
            c.px(9, tt + 1, L.apron)
        if L.scarf:
            c.hline(5, tt, 6, L.scarf)
            if view == "down":
                c.px(6, tt + 1, L.scarf)
        # --- bras
        la = ra = 0
        if arms == "swingA":
            la, ra = -1, 1
        elif arms == "swingB":
            la, ra = 1, -1
        if arms in ("up", "carry"):
            for x in (4, 11):
                c.vline(x, tt - 3, 4, sh)
                c.px(x, tt - 4, sk)
            if arms == "carry":
                c.px(5, tt - 4, sk)
                c.px(10, tt - 4, sk)
        elif arms == "fwd":
            c.vline(4, tt, 3, sh)
            c.vline(11, tt, 3, sh)
            if view == "down":
                c.px(5, tt + 3, sh_d)
                c.px(10, tt + 3, sh_d)
                c.hline(7, tt + 4, 2, sk)
                c.px(6, tt + 4, sh_d)
                c.px(9, tt + 4, sh_d)
            else:
                c.px(4, tt + 3, sk)
                c.px(11, tt + 3, sk)
        else:
            c.vline(4, tt + la, 4, sh)
            c.px(4, tt + la + 4, sk)
            c.vline(11, tt + ra, 4, sh_d)
            c.px(11, tt + ra + 4, sk)
        # --- tête
        c.rect(4, ht + 1, 8, 8, sk)
        for x, y in ((4, ht + 8), (11, ht + 8)):
            c.px(x, y, None)
            c.a[y, x] = 0
        if view == "down":
            c.vline(11, ht + 4, 4, darker(sk))
            c.px(6, ht + 5, "ink")
            c.px(9, ht + 5, "ink")
            if L.child:
                c.px(6, ht + 6, "ink")
                c.px(9, ht + 6, "ink")
            if L.blush:
                c.px(5, ht + 7, "rose")
                c.px(10, ht + 7, "rose")
            if L.glasses:
                for x in (5, 7, 8, 10):
                    c.px(x, ht + 5, "stone_l")
                c.px(6, ht + 4, "stone_l")
                c.px(9, ht + 4, "stone_l")
            if L.beard:
                c.rect(5, ht + 7, 6, 2, L.hair)
                c.px(4, ht + 6, L.hair)
                c.px(11, ht + 6, L.hair)
                c.px(4, ht + 7, L.hair)
                c.px(11, ht + 7, L.hair)
                c.hline(7, ht + 7, 2, darker(sk))
            if L.moustache:
                c.hline(6, ht + 7, 4, L.hair)
            _hair_front(c, L, ht, tt)
        else:
            h = L.hair
            if L.style == "bald":
                c.rect(4, ht + 3, 8, 3, h)
            else:
                c.hline(5, ht, 6, h)
                c.rect(4, ht + 1, 8, 6, h)
                c.px(6, ht + 1, lighter(h))
                if L.style == "long":
                    c.rect(3, ht + 4, 10, 7, h)
                    c.vline(7, ht + 5, 5, darker(h))
                if L.style == "bun":
                    c.rect(6, ht - 2, 4, 2, h)
                if L.style == "curly":
                    for x, y in ((3, 1), (3, 3), (12, 1), (12, 3), (6, -1), (9, -1), (3, 5), (12, 5)):
                        c.px(x, ht + y, h)
                    c.rect(4, ht + 7, 8, 1, h)
                if L.style == "pigtails":
                    c.rect(2, ht + 3, 2, 4, h)
                    c.rect(12, ht + 3, 2, 4, h)
                if L.style == "ponytail":
                    c.rect(7, ht + 5, 2, 6, h)
                    c.px(7, ht + 4, "red")
                    c.px(8, ht + 4, "red")
        _hat(c, L, ht, view)
    else:
        # --- profil (vers la droite)
        if L.skirt:
            c.rect(5, leg_top, 6, L.leg - 1, pa)
            c.vline(5, leg_top, L.leg - 1, pa_d)
            c.rect(7, shoe_y - 1, 2, 1, sk)
            c.rect(7, shoe_y, 3, 1, L.shoes)
            if legs == "stepL":
                c.rect(5, shoe_y, 2, 1, L.shoes)
                c.rect(9, shoe_y, 3, 1, L.shoes)
        elif legs == "stepL":
            c.rect(5, leg_top, 3, L.leg, pa_d)
            c.rect(8, leg_top, 3, L.leg, pa)
            c.rect(4, shoe_y, 3, 1, L.shoes)
            c.rect(9, shoe_y, 3, 1, L.shoes)
        elif legs == "stepR":
            c.rect(6, leg_top, 3, L.leg - 1, pa_d)
            c.rect(7, leg_top, 3, L.leg, pa)
            c.rect(5, shoe_y - 1, 2, 1, L.shoes)
            c.rect(7, shoe_y, 4, 1, L.shoes)
        else:
            c.rect(6, leg_top, 4, L.leg, pa)
            c.vline(6, leg_top, L.leg, pa_d)
            c.rect(6, shoe_y, 5, 1, L.shoes)
        c.rect(6, tt, 5, leg_top - tt, sh)
        c.vline(6, tt + 1, leg_top - tt - 1, sh_d)
        if L.apron:
            c.rect(9, tt + 2, 2, leg_top - tt - 1, L.apron)
        if L.scarf:
            c.hline(6, tt, 5, L.scarf)
        # bras
        sx, sy = 8, tt + 1
        if arms == "swingA":
            ex, ey = 10, tt + 4
        elif arms == "swingB":
            ex, ey = 6, tt + 4
        elif arms == "up":
            ex, ey = 11, tt - 4
        elif arms == "carry":
            ex, ey = 9, tt - 4
        elif arms == "fwd":
            ex, ey = 12, tt + 2
        else:
            ex, ey = 8, tt + 5
        c.line(sx, sy, ex, ey, sh_d)
        c.line(sx - 1, sy, ex - 1, ey, sh_d if arms in ("down", "swingA", "swingB") else sh)
        c.px(ex, ey, sk)
        c.px(ex - 1, ey, sk)
        # tête
        c.rect(4, ht + 1, 8, 8, sk)
        c.a[ht + 8, 4] = 0
        c.a[ht + 8, 11] = 0
        c.px(12, ht + 6, sk)
        c.px(9, ht + 5, "ink")
        if L.child:
            c.px(9, ht + 6, "ink")
        if L.blush:
            c.px(10, ht + 7, "rose")
        if L.glasses:
            c.px(8, ht + 5, "stone_l")
            c.px(10, ht + 5, "stone_l")
            c.px(9, ht + 4, "stone_l")
        h = L.hair
        if L.beard:
            c.rect(8, ht + 7, 4, 2, h)
            c.px(7, ht + 6, h)
        if L.moustache:
            c.hline(10, ht + 7, 3, h)
        if L.style == "bald":
            c.rect(4, ht + 3, 3, 3, h)
        else:
            c.hline(5, ht, 6, h)
            c.rect(4, ht + 1, 8, 2, h)
            c.rect(4, ht + 3, 4, 3, h)
            c.px(7, ht + 5, sk)
            c.px(6, ht + 1, lighter(h))
            if L.style == "long":
                c.rect(3, ht + 4, 4, 7, h)
            if L.style == "bun":
                c.rect(3, ht, 3, 3, h)
            if L.style == "curly":
                for x, y in ((3, 1), (3, 3), (6, -1), (9, -1), (3, 5), (12, 1), (8, 3)):
                    c.px(x, ht + y, h)
            if L.style == "pigtails":
                c.rect(2, ht + 3, 2, 4, h)
                c.px(3, ht + 2, "red")
            if L.style == "ponytail":
                c.rect(2, ht + 3, 2, 5, h)
                c.px(3, ht + 2, "red")
                c.px(2, ht + 8, h)
        _hat(c, L, ht, view)
    c.outline()
    return c


def frames_for(L: Look, cols: int) -> List[Canvas]:
    out: List[Canvas] = []
    walk = [("swingA", "stepL", 0), ("down", "stand", 0), ("swingB", "stepR", 0), ("down", "stand", 0)]
    for view in ("down", "up", "right", "left"):
        v = "right" if view == "left" else view
        row: List[Canvas] = [human(L, v)]
        for a, l, b in walk:
            row.append(human(L, v, a, l, b))
        if cols == PLAYER_COLS:
            row.append(human(L, v, "up"))
            row.append(human(L, v, "fwd", "stepL"))
            row.append(human(L, v, "fwd", "stepL", 1))
            row.append(human(L, v, "up", "stepL"))
            row.append(human(L, v, "fwd"))
            row.append(human(L, v, "carry"))
            for a, l, b in walk:
                row.append(human(L, v, "carry", l, b))
        if view == "left":
            row = [f.flipped() for f in row]
        out += row
    return out


# --- portraits ---------------------------------------------------------------

def portrait(L: Look, mood: str) -> Canvas:
    P = 48
    c = Canvas(P, P)
    sk, h = L.skin, L.hair
    sk_d = darker(sk)
    cy = 24 if not L.child else 26
    # épaules
    c.ellipse(24, 52, 21, 15, darker(L.shirt))
    c.ellipse(23, 52, 20, 15, L.shirt)
    if L.apron:
        c.rect(17, 40, 14, 8, L.apron)
        c.line(17, 40, 14, 34, L.apron)
        c.line(30, 40, 33, 34, L.apron)
    # cheveux longs derrière
    if L.style == "long":
        c.rect(9, 14, 30, 30, h)
        c.rect(9, 30, 5, 14, darker(h))
    if L.style == "ponytail":
        c.ellipse(38, 30, 4, 9, h)
    if L.style == "pigtails":
        c.ellipse(7, cy + 4, 4, 7, h)
        c.ellipse(41, cy + 4, 4, 7, h)
        c.rect(9, cy - 3, 2, 2, "red")
        c.rect(37, cy - 3, 2, 2, "red")
    # cou
    c.rect(20, cy + 10, 9, 8, sk_d)
    c.rect(20, cy + 10, 7, 7, sk)
    if L.scarf:
        c.ellipse(24, cy + 16, 10, 3, L.scarf)
        c.rect(26, cy + 16, 4, 7, L.scarf)
        c.rect(29, cy + 17, 1, 6, darker(L.scarf))
    # tête
    c.ellipse(24, cy, 12, 13, sk_d)
    c.ellipse(23.3, cy - 0.5, 11.2, 12.4, sk)
    c.ellipse(11.5, cy + 2, 1.6, 2.5, sk)
    c.ellipse(36.5, cy + 2, 1.6, 2.5, sk_d)
    # cheveux
    if L.style == "bald":
        c.ellipse(12, cy - 2, 3, 5, h)
        c.ellipse(36, cy - 2, 3, 5, h)
        c.ellipse(21, cy - 9, 4, 2, lighter(sk))
    else:
        for y in range(cy - 15, cy - 3):
            for x in range(8, 41):
                if ((x - 24) / 13.5) ** 2 + ((y - (cy - 3)) / 12.5) ** 2 <= 1.0:
                    fringe = cy - 7 + (1 if (x // 3) % 2 == 0 else 0) + (2 if x < 14 or x > 34 else 0)
                    if L.style in ("long", "pigtails"):
                        fringe = cy - 8 + abs(x - 24) // 4
                    if y < fringe:
                        c.px(x, y, h)
        c.line(16, cy - 12, 22, cy - 14, lighter(h))
        c.line(17, cy - 11, 20, cy - 12, lighter(h))
        if L.style in ("short", "bun", "ponytail", "curly"):
            c.rect(11, cy - 6, 2, 5, h)
            c.rect(35, cy - 6, 2, 5, h)
        if L.style == "bun":
            c.ellipse(24, cy - 16, 5, 4, h)
            c.px(22, cy - 18, lighter(h))
        if L.style == "curly":
            for x, y in ((11, -10), (14, -14), (19, -16), (25, -17), (31, -15), (35, -12), (37, -8), (10, -5), (38, -4)):
                c.ellipse(x, cy + y, 3, 3, h)
            c.px(18, cy - 16, lighter(h))
    if L.hat == "straw":
        c.ellipse(24, cy - 10, 21, 4, darker(L.hat_color))
        c.ellipse(24, cy - 11, 21, 3.5, L.hat_color)
        c.ellipse(24, cy - 15, 10, 6, L.hat_color)
        c.rect(15, cy - 13, 19, 2, "rust")
        c.line(17, cy - 18, 21, cy - 19, lighter(L.hat_color))
    if L.hat == "rain":
        c.ellipse(24, cy - 13, 12, 8, L.hat_color)
        c.ellipse(24, cy - 8, 17, 3.5, darker(L.hat_color))
        c.ellipse(24, cy - 9, 17, 3, L.hat_color)
        c.line(18, cy - 18, 22, cy - 19, lighter(L.hat_color))
    # sourcils
    bc = darker(h) if h not in ("ink", "ink2") else "ink"
    if L.style == "bald" or h in ("silver", "stone_l"):
        bc = "stone"
    ey = cy + 1
    if mood == "sad":
        c.line(16, ey - 4, 20, ey - 5, bc)
        c.line(27, ey - 5, 31, ey - 4, bc)
    elif mood == "happy":
        c.line(16, ey - 5, 20, ey - 6, bc)
        c.line(27, ey - 6, 31, ey - 5, bc)
    else:
        c.hline(16, ey - 4, 5, bc)
        c.hline(27, ey - 4, 5, bc)
    # yeux
    for ex in (17, 28):
        if mood == "happy":
            c.px(ex, ey + 1, "ink")
            c.px(ex + 1, ey, "ink")
            c.px(ex + 2, ey, "ink")
            c.px(ex + 3, ey + 1, "ink")
        else:
            c.rect(ex, ey - 1, 3, 4 if L.child else 3, "ink")
            c.px(ex, ey - 1, "white")
            if mood == "sad":
                c.px(ex + 2, ey + 3, "sky")
    if L.glasses:
        c.frame(14, ey - 3, 9, 8, "ink2")
        c.frame(25, ey - 3, 9, 8, "ink2")
        c.hline(22, ey, 4, "ink2")
        c.px(15, ey - 2, "white")
        c.px(26, ey - 2, "white")
    # nez
    c.px(24, ey + 4, sk_d)
    c.px(23, ey + 5, sk_d)
    c.px(24, ey + 5, sk_d)
    # joues
    if L.blush or mood == "happy":
        c.rect(14, ey + 5, 3, 2, "rose" if sk != "skin_d" else "rust")
        c.rect(30, ey + 5, 3, 2, "rose" if sk != "skin_d" else "rust")
    # barbe et moustache
    my = cy + 9
    if L.beard:
        for y in range(cy + 3, cy + 16):
            for x in range(10, 38):
                if ((x - 24) / 12.0) ** 2 + ((y - (cy + 3)) / 12.0) ** 2 <= 1.0 and y > cy + 5 + abs(x - 24) // 6:
                    if not (20 <= x <= 27 and my - 1 <= y <= my + 1):
                        c.px(x, y, h)
        c.rect(19, my - 3, 10, 2, h)
    if L.moustache:
        c.rect(19, my - 3, 10, 2, h)
        c.px(18, my - 2, h)
        c.px(29, my - 2, h)
        c.px(17, my - 1, h)
        c.px(30, my - 1, h)
    # bouche
    if mood == "happy":
        c.px(20, my - 1, "wine")
        c.hline(21, my, 6, "wine")
        c.px(27, my - 1, "wine")
        c.hline(22, my + 1, 4, "red")
    elif mood == "sad":
        c.px(21, my + 1, "wine")
        c.hline(22, my, 4, "wine")
        c.px(26, my + 1, "wine")
    else:
        c.hline(21, my, 5, "wine")
    c.outline()
    out = Canvas(P, P, L.bg)
    for i in range(0, P, 6):
        out.dither(0, i, P, 2, lighter(L.bg) if lighter(L.bg) != L.bg else darker(L.bg), i // 6)
    out.blit(c, 0, 0)
    return out


def generate() -> Dict[str, Canvas]:
    out: Dict[str, Canvas] = {}
    for i, L in enumerate(PLAYER_OUTFITS):
        out["player_%d" % i] = sheet(frames_for(L, PLAYER_COLS), PLAYER_COLS, W, H)
        out["portrait_player_%d" % i] = sheet([portrait(L, m) for m in ("neutral", "happy", "sad")], 3, 48, 48)
    for name, L in NPCS.items():
        out["npc_" + name] = sheet(frames_for(L, NPC_COLS), NPC_COLS, W, H)
        out["portrait_" + name] = sheet([portrait(L, m) for m in ("neutral", "happy", "sad")], 3, 48, 48)
    return out


def main() -> int:
    n = 0
    for name, c in generate().items():
        save(c, os.path.join(OUT, name + ".png"))
        n += (c.w // 48) * (c.h // 48) if name.startswith("portrait") else (c.w // W) * (c.h // H)
    return n


if __name__ == "__main__":
    print("personnages : %d images" % main())
