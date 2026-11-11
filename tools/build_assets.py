"""Point d'entrée unique de la génération d'assets. Déterministe (graine fixe).

    python tools/build_assets.py            # régénère tout
    python tools/build_assets.py --no-audio # sans l'audio (plus rapide)
    python tools/build_assets.py --verify   # régénère et compare aux empreintes du manifeste
"""
import hashlib
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "content"))

import atlas  # noqa: E402
import gen_app_icons  # noqa: E402
import gen_audio  # noqa: E402
import gen_chars  # noqa: E402
import gen_creatures  # noqa: E402
import gen_crops  # noqa: E402
import gen_font  # noqa: E402
import gen_icons  # noqa: E402
import gen_objects  # noqa: E402
import gen_tiles  # noqa: E402
import gen_ui  # noqa: E402
from palette import RGB_SET  # noqa: E402
from px import save  # noqa: E402

ROOT = os.path.dirname(HERE)
ASSETS = os.path.join(ROOT, "assets")
MANIFEST = os.path.join(ASSETS, "manifest.json")
PALETTE_EXEMPT = ("fonts/", "ui/light.png", "contact/")


def hashes() -> dict:
    out = {}
    for base, _dirs, files in os.walk(ASSETS):
        for f in sorted(files):
            if f.endswith((".png", ".wav", ".fnt", ".ico", ".icns")):
                p = os.path.join(base, f)
                rel = os.path.relpath(p, ASSETS).replace(os.sep, "/")
                if rel.startswith("contact/"):
                    continue
                with open(p, "rb") as fh:
                    out[rel] = hashlib.sha256(fh.read()).hexdigest()
    return dict(sorted(out.items()))


def check_palette() -> list:
    from PIL import Image
    bad = []
    for base, _dirs, files in os.walk(ASSETS):
        for f in files:
            if not f.endswith(".png"):
                continue
            rel = os.path.relpath(os.path.join(base, f), ASSETS).replace(os.sep, "/")
            if rel.startswith(PALETTE_EXEMPT):
                continue
            im = Image.open(os.path.join(base, f)).convert("RGBA")
            cols = {c[:3] for _n, c in (im.getcolors(1 << 20) or []) if c[3] > 0}
            extra = cols - RGB_SET
            if extra:
                bad.append((rel, sorted(extra)[:3]))
    return bad


def build(audio: bool = True) -> dict:
    counts = {}
    counts["font_glyphs"] = gen_font.main()
    counts["tiles"] = gen_tiles.main()
    counts["character_frames"] = gen_chars.main()
    counts["creature_frames"] = gen_creatures.main()
    crops_sheet, trees = gen_crops.generate()
    save(crops_sheet, os.path.join(ASSETS, "sprites", "crops.png"))
    counts["crop_frames"] = (crops_sheet.w // gen_crops.CW) * (crops_sheet.h // gen_crops.CH)
    save(gen_icons.generate(), os.path.join(ASSETS, "sprites", "icons.png"))
    counts["icons"] = len(gen_icons.all_items())
    objects = gen_objects.generate()
    objects.update(trees)
    obj_sheet, rects = atlas.pack(objects, "sprites/objects", 1024)
    save(obj_sheet, os.path.join(ASSETS, "sprites", "objects.png"))
    counts["object_sprites"] = len(objects)
    ui = gen_ui.generate()
    ui_sheet, ui_rects = atlas.pack(ui, "ui/ui", 256)
    save(ui_sheet, os.path.join(ASSETS, "ui", "ui.png"))
    gen_ui.write_standalone()
    counts["ui_sprites"] = len(ui) + 2
    rects.update(ui_rects)
    with open(os.path.join(ROOT, "data", "atlas.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(dict(sorted(rects.items())), f, indent=0, sort_keys=True)
    gen_app_icons.main()
    counts["app_icons"] = 9
    if audio:
        counts["sfx"], counts["music"] = gen_audio.main()
    counts["sprites_total"] = sum(v for k, v in counts.items() if k not in ("sfx", "music", "font_glyphs"))
    return counts


def main() -> int:
    verify = "--verify" in sys.argv
    audio = "--no-audio" not in sys.argv
    before = {}
    if verify and os.path.exists(MANIFEST):
        with open(MANIFEST, encoding="utf-8") as f:
            before = json.load(f).get("sha256", {})
    counts = build(audio)
    bad = check_palette()
    for rel, cols in bad:
        print("HORS PALETTE : %s %s" % (rel, cols))
    now = hashes()
    if verify:
        diff = [k for k in now if (audio or not k.startswith("audio/")) and before.get(k) != now[k]]
        if diff:
            print("NON DÉTERMINISTE : %d fichier(s) diffèrent, ex. %s" % (len(diff), diff[:5]))
            return 1
        print("déterminisme : OK (%d fichiers identiques)" % len(now))
    if not audio and os.path.exists(MANIFEST):
        with open(MANIFEST, encoding="utf-8") as f:
            old = json.load(f)
        for k in ("sfx", "music"):
            if k in old.get("counts", {}):
                counts[k] = old["counts"][k]
    with open(MANIFEST, "w", encoding="utf-8", newline="\n") as f:
        json.dump({"counts": counts, "sha256": now}, f, indent=1, sort_keys=True)
    for k, v in counts.items():
        print("  %-18s %d" % (k, v))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
