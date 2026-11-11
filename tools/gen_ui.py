"""Interface : panneaux 9-slice, boutons, icônes de HUD, commandes tactiles, particules, logo, fond du titre."""
import math
import os
from typing import Dict

import numpy as np
from PIL import Image

import gen_font
from palette import RGBA, INDEX, darker, lighter
from px import Canvas, rng_for

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "ui")


def panel(fill: str, border: str, inner: str, shadow: str = "ink") -> Canvas:
    c = Canvas(24, 24)
    c.rect(1, 1, 22, 22, shadow)
    c.rect(1, 0, 22, 23, border)
    c.rect(0, 1, 24, 21, border)
    c.rect(2, 2, 20, 19, inner)
    c.rect(3, 3, 18, 17, fill)
    for x, y in ((3, 3), (20, 3), (3, 19), (20, 19)):
        c.px(x, y, inner)
    c.hline(1, 23, 22, shadow)
    c.hline(3, 3, 18, lighter(fill)) if lighter(fill) != fill else None
    return c


def button(state: str) -> Canvas:
    fill, edge, hi = {"normal": ("wood_l", "bark", "straw"), "hover": ("straw", "bark", "cream"),
                      "pressed": ("wood", "bark_d", "wood_l"), "disabled": ("stone_l", "stone_d", "silver")}[state]
    c = Canvas(24, 18)
    dy = 1 if state == "pressed" else 0
    c.rect(1, 0 + dy, 22, 16, edge)
    c.rect(0, 1 + dy, 24, 14, edge)
    c.rect(1, 1 + dy, 22, 14, fill)
    c.hline(2, 1 + dy, 20, hi)
    c.hline(2, 14 + dy, 20, darker(fill))
    if not dy:
        c.rect(1, 16, 22, 2, "ink2")
        c.rect(0, 15, 1, 2, "ink2")
        c.rect(23, 15, 1, 2, "ink2")
    return c


def slot(selected: bool) -> Canvas:
    c = Canvas(20, 20)
    c.rect(0, 0, 20, 20, "bark")
    c.rect(1, 1, 18, 18, "soil_l")
    c.rect(2, 2, 17, 17, "sand")
    c.hline(1, 1, 18, "soil")
    c.vline(1, 1, 18, "soil")
    if selected:
        c.frame(0, 0, 20, 20, "red")
        c.frame(1, 1, 18, 18, "amber")
        for x, y in ((0, 0), (19, 0), (0, 19), (19, 19)):
            c.px(x, y, "wine")
    return c


def tab(on: bool) -> Canvas:
    c = Canvas(24, 16)
    c.rect(1, 0, 22, 16, "bark")
    c.rect(0, 2, 24, 14, "bark")
    c.rect(2, 2, 20, 14, "cream" if on else "wood_l")
    c.hline(2, 2, 20, "white" if on else "straw")
    if not on:
        c.hline(0, 15, 24, "bark")
    return c


def bar_frame() -> Canvas:
    c = Canvas(16, 8)
    c.rect(1, 0, 14, 8, "ink")
    c.rect(0, 1, 16, 6, "ink")
    c.rect(1, 1, 14, 6, "bark_d")
    return c


def solid(col: str, hi: str) -> Canvas:
    c = Canvas(4, 6, col)
    c.hline(0, 0, 4, hi)
    c.hline(0, 5, 4, darker(col))
    return c


def season_icon(i: int) -> Canvas:
    c = Canvas(12, 12)
    if i == 0:
        for dx, dy in ((0, -3), (-3, 0), (3, 0), (0, 3)):
            c.ellipse(5.5 + dx, 5.5 + dy, 1.7, 1.7, "rose")
        c.ellipse(5.5, 5.5, 1.5, 1.5, "yellow")
    elif i == 1:
        c.ellipse(5.5, 5.5, 3, 3, "amber")
        c.px(5, 5, "yellow")
        for a in range(8):
            c.px(5.5 + 5 * math.cos(a * math.pi / 4) + 0.5, 5.5 + 5 * math.sin(a * math.pi / 4) + 0.5, "orange")
    elif i == 2:
        c.poly([(2, 7), (5, 1), (9, 3), (10, 7), (6, 10)], "orange")
        c.line(3, 10, 8, 4, "rust")
        c.px(5, 3, "amber")
    else:
        for a in range(6):
            c.line(5.5, 5.5, 5.5 + 5 * math.cos(a * math.pi / 3), 5.5 + 5 * math.sin(a * math.pi / 3), "ice")
        c.px(5, 5, "white")
        c.px(6, 6, "white")
    c.outline()
    return c


