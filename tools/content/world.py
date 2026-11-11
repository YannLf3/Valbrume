"""Tables de monde : équilibrage, outils, objets, machines, animaux, bâtiments, compétences, boutiques, météo, mine."""
from typing import Any, Dict, List

# ---------------------------------------------------------------------------
# Toutes les constantes de gameplay vivent ici (aucune valeur magique dans le code).
BALANCE: Dict[str, Any] = {
    "start_money": 500, "start_energy": 100, "start_health": 100,
    "stack_size": 999, "inventory_base_size": 36, "inventory_big_size": 48, "shipping_size": 36, "backpack_price": 5000,
    "quality_price_mult": [1.0, 1.25, 1.5],
    "player_speed": 62.0, "player_speed_buff": 8.0,
    # énergie par action
    "energy_hoe": 2.0, "energy_can": 1.5, "energy_axe": 3.0, "energy_pick": 3.0, "energy_scythe": 1.0,
    "energy_rod": 4.0, "energy_sword": 0.5, "energy_skill_discount": 0.03, "energy_charge_factor": 0.6,
    "low_energy_threshold": 12.0, "exhausted_speed_mult": 0.6,
    "faint_energy_ratio": 0.5, "faint_money_pct": 10, "faint_money_max": 1000,
    "death_money_pct": 12, "death_money_max": 2500, "death_item_losses": 3,
    "charge_time": 0.45, "tool_cooldown": 0.32,
    "can_capacity": [20, 35, 55, 80],
    # agriculture
    "quality_silver_base": 0.02, "quality_gold_base": 0.0, "quality_per_level": 0.012, "quality_gold_ratio": 0.4,
    "fertilizer_quality": {"compost": 0.12, "rich_fertilizer": 0.30},
    "quick_soil_speed": 0.25, "pest_chance": 0.015, "pest_start_day": 10, "scarecrow_radius": 6, "weed_spread_chance": 0.02,
    "soil_decay_chance": 0.12, "sprinkler_patterns": {
        "sprinkler_1": [[0, -1], [1, 0], [0, 1], [-1, 0]],
        "sprinkler_2": [[-1, -1], [0, -1], [1, -1], [-1, 0], [1, 0], [-1, 1], [0, 1], [1, 1]],
        "sprinkler_3": "5x5"},
    "fruit_tree_days": 28, "fruit_tree_max": 3, "tree_grow_days": [5, 9],
    "forage_per_map": 5, "dig_spots_per_map": 2,
    # expérience
    "xp_levels": [0, 150, 450, 950, 1700, 2750, 4150, 5950, 8200, 11000],
    "xp_harvest_base": 5, "xp_harvest_div": 20, "xp_fish_base": 10, "xp_fish_per_diff": 8, "xp_rock": 3, "xp_ore": 9,
    "xp_forage": 8, "xp_tree": 12, "xp_pet": 5, "xp_product": 7, "xp_pot": 6,
    # amitié
    "heart_points": 100, "max_hearts": 10, "dating_cap_hearts": 8, "talk_points": 12,
    "gift_points": {"love": 45, "like": 22, "neutral": 9, "dislike": -12, "hate": -25},
    "birthday_mult": 4, "gifts_per_week": 2, "friend_decay": 1, "quest_friend_points": 35, "festival_points": 15,
    "marriage_hearts": 10,
    # animaux
    "affection_max": 1000, "affection_pet": 15, "affection_fed": 8, "affection_graze": 4,
    "affection_unfed": -20, "affection_unpet": -5, "affection_silver": 400, "affection_gold": 750,
    "hay_per_grass": 1, "silo_capacity": 240,
    # combat
    "sword_damage": [8, 14, 22, 32], "sword_reach": 22.0, "sword_arc": 110.0, "knockback": 90.0,
    "invincible_time": 0.9, "combat_damage_per_level": 1.0, "health_per_combat_level": 5,
    # mine
    "mine_floors": 60, "mine_biome_size": 20, "mine_elevator_step": 5, "mine_w": 34, "mine_h": 24,
    "ladder_reveal_chance": 0.04, "ladder_kill_chance": 0.15,
    # pêche (mini-jeu « ondes »)
    "fish_wait_min": 1.2, "fish_wait_max": 5.0, "fish_bait_wait_mult": 0.55,
    "fish_window_base": 0.21, "fish_window_per_rod": 0.02, "fish_window_per_diff": 0.022, "fish_perfect_ratio": 0.38,
    "fish_beats_base": 4, "fish_misses_allowed": 3, "fish_treasure_chance": 0.08,
    # météo et temps
    "rain_waters_crops": True, "storm_debris_chance": 0.01,
    # économie
    "shop_sell_ratio": 0.75, "daily_quest_base_reward": 120, "tool_upgrade_days": 2,
}

