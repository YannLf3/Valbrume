"""Assemble des sprites nommés en feuilles (rangement par étagères) + table des rectangles."""
from typing import Dict, Tuple

from px import Canvas


def pack(sprites: Dict[str, Canvas], sheet_name: str, width: int = 512, pad: int = 1) -> Tuple[Canvas, Dict[str, Dict]]:
    order = sorted(sprites.items(), key=lambda kv: (-kv[1].h, -kv[1].w, kv[0]))
    x = y = pad
    shelf_h = 0
    places = []
    for name, c in order:
        if x + c.w + pad > width:
            x = pad
            y += shelf_h + pad
            shelf_h = 0
        places.append((name, c, x, y))
        x += c.w + pad
        shelf_h = max(shelf_h, c.h)
    height = 1
    while height < y + shelf_h + pad:
        height *= 2
    out = Canvas(width, height)
    rects: Dict[str, Dict] = {}
    for name, c, px_, py_ in places:
        out.blit(c, px_, py_)
        rects[name] = {"sheet": sheet_name, "x": px_, "y": py_, "w": c.w, "h": c.h}
    return out, rects