def weather_icon(kind: str) -> Canvas:
    c = Canvas(12, 12)
    def cloud(col: str, y: int = 4) -> None:
        c.ellipse(4, y + 1, 3, 2.2, col)
        c.ellipse(7, y, 3, 2.6, col)
        c.rect(2, y + 1, 8, 2, col)
    if kind == "sun":
        return season_icon(1)
    if kind == "rain":
        cloud("stone_l")
        for x in (3, 6, 9):
            c.line(x, 8, x - 1, 10, "sky")
    elif kind == "storm":
        cloud("stone")
        c.poly([(6, 6), (4, 9), (6, 9), (5, 11), (8, 8), (6, 8)], "yellow")
    elif kind == "wind":
        c.hline(1, 3, 7, "silver")
        c.px(8, 2, "silver")
        c.hline(2, 6, 8, "white")
        c.px(10, 5, "white")
        c.hline(1, 9, 5, "silver")
        c.px(8, 8, "leaf_l")
    else:
        cloud("silver")
        for x, y in ((3, 8), (6, 10), (9, 8), (5, 8)):
            c.px(x, y, "white")
    c.outline()
    return c


def skill_icon(kind: str) -> Canvas:
    c = Canvas(12, 12)
    if kind == "farming":
        c.vline(6, 4, 7, "leaf")
        c.ellipse(3.5, 4, 2.2, 1.6, "leaf_l")
        c.ellipse(8.5, 5, 2.2, 1.6, "leaf")
        c.hline(3, 10, 7, "soil")
    elif kind == "husbandry":
        c.ellipse(6, 6.5, 3.5, 4.2, "cream")
        c.px(5, 4, "white")
        c.px(7, 8, "straw")
    elif kind == "fishing":
        c.ellipse(6, 6, 3.5, 2.5, "sky")
        c.poly([(2, 6), (0, 4), (0, 8)], "blue")
        c.px(8, 5, "ink")
        c.hline(4, 7, 4, "ice")
    elif kind == "mining":
        c.line(2, 10, 8, 4, "wood")
        c.line(4, 2, 10, 4, "stone_l")
        c.line(10, 4, 10, 7, "stone_l")
    elif kind == "combat":
        c.line(3, 9, 9, 2, "silver")
        c.line(2, 7, 5, 10, "amber")
        c.px(2, 10, "bark")
    else:
        c.rect(5, 6, 2, 5, "cream")
        c.ellipse(6, 4.5, 4, 2.6, "rust")
        c.px(4, 4, "cream")
        c.px(8, 5, "cream")
    c.outline()
    return c


def heart(full: bool) -> Canvas:
    c = Canvas(9, 8)
    col = "red" if full else "stone_d"
    c.ellipse(2.5, 2.5, 1.8, 1.8, col)
    c.ellipse(5.5, 2.5, 1.8, 1.8, col)
    c.poly([(1, 3), (7, 3), (4, 6)], col)
    if full:
        c.px(2, 2, "rose")
    c.outline("wine" if full else "ink")
    return c


def star(col: str) -> Canvas:
    c = Canvas(7, 7)
    c.poly([(3, 0), (4, 2), (6, 2), (4, 4), (5, 6), (3, 5), (1, 6), (2, 4), (0, 2), (2, 2)], col)
    c.px(3, 2, "white")
    return c


def coin() -> Canvas:
    c = Canvas(10, 10)
    c.ellipse(4.5, 4.5, 4, 4, "amber")
    c.ellipse(4.5, 4.5, 2.5, 2.5, "yellow")
    c.px(4, 4, "amber")
    c.px(5, 5, "amber")
    c.px(3, 2, "white")
    c.outline()
    return c


