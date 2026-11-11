class_name MapRuntime
extends RefCounted
## Données d'exécution d'une carte : terrain, collisions, objets et sol labouré.
## L'état modifiable vit dans GameState.maps[id] (objets, sol) pour être sauvegardé.

const T: int = 16

var id: String = ""
var data: Dictionary = {}
var w: int = 0
var h: int = 0
var state: Dictionary = {}

var _chars: Dictionary = {}
var _rows: Array = []
var _static_solid: Dictionary = {}
var _occupy: Dictionary = {}


func _init(map_id: String) -> void:
	id = map_id
	data = Database.map(map_id)
	w = int(data.get("w", 0))
	h = int(data.get("h", 0))
	_rows = data.get("rows", [])
	var terr: Dictionary = Database.table("terrains")
	for tid: String in terr:
		_chars[str(terr[tid]["ch"])] = terr[tid]
	state = GameState.map_state(map_id)
	if not state.has("init"):
		_initial_objects()
	rebuild_statics()
	rebuild_occupancy()


func _initial_objects() -> void:
	state["init"] = true
	for o: Dictionary in data.get("objects", []):
		var obj: Dictionary = o.duplicate()
		var origin: Vector2i = Vector2i(int(obj["x"]), int(obj["y"]))
		obj.erase("x")
		obj.erase("y")
		if not obj.has("hp"):
			obj["hp"] = int(WorldObjects.def_of(obj).get("hp", 1))
		state["objects"][GameState.key(origin)] = obj


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < w and c.y < h


func terrain_at(c: Vector2i) -> Dictionary:
	if not in_bounds(c):
		return _chars[" "]
	var row: String = _rows[c.y]
	return _chars.get(row[c.x], _chars[" "])


func terrain_id(c: Vector2i) -> String:
	return str(terrain_at(c)["id"])


func is_interior() -> bool:
	return data.has("interior")


# --- statiques ----------------------------------------------------------------

func static_visible(st: Dictionary) -> bool:
	if st.has("flag") and not GameState.flag(str(st["flag"])):
		return false
	if st.has("not_flag") and GameState.flag(str(st["not_flag"])):
		return false
	return true


func rebuild_statics() -> void:
	_static_solid.clear()
	for st: Dictionary in data.get("statics", []):
		if not bool(st.get("solid", false)) or not static_visible(st):
			continue
		var door: Variant = st.get("door")
		for j: int in int(st["h"]):
			for i: int in int(st["w"]):
				var c: Vector2i = Vector2i(int(st["x"]) + i, int(st["y"]) + j)
				if door != null and c == Vector2i(int(door[0]), int(door[1])):
					continue
				_static_solid[c] = true


# --- objets -------------------------------------------------------------------

func objects() -> Dictionary:
	return state["objects"]


func soil() -> Dictionary:
	return state["soil"]


func rebuild_occupancy() -> void:
	_occupy.clear()
	for k: String in state["objects"]:
		_mark(GameState.cell_of(k), state["objects"][k])


func _mark(origin: Vector2i, obj: Dictionary) -> void:
	var size: Vector2i = WorldObjects.size_of(obj)
	for j: int in size.y:
		for i: int in size.x:
			_occupy[origin + Vector2i(i, j)] = origin


func origin_at(c: Vector2i) -> Variant:
	return _occupy.get(c)


func object_at(c: Vector2i) -> Dictionary:
	var o: Variant = _occupy.get(c)
	if o == null:
		return {}
	return state["objects"].get(GameState.key(o), {})


func add_object(origin: Vector2i, obj: Dictionary) -> void:
	state["objects"][GameState.key(origin)] = obj
	_mark(origin, obj)
	EventBus.object_changed.emit(id, origin)


func remove_object(origin: Vector2i) -> void:
	var k: String = GameState.key(origin)
	var obj: Dictionary = state["objects"].get(k, {})
	if obj.is_empty():
		return
	var size: Vector2i = WorldObjects.size_of(obj)
	for j: int in size.y:
		for i: int in size.x:
			_occupy.erase(origin + Vector2i(i, j))
	state["objects"].erase(k)
	EventBus.object_changed.emit(id, origin)


func touch_object(origin: Vector2i) -> void:
	EventBus.object_changed.emit(id, origin)


func is_solid(c: Vector2i) -> bool:
	if not in_bounds(c):
		return true
	if bool(terrain_at(c).get("solid", false)):
		return true
	if _static_solid.has(c):
		return true
	var o: Dictionary = object_at(c)
	return not o.is_empty() and bool(WorldObjects.def_of(o).get("solid", false))


# --- sol labouré ---------------------------------------------------------------

func soil_at(c: Vector2i) -> Dictionary:
	return state["soil"].get(GameState.key(c), {})


func set_soil(c: Vector2i, s: Dictionary) -> void:
	state["soil"][GameState.key(c)] = s
	EventBus.soil_changed.emit(id, c)


func clear_soil(c: Vector2i) -> void:
	state["soil"].erase(GameState.key(c))
	EventBus.soil_changed.emit(id, c)


func touch_soil(c: Vector2i) -> void:
	EventBus.soil_changed.emit(id, c)


# --- zones, passages, points -----------------------------------------------------

func warp_at(c: Vector2i) -> Dictionary:
	for wp: Dictionary in data.get("warps", []):
		if wp.has("flag") and not GameState.flag(str(wp["flag"])):
			continue
		if c.x >= int(wp["x"]) and c.x < int(wp["x"]) + int(wp["w"]) and c.y >= int(wp["y"]) and c.y < int(wp["y"]) + int(wp["h"]):
			return wp
	return {}


func zone_at(c: Vector2i) -> Dictionary:
	for z: Dictionary in data.get("interact", []):
		if c.x >= int(z["x"]) and c.x < int(z["x"]) + int(z["w"]) and c.y >= int(z["y"]) and c.y < int(z["y"]) + int(z["h"]):
			return z
	return {}


func spot(spot_name: String) -> Vector2i:
	var s: Array = data.get("spots", {}).get(spot_name, [1, 1])
	return Vector2i(int(s[0]), int(s[1]))


## Position en pixels des pieds pour une case (bas de la case, centré).
static func foot_pixel(c: Vector2i) -> Vector2:
	return Vector2(c.x * T + T / 2, c.y * T + T - 2)


static func cell_of_pixel(p: Vector2) -> Vector2i:
	return Vector2i(int(floorf(p.x / T)), int(floorf(p.y / T)))
