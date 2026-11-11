extends Node
## État persistant de la partie. Tout est en types JSON (dictionnaires, tableaux,
## nombres, chaînes) pour que la sauvegarde soit un simple aller-retour.

const SAVE_FIELDS: Array[String] = [
	"player_name", "farm_name", "outfit", "money", "energy", "max_energy", "health", "max_health",
	"inventory", "inventory_size", "hotbar_index", "day", "minutes", "weather", "weather_tomorrow",
	"map_id", "px", "py", "facing", "skills", "maps", "relations", "quests", "story", "stats",
	"collections", "shipping", "buildings", "animals", "house", "tool_upgrade", "recipes",
	"buffs", "mine", "flags", "pet", "seed", "playtime", "spouse", "pending_mail", "can_water",
]
const SKILLS: Array[String] = ["farming", "husbandry", "fishing", "mining", "combat", "foraging"]

var active: bool = false   # une partie est-elle chargée ?

var player_name: String = ""
var farm_name: String = ""
var outfit: int = 0
var money: int = 0
var energy: float = 0.0
var max_energy: int = 0
var health: float = 0.0
var max_health: int = 0
var inventory: Array = []
var inventory_size: int = 36
var hotbar_index: int = 0
var day: int = 0
var minutes: int = 360
var weather: String = "sun"
var weather_tomorrow: String = "sun"
var map_id: String = "farm"
var px: float = 0.0
var py: float = 0.0
var facing: int = 0
var skills: Dictionary = {}
var maps: Dictionary = {}
var relations: Dictionary = {}
var quests: Dictionary = {}
var story: Dictionary = {}
var stats: Dictionary = {}
var collections: Dictionary = {}
var shipping: Array = []
var buildings: Dictionary = {}
var animals: Array = []
var house: Dictionary = {}
var tool_upgrade: Dictionary = {}
var recipes: Dictionary = {}
var buffs: Array = []
var mine: Dictionary = {}
var flags: Dictionary = {}
var pet: Dictionary = {}
var seed: int = 0
var playtime: float = 0.0
var spouse: String = ""
var pending_mail: Array = []
var can_water: int = 0


func reset() -> void:
	active = false
	player_name = ""
	farm_name = ""
	outfit = 0
	money = Database.bal_i("start_money", 500)
	max_energy = Database.bal_i("start_energy", 100)
	energy = float(max_energy)
	max_health = Database.bal_i("start_health", 100)
	health = float(max_health)
	inventory_size = Database.bal_i("inventory_base_size", 36)
	inventory = []
	inventory.resize(inventory_size)
	hotbar_index = 0
	day = 0
	minutes = TimeManager.DAY_START
	weather = "sun"
	weather_tomorrow = "sun"
	map_id = "farm"
	px = 0.0
	py = 0.0
	facing = 0
	skills = {}
	for s: String in SKILLS:
		skills[s] = {"xp": 0, "level": 1}
	maps = {}
	relations = {}
	quests = {"board": [], "active": [], "done": 0}
	story = {"bells": {}, "notes": {}}
	stats = {}
	collections = {"donated": {}, "rewards": {}}
	shipping = []
	shipping.resize(Database.bal_i("shipping_size", 36))
	buildings = {}
	animals = []
	house = {"level": 1, "upgrade_days": 0, "wallpaper": 0, "floor": 0}
	tool_upgrade = {}
	recipes = {}
	buffs = []
	mine = {"deepest": 0, "elevator": 0}
	flags = {}
	pet = {}
	seed = 0
	playtime = 0.0
	spouse = ""
	pending_mail = []
	can_water = 0


## Démarre une nouvelle partie : état neuf, objets de départ, réveil dans la maison.
func new_game(p_name: String, p_farm: String, p_outfit: int) -> void:
	reset()
	active = true
	player_name = p_name
	farm_name = p_farm
	outfit = clampi(p_outfit, 0, 2)
	seed = randi()
	weather = "sun"
	weather_tomorrow = "sun"
	for entry: Array in Database.table("tools").get("start_items", []):
		add_item(str(entry[0]), int(entry[1]))
	pet = {"type": "dog", "name": Loc.t("PET_NAME"), "affection": 0, "petted": false}
	Recipes.refresh(false)
	Skills.recompute_stats()
	energy = float(max_energy)
	health = float(max_health)
	map_id = "farmhouse_1"
	var spot: Array = Database.map("farmhouse_1").get("spots", {}).get("bed", [2, 4])
	px = float(int(spot[0]) * 16 + 8)
	py = float(int(spot[1]) * 16 + 14)
	facing = 0