def tile_cursor(col: str) -> Canvas:
    c = Canvas(16, 16)
    for x, y, dx, dy in ((0, 0, 1, 1), (15, 0, -1, 1), (0, 15, 1, -1), (15, 15, -1, -1)):
        for k in range(5):
            c.px(x + dx * k, y, col)
            c.px(x, y + dy * k, col)
        c.px(x + dx, y + dy, "white")
    return c


def cursor(kind: str) -> Canvas:
    c = Canvas(12, 14)
    if kind == "arrow":
        c.poly([(1, 1), (1, 10), (4, 8), (6, 12), (8, 11), (6, 7), (9, 7)], "white")
    else:
        c.rect(4, 1, 2, 7, "skin_l")
        c.rect(6, 4, 5, 5, "skin_l")
        c.rect(2, 6, 2, 4, "skin_l")
        c.rect(3, 8, 8, 4, "skin_l")
        c.px(7, 5, "skin")
        c.px(9, 5, "skin")
    c.outline("ink")
    return c


def joystick(base: bool) -> Canvas:
    s = 56 if base else 26
    c = Canvas(s, s)
    r = s / 2 - 1
    c.ellipse(s / 2 - 0.5, s / 2 - 0.5, r, r, "ink2" if base else "cream")
    c.ellipse(s / 2 - 0.5, s / 2 - 0.5, r - 2, r - 2, "stone_d" if base else "straw")
    if base:
        c.ellipse(s / 2 - 0.5, s / 2 - 0.5, r - 5, r - 5, "ink2")
        for a in range(4):
            c.px(s / 2 + (r - 3) * math.cos(a * math.pi / 2), s / 2 + (r - 3) * math.sin(a * math.pi / 2), "silver")
    else:
        c.ellipse(s / 2 - 2, s / 2 - 3, 4, 3, "cream")
    return c


def touch_button(glyph: str) -> Canvas:
    s = 36
    c = Canvas(s, s)
    c.ellipse(17.5, 18.5, 17, 17, "ink")
    c.ellipse(17.5, 17.5, 17, 17, "bark")
    c.ellipse(17.5, 17.5, 15, 15, "wood_l")
    c.ellipse(17.5, 16.5, 14, 13.5, "straw")
    g = "bark_d"
    if glyph == "action":
        c.rect(15, 9, 3, 10, g)
        c.rect(19, 12, 3, 8, g)
        c.rect(23, 14, 3, 7, g)
        c.rect(11, 15, 3, 7, g)
        c.rect(12, 19, 14, 8, g)
    elif glyph == "tool":
        c.line(11, 26, 22, 13, g)
        c.line(12, 27, 23, 14, g)
        c.poly([(18, 9), (26, 9), (28, 13), (23, 17)], g)
    elif glyph == "menu":
        for y in (11, 17, 23):
            c.rect(10, y, 16, 3, g)
    elif glyph == "bag":
        c.rect(11, 14, 14, 13, g)
        c.frame(14, 9, 8, 6, g)
        c.rect(16, 19, 4, 3, "straw")
    elif glyph == "cancel":
        c.line(11, 11, 24, 24, g)
        c.line(12, 11, 25, 24, g)
        c.line(24, 11, 11, 24, g)
        c.line(25, 11, 12, 24, g)
    return c


