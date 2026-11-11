extends Node
## Charge toutes les définitions data-driven (data/*.json) et sert les textures d'atlas.

const DATA_DIR: String = "res://data/"
const TABLES: Array[String] = [
	"items", "crops", "fruit_trees", "fish", "recipes", "npcs", "dialogues", "events", "shops",
	"objects", "animals", "buildings", "machines", "monsters", "skills", "story", "festivals",
	"quests", "collections", "weather", "balance", "atlas", "mine", "house", "terrains", "tools", "calendar",
]
const ICON_SIZE: int = 16
const ICON_COLS: int = 16

var tables: Dictionary = {}
var maps: Dictionary = {}
var items: Dictionary = {}
var crops: Dictionary = {}
var balance: Dictionary = {}

var _icon_sheet: Texture2D
var _icons: Dictionary = {}
var _sprites: Dictionary = {}
var _sheets: Dictionary = {}


func _ready() -> void:
	reload()


func reload() -> void:
	tables.clear()
	maps.clear()
	for t: String in TABLES:
		tables[t] = _read_json(DATA_DIR + t + ".json", {})
	items = table("items")
	crops = table("crops")
	balance = table("balance")
	var index: Variant = _read_json(DATA_DIR + "maps/index.json", [])
	if typeof(index) == TYPE_ARRAY:
		for id: Variant in index:
			var m: Variant = _read_json(DATA_DIR + "maps/%s.json" % str(id), {})
			if typeof(m) == TYPE_DICTIONARY and not (m as Dictionary).is_empty():
				maps[str(id)] = m


func _read_json(path: String, fallback: Variant) -> Variant:
	if not FileAccess.file_exists(path):
		return fallback
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null:
		push_error("JSON invalide : " + path)
		return fallback
	return normalize(parsed)


## Le parseur JSON de Godot rend tous les nombres en float : on rétablit les entiers.
static func normalize(v: Variant) -> Variant:
	match typeof(v):
		TYPE_FLOAT:
			var f: float = v
			if f == floorf(f) and absf(f) < 9.0e15:
				return int(f)
			return f
		TYPE_ARRAY:
			var a: Array = v
			for i: int in a.size():
				a[i] = normalize(a[i])
			return a
		TYPE_DICTIONARY:
			var d: Dictionary = v
			for k: Variant in d.keys():
				d[k] = normalize(d[k])
			return d
	return v


func table(table_name: String) -> Dictionary:
	var t: Variant = tables.get(table_name, {})
	return t if typeof(t) == TYPE_DICTIONARY else {}


func item(id: String) -> Dictionary:
	return items.get(id, {})


func has_item(id: String) -> bool:
	return items.has(id)


func item_name(id: String) -> String:
	return tr("ITEM_" + id.to_upper())


func item_desc(id: String) -> String:
	return tr("ITEMD_" + id.to_upper())


## Valeur d'équilibrage nommée (data/balance.json) — pas de nombre magique dans le code.
func bal(key: String, fallback: Variant = 0) -> Variant:
	return balance.get(key, fallback)


func bal_f(key: String, fallback: float = 0.0) -> float:
	return float(balance.get(key, fallback))


func bal_i(key: String, fallback: int = 0) -> int:
	return int(balance.get(key, fallback))


func sell_price(id: String, quality: int = 0) -> int:
	var base: int = int(item(id).get("price", 0))
	var mult: Array = bal("quality_price_mult", [1.0, 1.25, 1.5])
	return int(round(base * float(mult[clampi(quality, 0, mult.size() - 1)])))


func sheet(sheet_name: String) -> Texture2D:
	if _sheets.has(sheet_name):
		return _sheets[sheet_name]
	var path: String = "res://assets/%s.png" % sheet_name
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_sheets[sheet_name] = tex
	return tex


func icon(id: String) -> Texture2D:
	if _icons.has(id):
		return _icons[id]
	if _icon_sheet == null:
		_icon_sheet = sheet("sprites/icons")
	var tex: AtlasTexture = null
	if _icon_sheet != null and items.has(id):
		var idx: int = int(items[id].get("icon", 0))
		tex = AtlasTexture.new()
		tex.atlas = _icon_sheet
		tex.region = Rect2((idx % ICON_COLS) * ICON_SIZE, (idx / ICON_COLS) * ICON_SIZE, ICON_SIZE, ICON_SIZE)
	_icons[id] = tex
	return tex


## Sprite nommé dans l'atlas (data/atlas.json : feuille + rectangle).
func sprite(sprite_name: String) -> AtlasTexture:
	if _sprites.has(sprite_name):
		return _sprites[sprite_name]
	var tex: AtlasTexture = null
	var info: Dictionary = table("atlas").get(sprite_name, {})
	if not info.is_empty():
		var base: Texture2D = sheet(str(info["sheet"]))
		if base != null:
			tex = AtlasTexture.new()
			tex.atlas = base
			tex.region = Rect2(int(info["x"]), int(info["y"]), int(info["w"]), int(info["h"]))
	_sprites[sprite_name] = tex
	return tex


func sprite_info(sprite_name: String) -> Dictionary:
	return table("atlas").get(sprite_name, {})


func map(id: String) -> Dictionary:
	if not maps.has(id) and id.begins_with("mine_"):
		var f: int = MineGen.floor_of(id)
		if f >= 1 and f <= MineGen.floor_count():
			maps[id] = MineGen.generate(f)
	return maps.get(id, {})


func has_map(id: String) -> bool:
	return not map(id).is_empty()


## Les étages de la mine sont régénérés chaque jour.
func forget_mine_floors() -> void:
	for id: String in maps.keys():
		if id.begins_with("mine_"):
			maps.erase(id)