func house_map() -> String:
	return "farmhouse_%d" % clampi(int(house.get("level", 1)), 1, 3)


func to_dict() -> Dictionary:
	var d: Dictionary = {}
	for f: String in SAVE_FIELDS:
		d[f] = get(f)
	return d.duplicate(true)


func from_dict(d: Dictionary) -> void:
	reset()
	for f: String in SAVE_FIELDS:
		if not d.has(f):
			continue
		var cur: Variant = get(f)
		var v: Variant = d[f]
		if typeof(cur) == TYPE_FLOAT and typeof(v) == TYPE_INT:
			v = float(v)
		elif typeof(cur) == TYPE_INT and typeof(v) == TYPE_FLOAT:
			v = int(v)
		if typeof(v) == typeof(cur):
			set(f, v)
	inventory.resize(inventory_size)
	for s: String in SKILLS:
		if not skills.has(s):
			skills[s] = {"xp": 0, "level": 1}
	active = true


# --- accès pratiques ---------------------------------------------------------

func map_state(id: String) -> Dictionary:
	if not maps.has(id):
		maps[id] = {"objects": {}, "soil": {}}
	return maps[id]


static func key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


static func cell_of(k: String) -> Vector2i:
	var p: PackedStringArray = k.split(",")
	return Vector2i(int(p[0]), int(p[1]))


func add_money(amount: int) -> void:
	money = maxi(0, money + amount)
	if amount > 0:
		add_stat("money_earned", amount)
	EventBus.money_changed.emit(money)


func spend(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	add_stat("money_spent", amount)
	EventBus.money_changed.emit(money)
	return true


func change_energy(delta: float) -> void:
	energy = clampf(energy + delta, 0.0, float(max_energy))
	EventBus.energy_changed.emit(energy, float(max_energy))


func change_health(delta: float) -> void:
	health = clampf(health + delta, 0.0, float(max_health))
	EventBus.health_changed.emit(health, float(max_health))


func add_stat(stat: String, amount: int = 1, sub: String = "") -> void:
	if sub == "":
		stats[stat] = int(stats.get(stat, 0)) + amount
	else:
		if not stats.has(stat) or typeof(stats[stat]) != TYPE_DICTIONARY:
			stats[stat] = {}
		stats[stat][sub] = int(stats[stat].get(sub, 0)) + amount


func stat(stat_name: String, sub: String = "") -> int:
	var v: Variant = stats.get(stat_name, 0)
	if sub != "":
		return int((v as Dictionary).get(sub, 0)) if typeof(v) == TYPE_DICTIONARY else 0
	if typeof(v) == TYPE_DICTIONARY:
		var total: int = 0
		for k: Variant in (v as Dictionary):
			total += int(v[k])
		return total
	return int(v)


## Nombre d'entrées distinctes d'une statistique à sous-clés (ex. espèces pêchées).
func stat_kinds(stat_name: String) -> int:
	var v: Variant = stats.get(stat_name, {})
	return (v as Dictionary).size() if typeof(v) == TYPE_DICTIONARY else 0


func flag(flag_name: String) -> bool:
	return bool(flags.get(flag_name, false))


func set_flag(flag_name: String, value: bool = true) -> void:
	flags[flag_name] = value


func add_item(id: String, count: int = 1, quality: int = 0) -> int:
	var left: int = Inv.add(inventory, id, count, quality)
	if left < count:
		EventBus.inventory_changed.emit()
		EventBus.item_gained.emit(id, count - left, quality)
	return left


func remove_item(id: String, count: int = 1) -> bool:
	if Inv.count(inventory, id) < count:
		return false
	Inv.remove(inventory, id, count)
	EventBus.inventory_changed.emit()
	return true


func item_count(id: String) -> int:
	return Inv.count(inventory, id)


func held() -> Dictionary:
	var s: Variant = inventory[hotbar_index] if hotbar_index < inventory.size() else null
	return s if typeof(s) == TYPE_DICTIONARY else {}


func held_id() -> String:
	return str(held().get("id", ""))


func skill_level(skill: String) -> int:
	return int(skills.get(skill, {}).get("level", 1))


func buff_total(stat_name: String) -> float:
	var total: float = 0.0
	for b: Variant in buffs:
		if str(b.get("stat", "")) == stat_name:
			total += float(b.get("amount", 0.0))
	return total