def small_glyph(kind: str) -> Canvas:
    c = Canvas(10, 10)
    if kind == "arrow_right":
        c.poly([(3, 1), (7, 5), (3, 9)], "bark_d")
    elif kind == "arrow_left":
        c.poly([(6, 1), (2, 5), (6, 9)], "bark_d")
    elif kind == "arrow_up":
        c.poly([(1, 6), (5, 2), (9, 6)], "bark_d")
    elif kind == "arrow_down":
        c.poly([(1, 3), (5, 7), (9, 3)], "bark_d")
    elif kind == "check_on":
        c.rect(0, 0, 10, 10, "bark")
        c.rect(1, 1, 8, 8, "cream")
        c.line(2, 5, 4, 7, "leaf_d")
        c.line(4, 7, 8, 2, "leaf_d")
        c.line(2, 4, 4, 6, "leaf")
    elif kind == "check_off":
        c.rect(0, 0, 10, 10, "bark")
        c.rect(1, 1, 8, 8, "cream")
    elif kind == "close":
        c.rect(0, 0, 10, 10, "wine")
        c.rect(1, 1, 8, 8, "red")
        c.line(2, 2, 7, 7, "white")
        c.line(7, 2, 2, 7, "white")
    elif kind == "knob":
        c.rect(2, 0, 6, 10, "bark")
        c.rect(3, 1, 4, 8, "straw")
    elif kind == "lock":
        c.rect(2, 4, 6, 5, "stone_d")
        c.frame(3, 1, 4, 4, "stone_d")
        c.px(5, 6, "ink")
    elif kind == "gift":
        c.rect(1, 4, 8, 5, "red")
        c.rect(4, 4, 2, 5, "amber")
        c.rect(1, 3, 8, 2, "rose")
        c.px(3, 2, "amber")
        c.px(6, 2, "amber")
    elif kind == "talk":
        c.rect(1, 1, 8, 6, "white")
        c.px(3, 7, "white")
        c.px(2, 8, "white")
        c.hline(3, 3, 4, "stone")
        c.outline("ink2")
    return c


def emote(kind: str) -> Canvas:
    c = Canvas(14, 14)
    c.rect(1, 1, 12, 9, "white")
    c.rect(0, 2, 14, 7, "white")
    c.px(4, 10, "white")
    c.px(5, 10, "white")
    c.px(4, 11, "white")
    if kind == "heart":
        c.blit(heart(True), 3, 2)
    elif kind == "exclaim":
        c.rect(6, 2, 2, 4, "red")
        c.rect(6, 7, 2, 2, "red")
    elif kind == "question":
        c.hline(5, 2, 4, "blue")
        c.px(9, 3, "blue")
        c.px(8, 4, "blue")
        c.px(7, 5, "blue")
        c.px(7, 7, "blue")
        c.px(4, 3, "blue")
    elif kind == "zzz":
        for x, y in ((3, 6), (7, 4), (10, 2)):
            c.hline(x, y, 3, "navy")
            c.px(x + 1, y + 1, "navy")
            c.hline(x, y + 2, 3, "navy")
    elif kind == "note":
        c.vline(8, 2, 5, "plum")
        c.hline(8, 2, 3, "plum")
        c.ellipse(6.5, 7, 1.6, 1.2, "plum")
    elif kind == "happy":
        c.px(4, 4, "ink")
        c.px(9, 4, "ink")
        c.px(4, 6, "ink")
        c.hline(5, 7, 4, "ink")
        c.px(9, 6, "ink")
    elif kind == "sad":
        c.px(4, 4, "ink")
        c.px(9, 4, "ink")
        c.hline(5, 6, 4, "ink")
        c.px(4, 7, "ink")
        c.px(9, 7, "ink")
        c.px(10, 5, "sky")
    elif kind == "fish":
        c.rect(6, 2, 2, 5, "amber")
        c.rect(6, 8, 2, 1, "amber")
        c.px(4, 3, "amber")
        c.px(9, 3, "amber")
    c.outline("ink2")
    return c


