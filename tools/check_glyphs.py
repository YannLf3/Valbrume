"""Vérifie que tous les textes (CSV de traduction) n'utilisent que des glyphes présents dans la police."""
import csv
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gen_font  # noqa: E402

ROOT = os.path.dirname(HERE)


def main() -> int:
    glyphs = set(gen_font.all_glyphs().keys()) | {"\n", "\t"}
    missing = {}
    with open(os.path.join(ROOT, "i18n", "strings.csv"), encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            for col in ("fr", "en"):
                for ch in row[col]:
                    if ch not in glyphs:
                        missing.setdefault(ch, []).append(row["keys"])
    for ch, keys in sorted(missing.items()):
        print("glyphe absent %r (U+%04X) : %s" % (ch, ord(ch), ", ".join(keys[:4])))
    print("glyphes : %s" % ("OK" if not missing else "%d manquant(s)" % len(missing)))
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
