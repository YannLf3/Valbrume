"""Outils de construction de cartes : classe M (grille, décors, passages, zones) et placement d'objets."""
import json
import math
import os
import sys
from typing import Dict, List, Optional, Tuple

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

T = 16


class M:
    def __init__(self, id_: str, w: int, h: int, fill: str, **meta):
        self.id, self.w, self.h = id_, w, h
        self.g = [[fill] * w for _ in range(h)]
        self.meta = meta
        self.statics: List[Dict] = []
        self.objects: List[Dict] = []
        self.warps: List[Dict] = []
        self.spots: Dict[str, List[int]] = {}
        self.interact: List[Dict] = []
        self.taken = set()

    def inb(self, x: int, y: int) -> bool:
        return 0 <= x < self.w and 0 <= y < self.h

    def set(self, x: int, y: int, c: str) -> None:
        if self.inb(x, y):
            self.g[y][x] = c

    def get(self, x: int, y: int) -> str:
        return self.g[y][x] if self.inb(x, y) else " "

    def rect(self, x: int, y: int, w: int, h: int, c: str) -> None:
        for j in range(y, y + h):
            for i in range(x, x + w):
                self.set(i, j, c)

    def ellipse(self, cx: float, cy: float, rx: float, ry: float, c: str) -> None:
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                    self.set(x, y, c)

    def block(self, x: int, y: int, w: int, h: int) -> None:
        for j in range(y, y + h):
            for i in range(x, x + w):
                self.taken.add((i, j))

    def static(self, s: str, x: int, y: int, w: int, h: int, solid: bool = True, door: Optional[Tuple[int, int]] = None, **kw) -> None:
        d = {"s": s, "x": x, "y": y, "w": w, "h": h, "solid": solid}
        if door:
            d["door"] = list(door)
        d.update(kw)
        self.statics.append(d)
        self.block(x, y, w, h)

    def warp(self, x: int, y: int, w: int, h: int, to: str, spot: str, face: int) -> None:
        self.warps.append({"x": x, "y": y, "w": w, "h": h, "to": to, "spot": spot, "face": face})

    def zone(self, x: int, y: int, w: int, h: int, kind: str, **kw) -> None:
        d = {"x": x, "y": y, "w": w, "h": h, "kind": kind}
        d.update(kw)
        self.interact.append(d)

    def free_grass(self, x: int, y: int) -> bool:
        return self.get(x, y) == "." and (x, y) not in self.taken

    def to_json(self) -> Dict:
        d = {"id": self.id, "w": self.w, "h": self.h, "rows": ["".join(r) for r in self.g],
             "statics": self.statics, "objects": self.objects, "warps": self.warps,
             "spots": self.spots, "interact": self.interact}
        d.update(self.meta)
        return d

    def warp_ex(self, x: int, y: int, w: int, h: int, to: str, spot: str, face: int, **kw) -> None:
        """Passage avec conditions : need_flag + msg (verrouillé), shop (ouvert aux horaires du commerce)."""
        d = {"x": x, "y": y, "w": w, "h": h, "to": to, "spot": spot, "face": face}
        d.update(kw)
        self.warps.append(d)