def particle(kind: str) -> Canvas:
    spec = {
        "rain": (2, 6, [(1, 0, "ice"), (1, 1, "ice"), (0, 2, "sky"), (0, 3, "sky"), (0, 4, "blue")]),
        "snow": (3, 3, [(1, 0, "white"), (0, 1, "white"), (1, 1, "white"), (2, 1, "frost"), (1, 2, "frost")]),
        "leaf_a": (5, 4, [(1, 0, "orange"), (2, 0, "orange"), (0, 1, "amber"), (1, 1, "orange"), (2, 1, "rust"), (3, 1, "orange"), (2, 2, "rust"), (3, 2, "orange"), (4, 3, "bark")]),
        "leaf_b": (5, 4, [(1, 0, "leaf_l"), (2, 0, "leaf"), (0, 1, "leaf_l"), (1, 1, "leaf"), (2, 1, "leaf_d"), (3, 1, "leaf"), (2, 2, "leaf"), (4, 3, "leaf_d")]),
        "petal": (3, 3, [(1, 0, "blush"), (0, 1, "rose"), (1, 1, "blush"), (2, 2, "rose")]),
        "splash": (5, 3, [(0, 2, "ice"), (1, 1, "frost"), (2, 0, "white"), (3, 1, "frost"), (4, 2, "ice"), (2, 2, "sky")]),
        "sparkle": (5, 5, [(2, 0, "yellow"), (2, 1, "white"), (0, 2, "yellow"), (1, 2, "white"), (2, 2, "white"), (3, 2, "white"), (4, 2, "yellow"), (2, 3, "white"), (2, 4, "yellow")]),
        "dust": (4, 4, [(1, 0, "sand"), (2, 0, "sand"), (0, 1, "sand"), (1, 1, "cream"), (2, 1, "sand"), (3, 1, "soil_l"), (1, 2, "sand"), (2, 2, "soil_l"), (0, 2, "soil_l"), (2, 3, "soil_l")]),
        "smoke": (5, 5, [(1, 0, "silver"), (2, 0, "silver"), (3, 0, "stone_l"), (0, 1, "silver"), (1, 1, "white"), (2, 1, "silver"), (3, 1, "silver"), (4, 1, "stone_l"), (0, 2, "silver"), (1, 2, "silver"), (2, 2, "silver"), (3, 2, "stone_l"), (4, 2, "stone_l"), (1, 3, "stone_l"), (2, 3, "stone_l"), (3, 3, "stone_l")]),
        "chip": (3, 3, [(0, 0, "stone_l"), (1, 0, "stone"), (0, 1, "stone"), (1, 1, "stone_l"), (2, 1, "stone_d"), (1, 2, "stone_d")]),
        "wood": (3, 3, [(0, 0, "wood_l"), (1, 0, "wood"), (1, 1, "wood_l"), (2, 1, "bark"), (2, 2, "wood")]),
        "drop": (2, 3, [(0, 0, "ice"), (0, 1, "sky"), (1, 1, "sky"), (0, 2, "blue")]),
        "heart": (5, 5, [(1, 0, "red"), (3, 0, "red"), (0, 1, "red"), (1, 1, "rose"), (2, 1, "red"), (3, 1, "red"), (4, 1, "red"), (1, 2, "red"), (2, 2, "red"), (3, 2, "red"), (2, 3, "wine")]),
        "note": (4, 6, [(2, 0, "plum"), (3, 0, "plum"), (2, 1, "plum"), (2, 2, "plum"), (2, 3, "plum"), (0, 4, "plum"), (1, 4, "violet"), (2, 4, "plum"), (0, 5, "plum"), (1, 5, "plum")]),
        "frost": (6, 6, [(2, 0, "frost"), (3, 0, "ice"), (1, 1, "ice"), (2, 1, "white"), (3, 1, "frost"), (4, 1, "sky"), (0, 2, "ice"), (1, 2, "frost"), (2, 2, "white"), (3, 2, "white"), (4, 2, "ice"), (5, 2, "sky"), (1, 3, "ice"), (2, 3, "frost"), (3, 3, "ice"), (4, 3, "sky"), (2, 4, "sky"), (3, 4, "blue")]),
    }[kind]
    w, h, pts = spec
    c = Canvas(w, h)
    for x, y, col in pts:
        c.px(x, y, col)
    return c


def bobber() -> Canvas:
    c = Canvas(5, 7)
    c.rect(1, 1, 3, 2, "red")
    c.rect(1, 3, 3, 2, "white")
    c.px(2, 0, "ink2")
    c.px(2, 5, "stone")
    c.outline("ink")
    return c