# Outils : énergie, compétence, motifs de zone par niveau (cases relatives à la case visée,
# axe « avant » = +y), coûts d'amélioration (niveau visé → prix + lingots).
TOOL_KINDS: Dict[str, Any] = {
    "hoe": {"energy": "energy_hoe", "skill": "farming", "areas": [1, 3, 5, 9]},
    "can": {"energy": "energy_can", "skill": "farming", "areas": [1, 3, 5, 9]},
    "axe": {"energy": "energy_axe", "skill": "foraging", "power": [1, 2, 3, 4]},
    "pick": {"energy": "energy_pick", "skill": "mining", "power": [1, 2, 3, 4]},
    "scythe": {"energy": "energy_scythe", "skill": "farming", "areas": [3, 3, 9, 15]},
    "rod": {"energy": "energy_rod", "skill": "fishing"},
    "sword": {"energy": "energy_sword", "skill": "combat"},
}
# 1 = la case ; 3 = ligne de 3 ; 5 = ligne de 5 ; 9 = bloc 3×3 ; 15 = bloc 5×3
AREAS: Dict[str, List[List[int]]] = {
    "1": [[0, 0]],
    "3": [[0, 0], [0, 1], [0, 2]],
    "5": [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]],
    "9": [[-1, 0], [0, 0], [1, 0], [-1, 1], [0, 1], [1, 1], [-1, 2], [0, 2], [1, 2]],
    "15": [[x, y] for y in range(3) for x in range(-2, 3)],
}
TOOL_UPGRADES: Dict[str, Any] = {
    "2": {"price": 2000, "items": {"ingot_copper": 5}},
    "3": {"price": 5000, "items": {"ingot_iron": 5}},
    "4": {"price": 10000, "items": {"ingot_silver": 5}},
}

