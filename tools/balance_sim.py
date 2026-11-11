"""Simulation de l'économie de l'année 1 (agriculture seule, joueur raisonnablement efficace).

    python tools/balance_sim.py          # tableau de rentabilité + courbe d'argent
    python tools/balance_sim.py --check  # échoue si la courbe sort des bornes visées (utilisé par build.sh)

Modèle : énergie quotidienne bornant le nombre de parcelles arrosées à la main ; les arroseurs (acquis dès que
l'argent le permet) relèvent cette limite ; chaque jour on replante la culture la plus rentable de la saison qui
a le temps de mûrir ; les grands achats du jeu (bâtiments, outils, maison, cloches) sont dépensés quand ils sont
abordables, dans l'ordre où un joueur les viserait.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "content"))
from items import CROPS  # noqa: E402

SEASON_DAYS = 28
YEAR_DAYS = 112
QUALITY = 1.12            # multiplicateur moyen de prix grâce à la qualité
START_MONEY = 500
ENERGY = 100.0            # énergie quotidienne ; 55 % consacrés aux cultures (le reste : mine, pêche, relations)
CROP_SHARE = 0.55
ENERGY_PER_PLOT_HAND = 1.8   # arrosage + récolte + semis, par parcelle et par jour moyen
ENERGY_PER_PLOT_SPRINKLER = 0.5
LAND_PLOTS = 320
START_PLOTS = 18
# grands achats (coût d'argent), dans l'ordre visé ; le gain de capacité vient avec « sprinklers »
GOALS = [
    ("arroseurs", 1500, "sprinklers"), ("poulailler", 4000, ""), ("cloche Sillons", 2000, ""), ("houe+arrosoir 2", 4000, ""),
    ("étable", 6000, ""), ("cloche Ondes", 4000, ""), ("maison 2", 10000, ""), ("cloche Foyer", 6000, ""), ("cloche Roche", 8000, ""),
    ("pioche+hache 3", 10000, ""), ("cloche Troupeaux", 12000, ""), ("cloche Bourdon", 30000, ""),
]
SEASONS = ["spring", "summer", "autumn", "winter"]


def profit_per_plot(crop, remaining):
    cid, fr, en, season, seed, sell, days, regrow = crop[:8]
    if days > remaining:
        return 0.0, 0
    if regrow:
        n = 1 + (remaining - days) // regrow
        cost = seed
    else:
        n = remaining // days
        cost = seed * n
    return (n * sell * QUALITY - cost) / remaining, n


def best_crop(season_idx, remaining):
    best, bp = None, 0.0
    for c in CROPS:
        if c[3] != SEASONS[season_idx]:
            continue
        p, _ = profit_per_plot(c, remaining)
        if p > bp:
            best, bp = c, p
    return best, bp


def table():
    print("%-16s %-7s %6s %6s %5s %7s %9s" % ("culture", "saison", "graine", "vente", "jours", "repousse", "or/parcelle/jour"))
    for c in sorted(CROPS, key=lambda x: (SEASONS.index(x[3]), -profit_per_plot(x, SEASON_DAYS)[0])):
        p, n = profit_per_plot(c, SEASON_DAYS)
        print("%-16s %-7s %6d %6d %5d %7s %9.1f" % (c[1], c[3], c[4], c[5], c[6], c[7] or "-", p))


def simulate():
    money = float(START_MONEY)
    plots = START_PLOTS
    sprinklers = False
    goals = list(GOALS)
    log = []
    spent_total = 0.0
    earned_total = 0.0
    pending = []        # (jour de récolte, gain)
    ready_day = {}
    for day in range(YEAR_DAYS):
        season = day // SEASON_DAYS
        remaining = SEASON_DAYS - day % SEASON_DAYS
        per_plot = ENERGY_PER_PLOT_SPRINKLER if sprinklers else ENERGY_PER_PLOT_HAND
        max_plots = int(ENERGY * CROP_SHARE / per_plot)
        cap = min(max_plots, LAND_PLOTS)
        crop, daily = best_crop(season, remaining)
        # revenu du jour : étalé sur la saison (profit moyen des parcelles en culture)
        active = min(plots, cap)
        income = active * daily * 0.75 if crop else 0.0     # 0,75 : pertes (nuisibles, pluie ratée, déplacements, attente)
        # croissance des parcelles : on réinvestit dans de nouvelles graines tant qu'il y a de la place
        if crop and plots < cap:
            grow = min(cap - plots, int(max(0.0, money) // (crop[4] * 1.3 + 1)) // 6, 6)
            plots += max(0, grow)
        money += income
        earned_total += income
        # grands achats
        while goals and money >= goals[0][1] * 1.15:
            name, cost, effect = goals.pop(0)
            money -= cost
            spent_total += cost
            if effect == "sprinklers":
                sprinklers = True
            log.append((day + 1, name))
        if day % 28 == 27:
            print("fin de %-7s (jour %3d) : argent %8.0f · parcelles %3d · arroseurs %-3s · gains cumulés %8.0f · dépensé %8.0f" % (
                SEASONS[season], day + 1, money, plots, "oui" if sprinklers else "non", earned_total, spent_total))
    print("\nAchats réalisés (jour) :")
    for d, n in log:
        print("  j%3d  %s" % (d, n))
    return money, spent_total, earned_total, log, goals


def main():
    table()
    print()
    money, spent, earned, log, left = simulate()
    ok = True
    if left:
        print("ATTENTION : objectifs non atteints en un an : %s" % ", ".join(g[0] for g in left))
    # bornes visées : l'année est gratifiante (au moins 70 % des grands achats) sans être triviale (pas tout avant l'été de l'an 1)
    done = len(log)
    if done < 7 or (log and log[-1][0] < 56):
        ok = False
        print("HORS BORNES : %d achats sur %d, dernier au jour %d" % (done, len(GOALS), log[-1][0] if log else 0))
    print("\nbilan : %.0f é gagnés, %.0f é investis, %d/%d grands achats dans l'année." % (earned, spent, done, len(GOALS)))
    if "--check" in sys.argv:
        return 0 if ok else 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