def slash() -> Canvas:
    c = Canvas(28, 28)
    for a in range(-50, 51, 2):
        rad = math.radians(a)
        for rr, col in ((12, "white"), (11, "frost"), (10, "ice")):
            if abs(a) < 50 - (12 - rr) * 9:
                c.px(13 + rr * math.cos(rad), 13 + rr * math.sin(rad), col)
    return c


def shadow() -> Canvas:
    c = Canvas(14, 6)
    c.ellipse(6.5, 2.5, 6.5, 2.5, "ink")
    return c


def logo() -> Canvas:
    text = "Valbrume"
    sc = 3
    glyphs = gen_font.all_glyphs()
    w = sum((len(glyphs[ch][0]) + 1) * sc for ch in text) + 30
    c = Canvas(w, gen_font.CELL_H * sc + 10)
    x = 26
    for ch in text:
        g = glyphs[ch]
        for j in range(gen_font.CELL_H):
            for i in range(len(g[0])):
                if g[j][i]:
                    col = "yellow" if j < 6 else ("amber" if j < 9 else "orange")
                    c.rect(x + i * sc, 2 + j * sc, sc, sc, col)
        x += (len(g[0]) + 1) * sc
    # cloche-emblème
    c.poly([(11, 12), (17, 16), (19, 30), (22, 33), (0, 33), (3, 30), (5, 16)], "amber")
    c.rect(9, 8, 4, 4, "orange")
    c.vline(7, 16, 14, "yellow")
    c.hline(0, 33, 23, "orange")
    c.rect(9, 34, 4, 3, "orange")
    c.line(11, 8, 13, 3, "leaf")
    c.ellipse(15, 3, 2.5, 1.6, "leaf_l")
    c.outline("bark_d", diagonal=True)
    out = Canvas(c.w + 2, c.h + 3)
    sh = c.copy()
    sh.a[sh.a > 0] = INDEX["ink"]
    out.blit(sh, 1, 3)
    out.blit(c, 1, 1)
    return out


