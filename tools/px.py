"""Petite bibliothèque de dessin pixel art sur palette indexée."""
import random
import zlib
from typing import Dict, Iterable, List, Optional, Sequence, Tuple

import numpy as np
from PIL import Image

from palette import INDEX, NAMES, RGBA, darker, lighter, outline_of

SEED = 20261111


def rng_for(name: str) -> random.Random:
    """Générateur déterministe propre à un sprite (indépendant de l'ordre d'appel)."""
    return random.Random(SEED ^ zlib.crc32(name.encode("utf-8")))


class Canvas:
    def __init__(self, w: int, h: int, fill: Optional[str] = None):
        self.w, self.h = w, h
        self.a = np.zeros((h, w), dtype=np.uint8)
        if fill:
            self.a[:, :] = INDEX[fill]

    # -- primitives -------------------------------------------------------
    def px(self, x: float, y: float, c: Optional[str]) -> None:
        x, y = int(x), int(y)
        if c is not None and 0 <= x < self.w and 0 <= y < self.h:
            self.a[y, x] = INDEX[c]

    def get(self, x: float, y: float) -> str:
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            return NAMES[self.a[y, x]]
        return "void"

    def rect(self, x: float, y: float, w: float, h: float, c: str) -> None:
        x, y, w, h = int(x), int(y), int(w), int(h)
        x0, y0 = max(0, x), max(0, y)
        x1, y1 = min(self.w, x + w), min(self.h, y + h)
        if x1 > x0 and y1 > y0:
            self.a[y0:y1, x0:x1] = INDEX[c]

    def frame(self, x: int, y: int, w: int, h: int, c: str) -> None:
        self.rect(x, y, w, 1, c)
        self.rect(x, y + h - 1, w, 1, c)
        self.rect(x, y, 1, h, c)
        self.rect(x + w - 1, y, 1, h, c)

    def hline(self, x: int, y: int, n: int, c: str) -> None:
        self.rect(x, y, n, 1, c)

    def vline(self, x: int, y: int, n: int, c: str) -> None:
        self.rect(x, y, 1, n, c)

    def line(self, x0: float, y0: float, x1: float, y1: float, c: str) -> None:
        x0, y0, x1, y1 = int(round(x0)), int(round(y0)), int(round(x1)), int(round(y1))
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx + dy
        while True:
            self.px(x0, y0, c)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def ellipse(self, cx: float, cy: float, rx: float, ry: float, c: str) -> None:
        for y in range(int(cy - ry - 1), int(cy + ry + 2)):
            for x in range(int(cx - rx - 1), int(cx + rx + 2)):
                if ((x - cx) / max(rx, 0.01)) ** 2 + ((y - cy) / max(ry, 0.01)) ** 2 <= 1.0:
                    self.px(x, y, c)

    def poly(self, pts: Sequence[Tuple[float, float]], c: str) -> None:
        pts = [(int(round(p[0])), int(round(p[1]))) for p in pts]
        ys = [p[1] for p in pts]
        n = len(pts)
        for y in range(min(ys), max(ys) + 1):
            xs: List[float] = []
            for i in range(n):
                (x0, y0), (x1, y1) = pts[i], pts[(i + 1) % n]
                if y0 == y1:
                    if y == y0:
                        xs += [x0, x1]
                    continue
                if min(y0, y1) <= y <= max(y0, y1):
                    xs.append(x0 + (y - y0) * (x1 - x0) / (y1 - y0))
            xs.sort()
            for i in range(0, len(xs) - 1, 2):
                self.hline(int(round(xs[i])), y, int(round(xs[i + 1])) - int(round(xs[i])) + 1, c)
        for i in range(n):
            self.line(pts[i][0], pts[i][1], pts[(i + 1) % n][0], pts[(i + 1) % n][1], c)

    def art(self, rows: Sequence[str], x: int, y: int, cmap: Dict[str, Optional[str]], flip: bool = False) -> None:
        """Dessine depuis de l'art ASCII ; '.' et ' ' sont transparents."""
        for j, row in enumerate(rows):
            r = row[::-1] if flip else row
            for i, ch in enumerate(r):
                if ch in ". ":
                    continue
                self.px(x + i, y + j, cmap.get(ch))

    def blit(self, other: "Canvas", x: int, y: int, flip: bool = False) -> None:
        src = other.a[:, ::-1] if flip else other.a
        for j in range(other.h):
            for i in range(other.w):
                v = src[j, i]
                if v and 0 <= x + i < self.w and 0 <= y + j < self.h:
                    self.a[y + j, x + i] = v

    # -- traitements ------------------------------------------------------
    def outline(self, c: Optional[str] = None, diagonal: bool = False) -> None:
        """Contour sombre coloré autour des pixels opaques (là où il reste de la place)."""
        src = self.a.copy()
        nb = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        if diagonal:
            nb += [(1, 1), (-1, 1), (1, -1), (-1, -1)]
        for y in range(self.h):
            for x in range(self.w):
                if src[y, x]:
                    continue
                for dx, dy in nb:
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < self.w and 0 <= yy < self.h and src[yy, xx]:
                        self.a[y, x] = INDEX[c or outline_of(NAMES[src[yy, xx]])]
                        break

    def shade(self, base: str, light: bool = True, dark: bool = True) -> None:
        """Ombrage automatique d'une couleur : lumière en haut à gauche."""
        b = INDEX[base]
        src = self.a.copy()
        hi, lo = INDEX[lighter(base)], INDEX[darker(base)]
        for y in range(self.h):
            for x in range(self.w):
                if src[y, x] != b:
                    continue
                up = src[y - 1, x] if y > 0 else 0
                left = src[y, x - 1] if x > 0 else 0
                down = src[y + 1, x] if y < self.h - 1 else 0
                right = src[y, x + 1] if x < self.w - 1 else 0
                if light and (up != b and left != b):
                    self.a[y, x] = hi
                elif light and up != b and (x + y) % 2 == 0:
                    self.a[y, x] = hi
                elif dark and (down != b or right != b):
                    self.a[y, x] = lo

    def replace(self, a: str, b: str) -> None:
        self.a[self.a == INDEX[a]] = INDEX[b]

    def speckle(self, on: str, c: str, density: float, rng: random.Random) -> None:
        o = INDEX[on]
        for y in range(self.h):
            for x in range(self.w):
                if self.a[y, x] == o and rng.random() < density:
                    self.a[y, x] = INDEX[c]

    def dither(self, x: int, y: int, w: int, h: int, c: str, phase: int = 0) -> None:
        for j in range(y, y + h):
            for i in range(x, x + w):
                if (i + j + phase) % 2 == 0:
                    self.px(i, j, c)

    def copy(self) -> "Canvas":
        k = Canvas(self.w, self.h)
        k.a = self.a.copy()
        return k

    def flipped(self) -> "Canvas":
        k = Canvas(self.w, self.h)
        k.a = self.a[:, ::-1].copy()
        return k

    def rot90(self, times: int = 1) -> "Canvas":
        a = np.rot90(self.a, -times).copy()
        k = Canvas(a.shape[1], a.shape[0])
        k.a = a
        return k

    def sub(self, x: int, y: int, w: int, h: int) -> "Canvas":
        k = Canvas(w, h)
        k.a = self.a[y:y + h, x:x + w].copy()
        return k

    def bbox(self) -> Tuple[int, int, int, int]:
        ys, xs = np.nonzero(self.a)
        if len(xs) == 0:
            return (0, 0, 0, 0)
        return (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)

    def to_image(self) -> Image.Image:
        lut = np.array(RGBA, dtype=np.uint8)
        return Image.fromarray(lut[self.a], "RGBA")


def sheet(cells: Sequence[Canvas], cols: int, cw: int, ch: int) -> Canvas:
    rows = (len(cells) + cols - 1) // cols
    out = Canvas(cols * cw, max(1, rows) * ch)
    for i, c in enumerate(cells):
        out.blit(c, (i % cols) * cw, (i // cols) * ch)
    return out


def save(canvas: Canvas, path: str) -> None:
    import os
    os.makedirs(os.path.dirname(path), exist_ok=True)
    canvas.to_image().save(path, optimize=False)