# ---------------------------------------------------------------------------
# Objets du monde (non posés par le joueur). drops : [objet, min, max, probabilité]
OBJECTS: Dict[str, Any] = {
    "weed": {"sprite": "weed_%v", "variants": 3, "solid": True, "hp": 1, "tools": ["scythe", "hoe", "axe", "pick", "sword"],
             "drops": [["fiber", 1, 2, 1.0]], "xp": ["foraging", 1], "sfx": "scythe"},
    "rock": {"sprite": "rock_small", "solid": True, "hp": 2, "tools": ["pick"], "drops": [["stone", 2, 3, 1.0], ["clay", 1, 1, 0.12]],
             "xp": ["mining", 3], "sfx": "pick", "break_sfx": "rock_break", "fx": "chip"},
    "rock_big": {"sprite": "rock_big", "w": 2, "h": 2, "solid": True, "hp": 8, "tools": ["pick"], "min_level": 2,
                 "drops": [["stone", 10, 14, 1.0], ["coal", 1, 2, 0.5]], "xp": ["mining", 15], "sfx": "pick", "break_sfx": "rock_break", "fx": "chip"},
    "big_log": {"sprite": "big_log", "w": 2, "h": 1, "solid": True, "hp": 8, "tools": ["axe"], "min_level": 2,
                "drops": [["wood", 12, 16, 1.0], ["sap", 1, 3, 0.6]], "xp": ["foraging", 15], "sfx": "axe", "fx": "wood"},
    "stump": {"sprite": "stump_%k", "solid": True, "hp": 4, "tools": ["axe"], "drops": [["wood", 3, 5, 1.0]], "xp": ["foraging", 4], "sfx": "axe", "fx": "wood"},
    "tree": {"sprite": "tree_%k_%s_%g", "solid": True, "hp": 8, "tools": ["axe"], "tall": True,
             "drops": [["wood", 8, 12, 1.0], ["sap", 1, 2, 0.5]], "xp": ["foraging", 12], "sfx": "axe", "break_sfx": "tree_fall", "fx": "wood"},
    "ftree": {"sprite": "ftree_%k_%s_%g", "solid": True, "tall": True},
    "bush": {"sprite": "bush", "solid": True},
    "forage": {"solid": False, "pick": True},
    "dig": {"sprite": "dig_spot", "solid": False, "tools": ["hoe"]},
    "tall_grass": {"sprite": "tall_grass", "solid": False, "hp": 1, "tools": ["scythe"], "drops": [["fiber", 1, 1, 0.4]], "hay": 1, "sfx": "scythe"},
    "node_copper": {"sprite": "node_copper", "solid": True, "hp": 3, "tools": ["pick"], "drops": [["ore_copper", 1, 3, 1.0]], "xp": ["mining", 9], "sfx": "pick", "break_sfx": "rock_break", "fx": "chip"},
    "node_iron": {"sprite": "node_iron", "solid": True, "hp": 5, "tools": ["pick"], "min_level": 2, "drops": [["ore_iron", 1, 3, 1.0]], "xp": ["mining", 13], "sfx": "pick", "break_sfx": "rock_break", "fx": "chip"},
    "node_silver": {"sprite": "node_silver", "solid": True, "hp": 7, "tools": ["pick"], "min_level": 2, "drops": [["ore_silver", 1, 3, 1.0]], "xp": ["mining", 18], "sfx": "pick", "break_sfx": "rock_break", "fx": "chip"},
    "node_brumite": {"sprite": "node_brumite", "solid": True, "hp": 10, "tools": ["pick"], "min_level": 3, "drops": [["ore_brumite", 1, 2, 1.0]], "xp": ["mining", 26], "sfx": "pick", "break_sfx": "rock_break", "fx": "chip"},
    "node_coal": {"sprite": "node_coal", "solid": True, "hp": 3, "tools": ["pick"], "drops": [["coal", 1, 3, 1.0]], "xp": ["mining", 7], "sfx": "pick", "break_sfx": "rock_break", "fx": "chip"},
    "node_gem": {"sprite": "node_gem", "solid": True, "hp": 6, "tools": ["pick"], "drops": [["@gem", 1, 1, 1.0]], "xp": ["mining", 20], "sfx": "pick", "break_sfx": "rock_break", "fx": "sparkle"},
    "mine_rock": {"sprite": "mine_rock_%b", "solid": True, "hp": 2, "tools": ["pick"], "drops": [["stone", 1, 2, 0.8], ["coal", 1, 1, 0.06], ["clay", 1, 1, 0.05]],
                  "xp": ["mining", 3], "sfx": "pick", "break_sfx": "rock_break", "fx": "chip"},
    "crystal": {"sprite": "crystal_%c", "solid": True},
    "ladder_down": {"sprite": "ladder_down", "solid": False},
    "ladder_up": {"sprite": "ladder_up", "solid": False},
    "treasure": {"sprite": "treasure_closed", "solid": True},
}
GEM_WEIGHTS: Dict[str, Any] = {
    "1": {"quartz": 60, "topaz": 30, "amethyst": 10},
    "2": {"quartz": 35, "amethyst": 35, "topaz": 15, "emerald": 15},
    "3": {"amethyst": 25, "emerald": 30, "ruby": 30, "moonstone": 15},
}

