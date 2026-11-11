"""Contrôle de l'internationalisation.

1. i18n/strings.csv : aucune clé vide, FR et EN présents, mêmes marqueurs (%s %d {player}) dans les deux langues.
2. Toute clé citée dans le code (Loc.t / Loc.f / tr / constantes de clés) existe ; tout préfixe dynamique
   (« SKILL_ » + …) correspond à au moins une clé.
3. Aucune chaîne visible n'est écrite en dur dans les scripts ou les scènes (étiquettes, boutons, messages).
Code de sortie 1 si un problème est trouvé.
"""
import csv
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV = os.path.join(ROOT, "i18n", "strings.csv")
LETTERS = re.compile(r"[A-Za-zÀ-ÿœŒ]{3,}")
MARKERS = re.compile(r"%[-+0-9.]*[sdf]|\{player\}|\{farm\}")
WHITELIST = {"FPS", "Valbrume", "Godot", "MIT"}

# appels dont le premier argument est un texte visible
VISIBLE_CALLS = re.compile(
    r'(?:UIKit\.label|UIKit\.button|show_toast|Label\.new\(\)\.text\s*=|\.text\s*=|toast\.emit|\.tooltip_text\s*=)\s*\(?\s*"((?:[^"\\]|\\.)*)"')


def load_csv():
    rows = {}
    with open(CSV, encoding="utf-8", newline="") as f:
        for r in csv.DictReader(f):
            rows[r["keys"]] = (r["fr"], r["en"])
    return rows


def main() -> int:
    problems = []
    rows = load_csv()
    for k, (fr, en) in rows.items():
        if not fr.strip() or not en.strip():
            problems.append("clé sans traduction : %s" % k)
        elif sorted(MARKERS.findall(fr)) != sorted(MARKERS.findall(en)):
            problems.append("marqueurs différents FR/EN : %s  %s / %s" % (k, MARKERS.findall(fr), MARKERS.findall(en)))
    prefixes = {k.split("_")[0] for k in rows}
    used = set()
    dyn = set()
    hard = []
    files = glob.glob(os.path.join(ROOT, "scripts", "**", "*.gd"), recursive=True) + glob.glob(os.path.join(ROOT, "scenes", "**", "*.tscn"), recursive=True)
    for path in sorted(files):
        rel = os.path.relpath(path, ROOT)
        with open(path, encoding="utf-8") as f:
            raw = f.read()
        # commentaires (# …) et lignes marquées « i18n:ignore » (outils de débogage) exclus
        text = "\n".join("" if (l.strip().startswith("#") or "i18n:ignore" in l) else re.sub(r"\s#\s.*$", "", l) for l in raw.splitlines())
        for m in re.finditer(r'(?:Loc\.[tf]|tr)\(\s*"([A-Z][A-Z0-9_]*)"(?!\s*\+)', text):
            used.add((m.group(1), rel))
        for m in re.finditer(r'"([A-Z][A-Z0-9]*_)"\s*\+', text):
            dyn.add((m.group(1), rel))
        for m in re.finditer(r'"([A-Z][A-Z0-9]+_[A-Z0-9_]*[A-Z0-9])"', text):
            lit = m.group(1)
            if lit.split("_")[0] in prefixes and lit.split("_")[0] in ("TOAST", "SHOP", "BUILD", "MACHINE", "ANIMAL", "GIFT", "CRAFT", "UPGRADE", "QUEST", "FISH",
                                                                          "MINE", "FEST", "BELL", "COMMON", "SLOT", "MUSEUM", "COLLECT", "PET", "SILO", "SLEEP", "SUMMARY"):
                used.add((lit, rel))
        for line_no, line in enumerate(text.splitlines(), 1):
            if line.strip().startswith("#"):
                continue
            for m in VISIBLE_CALLS.finditer(line):
                lit = m.group(1)
                if LETTERS.search(re.sub(MARKERS, "", lit)) and lit not in WHITELIST and not all(w in WHITELIST for w in LETTERS.findall(lit)):
                    hard.append("%s:%d  texte en dur : %r" % (rel, line_no, lit))
    for key, rel in sorted(used):
        if key not in rows:
            problems.append("clé citée mais absente du CSV : %s (%s)" % (key, rel))
    for pre, rel in sorted(dyn):
        if not any(k.startswith(pre) for k in rows):
            problems.append("préfixe dynamique sans clé : %s (%s)" % (pre, rel))
    problems += hard
    for p in problems:
        print(p)
    print("i18n : %d clés, %d citées dans le code, %d préfixes dynamiques — %s" % (len(rows), len({k for k, _ in used}), len({p for p, _ in dyn}),
                                                                                 "OK" if not problems else "%d problème(s)" % len(problems)))
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
