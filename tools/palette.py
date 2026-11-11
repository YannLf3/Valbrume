"""Palette originale de Valbrume : 43 couleurs + transparent.

Tous les sprites du jeu n'utilisent que ces couleurs. L'index 0 est le
transparent. Les « rampes » décrivent les familles de teintes, de la plus
sombre à la plus claire ; elles servent à l'ombrage et aux contours colorés.
"""
from typing import Dict, List, Tuple

_HEX: List[Tuple[str, str]] = [
    # encres (pas de noir pur)
    ("ink", "2b2233"), ("ink2", "453a4f"),
    # bois et terre
    ("bark_d", "4a3228"), ("bark", "6e4a34"), ("wood", "96683f"), ("wood_l", "c08e55"), ("straw", "e3c07a"),
    ("soil_d", "5a3d33"), ("soil", "7d5741"), ("soil_l", "a47a57"),
    # sable et clairs
    ("sand", "e0c992"), ("cream", "f4e8c8"), ("white", "fbf7ec"),
    # verts
    ("leaf_dd", "24483f"), ("leaf_d", "2f6b47"), ("leaf", "4c9a4f"), ("leaf_l", "86c25a"), ("lime", "c3de7b"),
    # chauds
    ("rust", "a8432e"), ("orange", "dd7a34"), ("amber", "f0ae3f"), ("yellow", "f7dc6a"),
    # rouges et roses
    ("wine", "7a2840"), ("red", "c8413f"), ("rose", "e77f86"), ("blush", "f6c1b4"),
    # peaux
    ("skin_d", "8f5a44"), ("skin", "d99872"), ("skin_l", "f3c9a2"),
    # bleus
    ("navy", "263a66"), ("blue", "3d68a8"), ("sky", "5fa3d6"), ("ice", "a9d9e8"), ("frost", "dff1f2"),
    # sarcelle
    ("teal_d", "23606b"), ("teal", "36a39a"),
    # violets
    ("plum", "5b3a78"), ("violet", "8a5fb0"), ("lilac", "c2a0dc"),
    # pierres
    ("stone_d", "4d5263"), ("stone", "7c8394"), ("stone_l", "b0b6bf"), ("silver", "d8dde0"),
]

NAMES: List[str] = ["void"] + [n for n, _ in _HEX]
INDEX: Dict[str, int] = {n: i for i, n in enumerate(NAMES)}
RGBA: List[Tuple[int, int, int, int]] = [(0, 0, 0, 0)] + [
    (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255) for _, h in _HEX
]
RGB_SET = {c[:3] for c in RGBA[1:]}

RAMPS: List[List[str]] = [
    ["ink", "ink2", "stone_d", "stone", "stone_l", "silver", "white"],
    ["bark_d", "bark", "wood", "wood_l", "straw", "cream"],
    ["soil_d", "soil", "soil_l", "sand", "cream"],
    ["leaf_dd", "leaf_d", "leaf", "leaf_l", "lime"],
    ["wine", "rust", "orange", "amber", "yellow"],
    ["wine", "red", "rose", "blush"],
    ["bark_d", "skin_d", "skin", "skin_l", "cream"],
    ["navy", "blue", "sky", "ice", "frost"],
    ["leaf_dd", "teal_d", "teal", "ice"],
    ["ink", "plum", "violet", "lilac"],
]


def _ramp_of(name: str) -> List[str]:
    for r in RAMPS:
        if name in r:
            return r
    return RAMPS[0]


def darker(name: str, steps: int = 1) -> str:
    r = _ramp_of(name)
    return r[max(0, r.index(name) - steps)]


def lighter(name: str, steps: int = 1) -> str:
    r = _ramp_of(name)
    return r[min(len(r) - 1, r.index(name) + steps)]


def outline_of(name: str) -> str:
    """Couleur de contour : la plus sombre de la rampe (contour coloré)."""
    r = _ramp_of(name)
    return r[0]


def rgb(name: str) -> Tuple[int, int, int]:
    return RGBA[INDEX[name]][:3]


assert len(NAMES) - 1 <= 48, "palette trop grande"