# Objets posables : sprite (par défaut l'icône), solide, lumière, emprise.
PLACEABLES: Dict[str, Any] = {
    "chest": {"solid": True, "kind": "chest", "slots": 36},
    "scarecrow": {"solid": True, "sprite": "scarecrow_big", "kind": "scarecrow"},
    "sprinkler_1": {"solid": True, "kind": "sprinkler"},
    "sprinkler_2": {"solid": True, "kind": "sprinkler"},
    "sprinkler_3": {"solid": True, "kind": "sprinkler"},
    "furnace": {"solid": True, "kind": "machine", "active_sprite": "furnace_lit", "light": True},
    "cheese_press": {"solid": True, "kind": "machine"},
    "churn": {"solid": True, "kind": "machine"},
    "loom": {"solid": True, "kind": "machine"},
    "press": {"solid": True, "kind": "machine"},
    "preserve_jar": {"solid": True, "kind": "machine"},
    "smoker": {"solid": True, "kind": "machine"},
    "beehive": {"solid": True, "kind": "machine", "outdoor": True},
    "seed_sorter": {"solid": True, "kind": "machine"},
    "crab_pot": {"solid": True, "kind": "crab_pot", "on_water": True},
    "fence": {"solid": True, "kind": "fence"},
    "wood_path": {"solid": False, "kind": "path", "flat": True},
    "stone_path": {"solid": False, "kind": "path", "flat": True},
    "lantern": {"solid": True, "kind": "decor", "light": True},
    "sign": {"solid": True, "kind": "decor"},
    "birdhouse": {"solid": True, "kind": "decor"},
    "stone_bench": {"solid": True, "kind": "decor"},
    "table": {"solid": True, "kind": "furniture"},
    "chair": {"solid": True, "kind": "furniture"},
    "armchair": {"solid": True, "kind": "furniture"},
    "bookshelf": {"solid": True, "kind": "furniture"},
    "cabinet": {"solid": True, "kind": "furniture"},
    "rug": {"solid": False, "kind": "furniture", "flat": True},
    "lamp": {"solid": True, "kind": "furniture", "light": True},
    "painting": {"solid": False, "kind": "furniture", "wall": True},
    "plant": {"solid": True, "kind": "furniture"},
    "stove": {"solid": True, "kind": "furniture", "light": True},
    "wind_chime": {"solid": False, "kind": "furniture", "wall": True},
    "flower_pot": {"solid": True, "kind": "furniture"},
    "clock": {"solid": True, "kind": "furniture"},
    "pet_bed": {"solid": False, "kind": "furniture", "flat": True},
}

# Machines : durée en minutes de jeu, entrées (objet ou @catégorie), sortie.
MACHINES: Dict[str, Any] = {
    "furnace": {"fuel": {"coal": 1}, "recipes": [
        {"in": "ore_copper", "n": 5, "out": "ingot_copper", "minutes": 60},
        {"in": "ore_iron", "n": 5, "out": "ingot_iron", "minutes": 120},
        {"in": "ore_silver", "n": 5, "out": "ingot_silver", "minutes": 180},
        {"in": "ore_brumite", "n": 5, "out": "ingot_brumite", "minutes": 300}]},
    "cheese_press": {"keep_quality": True, "recipes": [
        {"in": "milk", "n": 1, "out": "cheese", "minutes": 180},
        {"in": "goat_milk", "n": 1, "out": "goat_cheese", "minutes": 180}]},
    "churn": {"keep_quality": True, "recipes": [{"in": "milk", "n": 1, "out": "butter", "minutes": 120}]},
    "loom": {"keep_quality": True, "recipes": [{"in": "wool", "n": 1, "out": "cloth", "minutes": 240}]},
    "press": {"recipes": [
        {"in": "@fruit", "n": 1, "out": "juice", "minutes": 360},
        {"in": "hazelnut", "n": 3, "out": "nut_oil", "minutes": 240}]},
    "preserve_jar": {"recipes": [
        {"in": "@fruit", "n": 1, "out": "jam", "minutes": 480},
        {"in": "@crop", "n": 1, "out": "pickles", "minutes": 480}]},
    "smoker": {"fuel": {"wood": 2}, "recipes": [{"in": "@fish", "n": 1, "out": "smoked_fish", "minutes": 240}]},
    "seed_sorter": {"recipes": [{"in": "@crop", "n": 1, "out": "@seed", "out_n": [1, 3], "minutes": 60}]},
    "beehive": {"passive": {"out": "honey", "days": 3, "seasons": ["spring", "summer", "autumn"]}},
}

