"""Textes d'interface : clé → (français, anglais). Tout texte visible passe par tr(clé)."""
from typing import Dict, Tuple

UI: Dict[str, Tuple[str, str]] = {
    "GAME_TITLE": ("Valbrume", "Valbrume"),
    "SEASON_SPRING": ("Printemps", "Spring"), "SEASON_SUMMER": ("Été", "Summer"),
    "SEASON_AUTUMN": ("Automne", "Autumn"), "SEASON_WINTER": ("Hiver", "Winter"),
    "WEEKDAY_0": ("Lun", "Mon"), "WEEKDAY_1": ("Mar", "Tue"), "WEEKDAY_2": ("Mer", "Wed"), "WEEKDAY_3": ("Jeu", "Thu"),
    "WEEKDAY_4": ("Ven", "Fri"), "WEEKDAY_5": ("Sam", "Sat"), "WEEKDAY_6": ("Dim", "Sun"),
    "WEATHER_SUN": ("Soleil", "Sunny"), "WEATHER_RAIN": ("Pluie", "Rain"), "WEATHER_STORM": ("Orage", "Storm"),
    "WEATHER_WIND": ("Vent", "Windy"), "WEATHER_SNOW": ("Neige", "Snow"),
    "CAT_TOOL": ("Outil", "Tool"), "CAT_SEED": ("Graine", "Seed"), "CAT_CROP": ("Récolte", "Crop"), "CAT_FRUIT": ("Fruit", "Fruit"),
    "CAT_FORAGE": ("Cueillette", "Forage"), "CAT_FISH": ("Poisson", "Fish"), "CAT_MINERAL": ("Minéral", "Mineral"),
    "CAT_INGOT": ("Lingot", "Ingot"), "CAT_RESOURCE": ("Ressource", "Resource"), "CAT_ANIMAL": ("Produit animal", "Animal Product"),
    "CAT_ARTISAN": ("Produit fermier", "Artisan Good"), "CAT_DISH": ("Plat", "Dish"), "CAT_CRAFTABLE": ("Objet à poser", "Placeable"),
    "CAT_FURNITURE": ("Meuble", "Furniture"), "CAT_DECOR": ("Décoration", "Decoration"), "CAT_ARTIFACT": ("Artefact", "Artifact"),
    "CAT_FERTILIZER": ("Engrais", "Fertilizer"), "CAT_SAPLING": ("Jeune arbre", "Sapling"), "CAT_MISC": ("Divers", "Misc"),
    "SKILL_FARMING": ("Agriculture", "Farming"), "SKILL_HUSBANDRY": ("Élevage", "Husbandry"), "SKILL_FISHING": ("Pêche", "Fishing"),
    "SKILL_MINING": ("Minage", "Mining"), "SKILL_COMBAT": ("Combat", "Combat"), "SKILL_FORAGING": ("Cueillette", "Foraging"),
}
