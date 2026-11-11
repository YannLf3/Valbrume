"""Textes d'interface complémentaires (touches, tactile)."""
from typing import Dict, Tuple


def tables() -> Dict:
    return {}


def strings() -> Dict[str, Tuple[str, str]]:
    return {
        "REMAP_TITLE": ("Touches du clavier", "Keyboard keys"), "REMAP_PRESS": ("Appuie sur une touche… (Échap : annuler)", "Press a key... (Esc: cancel)"),
        "REMAP_RESET": ("Par défaut", "Defaults"), "OPT_KEYS_REMAP": ("Remappage", "Remapping"),
        "ACT_MOVE_UP": ("Haut", "Up"), "ACT_MOVE_DOWN": ("Bas", "Down"), "ACT_MOVE_LEFT": ("Gauche", "Left"), "ACT_MOVE_RIGHT": ("Droite", "Right"),
        "ACT_ACTION": ("Action", "Action"), "ACT_TOOL": ("Outil (maintenir : charge)", "Tool (hold: charge)"), "ACT_INVENTORY": ("Sac", "Bag"),
        "ACT_JOURNAL": ("Journal", "Journal"), "ACT_MAP": ("Carte", "Map"), "ACT_MENU": ("Menu", "Menu"),
        "ACT_HOTBAR_PREV": ("Barre : précédent", "Hotbar: previous"), "ACT_HOTBAR_NEXT": ("Barre : suivant", "Hotbar: next"),
    }