ANIMALS: Dict[str, Any] = {
    "chicken": {"home": "coop", "min_level": 1, "price": 400, "product": "egg", "every": 1, "grow_days": 3, "sfx": "cluck"},
    "duck": {"home": "coop", "min_level": 2, "price": 900, "product": "duck_egg", "every": 2, "grow_days": 4, "sfx": "quack",
             "bonus": ["feather", 0.2, 600]},
    "cow": {"home": "barn", "min_level": 1, "price": 1500, "product": "milk", "every": 1, "grow_days": 5, "sfx": "moo"},
    "goat": {"home": "barn", "min_level": 2, "price": 2200, "product": "goat_milk", "every": 2, "grow_days": 5, "sfx": "bleat"},
    "sheep": {"home": "barn", "min_level": 2, "price": 3000, "product": "wool", "every": 3, "grow_days": 5, "sfx": "bleat"},
}

BUILDINGS: Dict[str, Any] = {
    "coop": {"levels": [
        {"price": 4000, "items": {"wood": 150, "stone": 50}, "capacity": 4, "days": 2},
        {"price": 8000, "items": {"wood": 250, "stone": 100}, "capacity": 8, "days": 2}]},
    "barn": {"levels": [
        {"price": 6000, "items": {"wood": 200, "stone": 100}, "capacity": 4, "days": 3},
        {"price": 12000, "items": {"wood": 350, "stone": 200}, "capacity": 8, "days": 3}]},
    "silo": {"levels": [{"price": 1500, "items": {"stone": 80, "clay": 10, "ingot_copper": 3}, "days": 1}]},
    "house": {"levels": [
        {"price": 0, "items": {}, "days": 0},
        {"price": 10000, "items": {"wood": 300}, "days": 3},
        {"price": 30000, "items": {"wood": 400, "stone": 200}, "days": 3}]},
}

# Compétences : à chaque niveau une recette (voir CRAFTS/DISH_UNLOCKS) ou un bonus (perk).
PERKS: Dict[str, Any] = {
    "farming": {"5": ["crop_quality", 0.08], "10": ["crop_price", 0.10]},
    "husbandry": {"3": ["affection_gain", 0.25], "5": ["animal_price", 0.10], "7": ["affection_gain", 0.25], "9": ["product_quality", 0.15], "10": ["animal_price", 0.10]},
    "fishing": {"4": ["fish_window", 0.015], "6": ["bait_saver", 0.3], "7": ["fish_window", 0.015], "8": ["fish_quality", 0.15], "9": ["treasure_chance", 0.08], "10": ["fish_price", 0.15]},
    "mining": {"5": ["ore_bonus", 0.15], "7": ["gem_chance", 0.03], "8": ["ore_bonus", 0.15], "9": ["ladder_chance", 0.04], "10": ["mineral_price", 0.15]},
    "combat": {"3": ["max_health", 15], "4": ["damage", 2], "6": ["max_health", 15], "7": ["crit_chance", 0.08], "8": ["damage", 3], "9": ["defense", 2], "10": ["max_health", 30]},
    "foraging": {"4": ["double_forage", 0.15], "6": ["wood_bonus", 0.25], "8": ["double_forage", 0.15], "9": ["forage_quality", 0.2], "10": ["forage_price", 0.15]},
}

