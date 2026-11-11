"""Icônes d'application : master 1024, .ico Windows, .icns macOS, icônes adaptatives Android."""
import os

from PIL import Image

from px import Canvas

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "icons")


def emblem(c: Canvas, ox: int, oy: int) -> None:
    """Cloche d'ambre d'où pousse une jeune feuille (32×36 env.)."""
    c.poly([(ox + 16, oy + 8), (ox + 24, oy + 13), (ox + 27, oy + 28), (ox + 31, oy + 32), (ox + 1, oy + 32), (ox + 5, oy + 28), (ox + 8, oy + 13)], "amber")
    c.poly([(ox + 11, oy + 13), (ox + 14, oy + 11), (ox + 13, oy + 28), (ox + 9, oy + 28)], "yellow")
    c.poly([(ox + 22, oy + 14), (ox + 24, oy + 15), (ox + 26, oy + 28), (ox + 23, oy + 28)], "orange")
    c.rect(ox + 1, oy + 31, 31, 2, "orange")
    c.rect(ox + 13, oy + 4, 6, 5, "orange")
    c.rect(ox + 14, oy + 5, 2, 3, "amber")
    c.ellipse(ox + 16, oy + 35, 3, 2.5, "orange")
    c.line(ox + 16, oy + 4, ox + 18, oy - 3, "leaf_d")
    c.ellipse(ox + 22, oy - 3, 4.5, 2.6, "leaf_l")
    c.ellipse(ox + 12, oy - 1, 3.5, 2.2, "leaf")
    c.px(ox + 21, oy - 4, "lime")


def background(size: int) -> Canvas:
    c = Canvas(size, size, "sky")
    c.rect(0, 0, size, size // 4, "blue")
    c.dither(0, size // 4 - 3, size, 6, "sky")
    c.rect(0, size // 2, size, size // 4, "ice")
    c.dither(0, size // 2 - 3, size, 6, "ice")
    c.ellipse(size * 0.3, size * 1.02, size * 0.6, size * 0.34, "leaf")
    c.ellipse(size * 0.85, size * 1.05, size * 0.5, size * 0.3, "leaf_d")
    c.ellipse(size * 0.25, size * 0.95, size * 0.4, size * 0.2, "leaf_l")
    for i in range(6):
        c.px(size * 0.15 + i * size * 0.09, size * 0.9 + (i % 2) * 2, "yellow")
    return c


def master() -> Canvas:
    s = 64
    bg = background(s)
    art = Canvas(s, s)
    emblem(art, 16, 14)
    art.outline("bark_d", diagonal=True)
    bg.blit(art, 0, 0)
    # coins arrondis
    for x in range(s):
        for y in range(s):
            dx = max(0, 8 - x, x - (s - 9))
            dy = max(0, 8 - y, y - (s - 9))
            if dx * dx + dy * dy > 64:
                bg.a[y, x] = 0
    return bg


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    m = master().to_image()
    big = m.resize((1024, 1024), Image.NEAREST)
    big.save(os.path.join(OUT, "icon_1024.png"))
    for s in (512, 256, 192, 128):
        big.resize((s, s), Image.NEAREST).save(os.path.join(OUT, "icon_%d.png" % s))
    big.save(os.path.join(OUT, "icon.ico"), sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    big.save(os.path.join(OUT, "icon.icns"))
    # Android adaptatif : 108 dp → 432 px ; le motif reste dans la zone sûre centrale (66 dp).
    fg = Canvas(108, 108)
    emblem(fg, 38, 38)
    fg.outline("bark_d", diagonal=True)
    fg.to_image().resize((432, 432), Image.NEAREST).save(os.path.join(OUT, "android_foreground.png"))
    background(108).to_image().resize((432, 432), Image.NEAREST).save(os.path.join(OUT, "android_background.png"))
    mono = Canvas(108, 108)
    emblem(mono, 38, 38)
    mono.a[mono.a > 0] = 13
    mono.to_image().resize((432, 432), Image.NEAREST).save(os.path.join(OUT, "android_monochrome.png"))


if __name__ == "__main__":
    main()
    print("icônes d'application : ok")
