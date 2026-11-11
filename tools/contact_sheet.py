"""Planches de contact ×4 de tous les sprites, pour l'inspection visuelle.

Sortie : assets/contact/*.png (dossier ignoré par Godot via .gdignore).
"""
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.join(os.path.dirname(HERE), "assets")
OUT = os.path.join(ASSETS, "contact")
SCALE = 4
BG = {"default": (134, 194, 90, 255), "ui": (95, 163, 214, 255), "icons": (244, 232, 200, 255), "crops": (125, 87, 65, 255)}


def montage(paths, cols: int, pad: int = 4) -> Image.Image:
    ims = [Image.open(p).convert("RGBA") for p in paths]
    cw = max(i.width for i in ims)
    ch = max(i.height for i in ims)
    rows = (len(ims) + cols - 1) // cols
    out = Image.new("RGBA", (cols * (cw + pad) + pad, rows * (ch + pad) + pad), (0, 0, 0, 0))
    for k, im in enumerate(ims):
        out.alpha_composite(im, (pad + (k % cols) * (cw + pad), pad + (k // cols) * (ch + pad)))
    return out


def export(name: str, im: Image.Image, bg: str = "default", max_side: int = 1900) -> None:
    box = im.getbbox()
    if box:
        im = im.crop((0, 0, box[2] + 2, box[3] + 2))
    base = Image.new("RGBA", im.size, BG[bg])
    base.alpha_composite(im)
    scale = SCALE
    while scale > 1 and max(base.size) * scale > max_side * 2:
        scale -= 1
    base.resize((base.width * scale, base.height * scale), Image.NEAREST).save(os.path.join(OUT, name + ".png"))


def main() -> int:
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, ".gdignore"), "w") as f:
        f.write("")
    j = lambda *p: os.path.join(ASSETS, *p)
    ls = lambda d, pre="": sorted(os.path.join(ASSETS, d, f) for f in os.listdir(os.path.join(ASSETS, d)) if f.endswith(".png") and f.startswith(pre))
    export("tiles", montage(ls("tiles"), 8))
    export("characters", montage(ls("sprites/chars", "player") + ls("sprites/chars", "npc"), 4))
    export("portraits", montage(ls("sprites/chars", "portrait"), 3), "icons")
    export("creatures", montage(ls("sprites/creatures"), 4))
    export("crops", Image.open(j("sprites", "crops.png")).convert("RGBA"), "crops")
    export("icons", Image.open(j("sprites", "icons.png")).convert("RGBA"), "icons")
    export("objects", Image.open(j("sprites", "objects.png")).convert("RGBA"))
    export("ui", Image.open(j("ui", "ui.png")).convert("RGBA"), "ui")
    export("title_bg", Image.open(j("ui", "title_bg.png")).convert("RGBA"))
    export("app_icon", Image.open(j("icons", "icon_256.png")).convert("RGBA"))
    n = len([f for f in os.listdir(OUT) if f.endswith(".png")])
    print("planches de contact : %d → assets/contact/" % n)
    return 0


if __name__ == "__main__":
    sys.exit(main())