# Déblocage des plats (les autres s'achètent à l'auberge ou viennent des amitiés).
DISH_UNLOCKS: Dict[str, str] = {
    "omelette": "start", "grilled_fish": "start", "bread": "start",
    "crepes": "shop:inn", "spring_salad": "friend:capucine:2", "turnip_soup": "shop:inn", "wild_garlic_soup": "skill:foraging:1",
    "cherry_clafoutis": "friend:roseline:6", "ratatouille": "shop:inn", "tian": "friend:capucine:5", "melon_frappe": "friend:pim:2",
    "lavender_tea": "friend:hyacinthe:4", "fried_gudgeon": "skill:fishing:1", "grilled_sardines": "friend:maiwenn:2",
    "hazelnut_trout": "friend:maiwenn:5", "fisher_stew": "skill:fishing:8", "pike_butter": "shop:inn", "mushroom_pan": "skill:foraging:6",
    "roast_chestnuts": "start", "pumpkin_veloute": "friend:roseline:3", "leek_gratin": "friend:gaspard:2", "garden_stew": "shop:inn",
    "apple_tart": "friend:theodule:4", "cheese_galette": "friend:theodule:2", "winter_salad": "shop:inn", "sunchoke_soup": "skill:mining:1",
    "parsnip_gratin": "friend:corentin:5", "frostberry_tart": "friend:isaure:4", "miner_stew": "skill:combat:1",
}

# Boutiques : horaires en heures, jour de fermeture (0 = lundi … 6 = dimanche).
SHOPS: Dict[str, Any] = {
    "store": {"npc": "capucine", "open": 9, "close": 18, "closed_day": 6,
              "stock": ["@seeds", "@saplings", "flour", "compost", "rich_fertilizer", "quick_soil", "bouquet", "braided_ring"],
              "services": ["backpack"]},
    "forge": {"npc": "bastien", "open": 9, "close": 17, "closed_day": 0,
              "stock": ["coal", ["ore_copper", 60], ["ore_iron", 120], ["ore_silver", 220]], "services": ["tool_upgrade"]},
    "carpentry": {"npc": "isaure", "open": 9, "close": 17, "closed_day": 2,
                  "stock": [["wood", 12], ["stone", 18], "table", "chair", "armchair", "bookshelf", "cabinet", "rug", "lamp", "painting",
                            "plant", "stove", "clock", "wallpaper_1", "wallpaper_2", "wallpaper_3", "wallpaper_4",
                            "floor_1", "floor_2", "floor_3", "floor_4"], "services": ["build"]},
    "ranch": {"npc": "theodule", "open": 8, "close": 16, "closed_day": 3, "stock": ["hay", "pet_bed"], "services": ["animals"]},
    "fishshop": {"npc": "maiwenn", "open": 6, "close": 14, "closed_day": 1, "stock": ["bait", "crab_pot", ["rod_2", 1500]], "services": []},
    "inn": {"npc": "gaspard", "open": 12, "close": 23, "closed_day": -1,
            "stock": [["bread", 180], ["garden_stew", 480], ["crepes", 300]], "services": ["recipes"],
            "recipes": {"crepes": 600, "turnip_soup": 500, "ratatouille": 900, "pike_butter": 1200, "garden_stew": 800, "winter_salad": 500}},
    "clinic": {"npc": "hyacinthe", "open": 9, "close": 15, "closed_day": 5, "stock": [["healing_salve", 220], ["field_snack", 90]], "services": []},
    "market": {"npc": "", "open": 8, "close": 14, "only_day": 6, "requires": "bell:hearth",
               "stock": ["@seeds_all", ["honey", 260], ["cloth", 800], ["nut_oil", 420], ["moonstone", 1500]], "services": []},
}

