class_name Buildings
extends RefCounted
## Bâtiments de la ferme (poulailler, étable, silo) et amélioration de la maison : coûts, chantiers, capacités.

const TYPES: Array[String] = ["coop", "barn", "silo", "house"]


static func table() -> Dictionary:
	return Database.table("buildings")


static func level(type: String) -> int:
	if type == "house":
		return int(GameState.house.get("level", 1))
	return int(GameState.buildings.get(type, {}).get("level", 0))


static func max_level(type: String) -> int:
	return (table()[type]["levels"] as Array).size()


static func next_level(type: String) -> int:
	return level(type) + 1


static func in_progress(type: String) -> bool:
	return GameState.flags.has("construction") and str(GameState.flags["construction"].get("type", "")) == type


static func builder_busy() -> bool:
	return GameState.flags.has("construction")


## Description du prochain chantier : {"price", "items", "days", "level"} ou {} s'il n'y en a plus.
static func next_cost(type: String) -> Dictionary:
	var lv: int = next_level(type)
	var levels: Array = table()[type]["levels"]
	if lv > levels.size() or (type == "house" and lv < 2):
		return {}
	var d: Dictionary = (levels[lv - 1] as Dictionary).duplicate()
	d["level"] = lv
	return d


static func can_start(type: String) -> String:
	var c: Dictionary = next_cost(type)
	if c.is_empty():
		return "BUILD_MAXED"
	if builder_busy():
		return "BUILD_BUSY"
	if type != "coop" and type != "barn" and type != "silo" and type != "house":
		return "BUILD_MAXED"
	if GameState.money < int(c["price"]):
		return "SHOP_NO_MONEY"
	for id: String in c["items"]:
		if GameState.item_count(id) < int(c["items"][id]):
			return "CRAFT_MISSING"
	return ""


## Lance le chantier (paye et retire les matériaux). Renvoie "" ou une clé d'erreur.
static func start(type: String) -> String:
	var err: String = can_start(type)
	if err != "":
		return err
	var c: Dictionary = next_cost(type)
	GameState.spend(int(c["price"]))
	for id: String in c["items"]:
		GameState.remove_item(id, int(c["items"][id]))
	GameState.flags["construction"] = {"type": type, "level": int(c["level"]), "days": int(c["days"])}
	AudioManager.sfx("buy")
	return ""


## Chaque nuit : le chantier avance ; renvoie le type terminé ou "".
static func nightly() -> String:
	if not GameState.flags.has("construction"):
		return ""
	var c: Dictionary = GameState.flags["construction"]
	c["days"] = int(c["days"]) - 1
	if int(c["days"]) > 0:
		return ""
	var type: String = str(c["type"])
	var lv: int = int(c["level"])
	GameState.flags.erase("construction")
	if type == "house":
		GameState.house["level"] = lv
	else:
		var st: Dictionary = GameState.buildings.get(type, {"out": [], "hay": 0})
		st["level"] = lv
		GameState.buildings[type] = st
	return type


static func capacity(type: String) -> int:
	var lv: int = level(type)
	if lv <= 0:
		return 0
	return int(table()[type]["levels"][lv - 1].get("capacity", 0))


# --- géométrie à l'écran ---------------------------------------------------------

## Emprise et sprite d'un bâtiment sur la ferme : {"s","x","y","w","h","door":[x,y]} ou {}.
static func footprint(type: String) -> Dictionary:
	var lv: int = level(type)
	if lv <= 0:
		return {}
	var lots: Dictionary = Database.map("farm").get("lots", {})
	match type:
		"coop":
			var lot: Dictionary = lots["coop"]
			var w: int = 4 if lv == 1 else 5
			return {"s": "coop_%d" % lv, "x": int(lot["x"]), "y": int(lot["y"]), "w": w, "h": 3, "door": [int(lot["x"]) + 2, int(lot["y"]) + 2],
				"interior": "coop_in_%d" % lv}
		"barn":
			var lot2: Dictionary = lots["barn"]
			var w2: int = 5 if lv == 1 else 7
			var x0: int = int(lot2["x"]) if lv == 1 else int(lot2["x"]) - 1
			return {"s": "barn_%d" % lv, "x": x0, "y": int(lot2["y"]), "w": w2, "h": 3, "door": [x0 + w2 / 2, int(lot2["y"]) + 2],
				"interior": "barn_in_%d" % lv}
		"silo":
			var lot3: Dictionary = lots["silo"]
			return {"s": "silo", "x": int(lot3["x"]), "y": int(lot3["y"]), "w": 2, "h": 2}
	return {}


## Foyer : maison selon son niveau (la porte reste en (28, 10)).
static func house_footprint() -> Dictionary:
	var lv: int = clampi(level("house"), 1, 3)
	var w: int = [5, 6, 7][lv - 1]
	var x0: int = [26, 26, 25][lv - 1]
	return {"s": "house_%d" % lv, "x": x0, "y": 8, "w": w, "h": 3, "door": [28, 10]}