def title_bg() -> Canvas:
    w, h = 640, 270
    c = Canvas(w, h, "sky")
    r = rng_for("titlebg")
    c.rect(0, 0, w, 60, "blue")
    c.dither(0, 52, w, 16, "sky")
    c.rect(0, 120, w, 60, "ice")
    c.dither(0, 108, w, 20, "ice")
    c.rect(0, 160, w, 40, "frost")
    c.dither(0, 150, w, 16, "frost")
    c.ellipse(500, 70, 22, 22, "cream")
    c.ellipse(500, 70, 18, 18, "white")
    for cx, cy, s in ((90, 50, 1.0), (300, 80, 1.3), (560, 120, 0.9), (200, 110, 0.8)):
        for dx, rx in ((-18, 14), (0, 20), (20, 13)):
            c.ellipse(cx + dx * s, cy, rx * s, 7 * s, "white")
        c.rect(cx - 30 * s, cy, 62 * s, 5 * s, "white")

    def hills(base_y: float, amp: float, freq: float, col: str, col2: str, phase: float) -> None:
        for x in range(w):
            y = int(base_y + amp * math.sin(x * freq + phase) + amp * 0.5 * math.sin(x * freq * 2.3 + phase * 2))
            c.vline(x, y, h - y, col)
            c.px(x, y, col2)
            if x % 3 == 0:
                c.px(x, y + 1, col2)
    hills(170, 14, 0.012, "teal", "ice", 0.5)
    hills(195, 12, 0.02, "leaf", "leaf_l", 2.0)
    # village lointain
    for x in range(250, 430, 22):
        hh = r.randint(10, 16)
        y = int(195 + 12 * math.sin(x * 0.02 + 2.0) + 6 * math.sin(x * 0.046 + 4.0)) - hh + 3
        c.rect(x, y, 14, hh, "cream")
        c.poly([(x - 2, y), (x + 7, y - 8), (x + 16, y)], "rust")
        c.px(x + 4, y + 4, "amber")
        c.px(x + 9, y + 5, "amber")
    bx, by = 340, 138
    c.rect(bx, by, 14, 56, "stone_l")
    c.rect(bx, by, 4, 56, "silver")
    c.rect(bx + 2, by + 6, 10, 8, "ink2")
    c.poly([(bx - 3, by), (bx + 7, by - 22), (bx + 17, by)], "navy")
    c.px(bx + 6, by + 9, "amber")
    c.px(bx + 7, by + 9, "amber")
    hills(222, 10, 0.016, "leaf_d", "leaf", 4.0)
    # champs au premier plan
    for row in range(6):
        y = 240 + row * 5
        for x in range(0, w, 6):
            c.px(x + (row * 2) % 6, y, "leaf_l" if (x // 6 + row) % 3 else "amber")
    for x in range(20, w, 90):
        c.ellipse(x, 226, 16, 13, "leaf_dd")
        c.ellipse(x - 4, 222, 9, 7, "leaf_d")
        c.rect(x - 1, 236, 3, 8, "bark")
    return c


def light_image() -> Image.Image:
    s = 64
    a = np.zeros((s, s, 4), dtype=np.uint8)
    a[:, :, :3] = 255
    for y in range(s):
        for x in range(s):
            d = math.hypot(x - 31.5, y - 31.5) / 31.5
            a[y, x, 3] = int(255 * max(0.0, 1.0 - d) ** 1.6)
    return Image.fromarray(a, "RGBA")


def generate() -> Dict[str, Canvas]:
    s: Dict[str, Canvas] = {}
    s["panel"] = panel("cream", "bark", "wood_l")
    s["panel_dark"] = panel("ink2", "ink", "stone_d")
    s["panel_inset"] = panel("sand", "bark", "soil_l", "bark")
    s["panel_blue"] = panel("frost", "navy", "sky")
    for st in ("normal", "hover", "pressed", "disabled"):
        s["button_" + st] = button(st)
    s["slot"] = slot(False)
    s["slot_selected"] = slot(True)
    s["tab_on"] = tab(True)
    s["tab_off"] = tab(False)
    s["bar_frame"] = bar_frame()
    s["bar_energy"] = solid("amber", "yellow")
    s["bar_health"] = solid("red", "rose")
    s["bar_xp"] = solid("leaf", "leaf_l")
    s["bar_blue"] = solid("sky", "ice")
    for i, n in enumerate(("spring", "summer", "autumn", "winter")):
        s["season_" + n] = season_icon(i)
    for k in ("sun", "rain", "storm", "wind", "snow"):
        s["weather_" + k] = weather_icon(k)
    for k in ("farming", "husbandry", "fishing", "mining", "combat", "foraging"):
        s["skill_" + k] = skill_icon(k)
    s["heart_full"] = heart(True)
    s["heart_empty"] = heart(False)
    s["star_silver"] = star("silver")
    s["star_gold"] = star("amber")
    s["coin"] = coin()
    s["tile_ok"] = tile_cursor("yellow")
    s["tile_bad"] = tile_cursor("red")
    s["cursor_arrow"] = cursor("arrow")
    s["cursor_hand"] = cursor("hand")
    s["joy_base"] = joystick(True)
    s["joy_knob"] = joystick(False)
    for g in ("action", "tool", "menu", "bag", "cancel"):
        s["touch_" + g] = touch_button(g)
    for g in ("arrow_right", "arrow_left", "arrow_up", "arrow_down", "check_on", "check_off", "close", "knob", "lock", "gift", "talk"):
        s["g_" + g] = small_glyph(g)
    for e in ("heart", "exclaim", "question", "zzz", "note", "happy", "sad", "fish"):
        s["emote_" + e] = emote(e)
    for p in ("rain", "snow", "leaf_a", "leaf_b", "petal", "splash", "sparkle", "dust", "smoke", "chip", "wood", "drop", "heart", "note", "frost"):
        s["p_" + p] = particle(p)
    s["bobber"] = bobber()
    s["slash"] = slash()
    s["shadow"] = shadow()
    s["logo"] = logo()
    return s


def write_standalone() -> None:
    os.makedirs(OUT, exist_ok=True)
    title_bg().to_image().save(os.path.join(OUT, "title_bg.png"))
    light_image().save(os.path.join(OUT, "light.png"))