WEATHER: Dict[str, Any] = {
    "kinds": ["sun", "rain", "storm", "wind", "snow"],
    "spring": {"sun": 55, "rain": 25, "wind": 12, "storm": 8},
    "summer": {"sun": 62, "rain": 14, "storm": 14, "wind": 10},
    "autumn": {"sun": 45, "rain": 28, "wind": 20, "storm": 7},
    "winter": {"sun": 45, "snow": 40, "wind": 15},
}

MONSTERS: Dict[str, Any] = {
    "pebbler": {"hp": 20, "damage": 6, "speed": 24, "ai": "chase", "xp": 6, "drops": [["stone", 1, 2, 0.8], ["coal", 1, 1, 0.2]]},
    "mosshop": {"hp": 28, "damage": 8, "speed": 70, "ai": "hop", "xp": 9, "drops": [["fiber", 1, 3, 0.8], ["sap", 1, 1, 0.4]]},
    "emberbat": {"hp": 34, "damage": 11, "speed": 52, "ai": "zigzag", "fly": True, "xp": 14, "drops": [["coal", 1, 2, 0.6], ["topaz", 1, 1, 0.05]]},
    "frostspit": {"hp": 46, "damage": 12, "speed": 0, "ai": "shoot", "xp": 18, "drops": [["quartz", 1, 1, 0.3], ["ore_silver", 1, 1, 0.12]]},
    "glowmite": {"hp": 22, "damage": 9, "speed": 78, "ai": "swarm", "pack": [3, 4], "xp": 11, "drops": [["ore_brumite", 1, 1, 0.10], ["amethyst", 1, 1, 0.04]]},
    "shellcharger": {"hp": 110, "damage": 20, "speed": 150, "ai": "charge", "xp": 40, "drops": [["ore_brumite", 1, 2, 0.9], ["ruby", 1, 1, 0.06], ["moonstone", 1, 1, 0.02]]},
}

MINE: Dict[str, Any] = {
    "biomes": {
        "1": {"rocks": 0.16, "nodes": {"node_copper": 55, "node_coal": 35, "node_gem": 10}, "node_density": 0.022,
              "monsters": {"pebbler": 60, "mosshop": 40}, "monster_count": [1, 4], "music": "mine"},
        "2": {"rocks": 0.18, "nodes": {"node_iron": 45, "node_copper": 15, "node_silver": 18, "node_coal": 12, "node_gem": 10}, "node_density": 0.026,
              "monsters": {"emberbat": 45, "frostspit": 30, "mosshop": 25}, "monster_count": [2, 5], "music": "mine"},
        "3": {"rocks": 0.20, "nodes": {"node_brumite": 30, "node_silver": 35, "node_iron": 15, "node_gem": 20}, "node_density": 0.03,
              "monsters": {"glowmite": 45, "shellcharger": 20, "frostspit": 20, "emberbat": 15}, "monster_count": [3, 6], "music": "mine"},
    },
    "treasures": {
        "10": [["quarry_charge", 5], ["ingot_copper", 3]],
        "20": [["amethyst", 2], ["rope_ladder", 3]],
        "30": [["ingot_iron", 5], ["healing_salve", 3]],
        "40": [["emerald", 1], ["ledger_page", 1]],
        "50": [["ingot_silver", 5], ["bell_charm", 2]],
        "60": [["moonstone", 2], ["ingot_brumite", 3]],
    },
    "treasure_money": {"10": 300, "20": 600, "30": 1000, "40": 1500, "50": 2500, "60": 5000},
    "pool_chance": 0.25,
}

HOUSE: Dict[str, Any] = {
    "levels": {"1": {"map": "farmhouse_1", "kitchen": False}, "2": {"map": "farmhouse_2", "kitchen": True},
               "3": {"map": "farmhouse_3", "kitchen": True}},
    "wallpapers": 4, "floors": 4,
}

START_ITEMS: List[List[Any]] = [
    ["hoe_1", 1], ["can_1", 1], ["axe_1", 1], ["pick_1", 1], ["scythe_1", 1], ["sword_1", 1], ["rod_1", 1], ["seed_turnip", 12], ["field_snack", 2],
]
