class_name MapView
extends Node2D
## Affichage d'une carte : terrain en tuiles (2 couches + sol labouré), objets et décors triés en profondeur.

const T: int = 16
const DIRS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const BITS: Array[int] = [1, 2, 4, 8]
const SHEETS: Array[String] = [
	"water", "dirt", "sand", "path", "cobble", "wood", "cliff", "void", "tilled", "tilled_wet",
	"grass_spring", "grass_summer", "grass_autumn", "grass_winter",
	"mine_floor_1", "mine_floor_2", "mine_floor_3", "mine_wall_1", "mine_wall_2", "mine_wall_3",
	"floor_0", "floor_1", "floor_2", "floor_3", "wall_0", "wall_1", "wall_2", "wall_3",
	"wall_low_0", "wall_low_1", "wall_low_2", "wall_low_3",
]
const SHAKE_PX: float = 1.5

static var _tileset: TileSet = null
static var _source_ids: Dictionary = {}

var rt: MapRuntime
var season: String = "spring"
var base_layer: TileMapLayer
var top_layer: TileMapLayer
var soil_layer: TileMapLayer
var sorted: Node2D
var _obj_nodes: Dictionary = {}
var _crop_nodes: Dictionary = {}
var _static_nodes: Array[Sprite2D] = []
var _crop_tex: Dictionary = {}
var _wall_style: int = 0
var _floor_style: int = 0


static func tileset() -> TileSet:
	if _tileset != null:
		return _tileset
	var ts: TileSet = TileSet.new()
	ts.tile_size = Vector2i(T, T)
	for sheet_name: String in SHEETS:
		var tex: Texture2D = load("res://assets/tiles/%s.png" % sheet_name)
		var src: TileSetAtlasSource = TileSetAtlasSource.new()
		src.texture = tex
		src.texture_region_size = Vector2i(T, T)
		if sheet_name == "water":
			src.create_tile(Vector2i.ZERO)
			src.set_tile_animation_frames_count(Vector2i.ZERO, 4)
			for f: int in 4:
				src.set_tile_animation_frame_duration(Vector2i.ZERO, f, 0.35)
		else:
			for y: int in 5:
				for x: int in 4:
					src.create_tile(Vector2i(x, y))
		_source_ids[sheet_name] = ts.add_source(src)
	_tileset = ts
	return ts


func _init(p_rt: MapRuntime = null) -> void:
	rt = p_rt


func _ready() -> void:
	var ts: TileSet = tileset()
	base_layer = _layer(ts, -20)
	top_layer = _layer(ts, -19)
	soil_layer = _layer(ts, -18)
	sorted = Node2D.new()
	sorted.name = "Sorted"
	sorted.y_sort_enabled = true
	add_child(sorted)
	rebuild_all()
	EventBus.object_changed.connect(_on_object_changed)
	EventBus.soil_changed.connect(_on_soil_changed)


func _layer(ts: TileSet, z: int) -> TileMapLayer:
	var l: TileMapLayer = TileMapLayer.new()
	l.tile_set = ts
	l.z_index = z
	add_child(l)
	return l


func sid(sheet_name: String) -> int:
	return int(_source_ids[sheet_name])


func rebuild_all() -> void:
	season = TimeManager.season_id()
	var style: Dictionary = rt.data.get("style", {})
	if rt.data.get("interior", "") == "house":
		_wall_style = int(GameState.house.get("wallpaper", 0))
		_floor_style = int(GameState.house.get("floor", 0))
	else:
		_wall_style = int(style.get("wall", 0))
		_floor_style = int(style.get("floor", 0))
	_rebuild_ground()
	_rebuild_soil()
	rebuild_objects()


func _sheet_name(tid: String) -> String:
	match tid:
		"grass":
			return "grass_" + season
		"floor":
			return "floor_%d" % _floor_style
		"wall":
			return "wall_%d" % _wall_style
		"wall_low":
			return "wall_low_%d" % _wall_style
	return tid


func _variant(c: Vector2i) -> int:
	return absi(hash(c)) % 4


func _rebuild_ground() -> void:
	base_layer.clear()
	top_layer.clear()
	var terr: Dictionary = Database.table("terrains")
	for y: int in rt.h:
		for x: int in rt.w:
			var c: Vector2i = Vector2i(x, y)
			var t: Dictionary = rt.terrain_at(c)
			var tid: String = str(t["id"])
			if tid == "water":
				base_layer.set_cell(c, sid("water"), Vector2i.ZERO)
				continue
			var prio: int = int(t["prio"])
			var mask: int = 0
			var under: Dictionary = {}
			for i: int in 4:
				var n: Vector2i = c + DIRS[i]
				var nt: Dictionary = rt.terrain_at(n) if rt.in_bounds(n) else t
				if int(nt["prio"]) >= prio:
					mask |= BITS[i]
				elif under.is_empty() or int(nt["prio"]) < int(under["prio"]):
					under = nt
			if mask == 15:
				base_layer.set_cell(c, sid(_sheet_name(tid)), Vector2i(_variant(c), 4))
				continue
			if under.is_empty():
				under = terr.get(str(t.get("under", tid)), t)
			if str(under["id"]) == "water":
				base_layer.set_cell(c, sid("water"), Vector2i.ZERO)
			else:
				base_layer.set_cell(c, sid(_sheet_name(str(under["id"]))), Vector2i(_variant(c), 4))
			top_layer.set_cell(c, sid(_sheet_name(tid)), Vector2i(mask % 4, mask / 4))


func _rebuild_soil() -> void:
	soil_layer.clear()
	for n: Sprite2D in _crop_nodes.values():
		n.queue_free()
	_crop_nodes.clear()
	for k: String in rt.soil():
		refresh_soil(GameState.cell_of(k), false)


func refresh_soil(c: Vector2i, neighbors: bool = true) -> void:
	var s: Dictionary = rt.soil_at(c)
	var k: String = GameState.key(c)
	if s.is_empty():
		soil_layer.erase_cell(c)
		if _crop_nodes.has(k):
			(_crop_nodes[k] as Sprite2D).queue_free()
			_crop_nodes.erase(k)
	else:
		var mask: int = 0
		for i: int in 4:
			if not rt.soil_at(c + DIRS[i]).is_empty():
				mask |= BITS[i]
		soil_layer.set_cell(c, sid("tilled_wet" if int(s.get("w", 0)) == 1 else "tilled"), Vector2i(mask % 4, mask / 4))
		_refresh_crop(c, s)
	if neighbors:
		for d: Vector2i in DIRS:
			var n: Vector2i = c + d
			if not rt.soil_at(n).is_empty():
				refresh_soil(n, false)


func _refresh_crop(c: Vector2i, s: Dictionary) -> void:
	var k: String = GameState.key(c)
	if not s.has("crop"):
		if _crop_nodes.has(k):
			(_crop_nodes[k] as Sprite2D).queue_free()
			_crop_nodes.erase(k)
		return
	var crop: Dictionary = s["crop"]
	var stage: int = Farming.stage_of(crop)
	var tex: Texture2D
	if stage < 0:
		tex = Database.sprite("crop_dead")
	else:
		var row: int = int(Farming.crop_def(str(crop["id"])).get("row", 0))
		var ck: int = row * 8 + stage
		if not _crop_tex.has(ck):
			var at: AtlasTexture = AtlasTexture.new()
			at.atlas = Database.sheet("sprites/crops")
			at.region = Rect2(stage * 16, row * 32, 16, 32)
			_crop_tex[ck] = at
		tex = _crop_tex[ck]
	var sp: Sprite2D = _crop_nodes.get(k)
	if sp == null:
		sp = Sprite2D.new()
		sp.centered = false
		sorted.add_child(sp)
		_crop_nodes[k] = sp
	sp.texture = tex
	sp.offset = Vector2(-8, -32)
	sp.position = Vector2(c.x * T + 8, (c.y + 1) * T + 1)


# --- objets et décors ----------------------------------------------------------

func rebuild_objects() -> void:
	for n: Sprite2D in _obj_nodes.values():
		n.queue_free()
	_obj_nodes.clear()
	for n2: Sprite2D in _static_nodes:
		n2.queue_free()
	_static_nodes.clear()
	for st: Dictionary in rt.data.get("statics", []):
		if not rt.static_visible(st):
			continue
		var tex: Texture2D = Database.sprite(str(st["s"]))
		if tex == null:
			continue
		var sp: Sprite2D = _place(tex, Vector2i(int(st["x"]), int(st["y"])), Vector2i(int(st["w"]), int(st["h"])))
		if bool(st.get("flat", false)) or str(st["s"]) in ["door_mat", "window_in"]:
			sp.z_index = -5
		_static_nodes.append(sp)
	for k: String in rt.objects():
		refresh_object(GameState.cell_of(k), false)


func _place(tex: Texture2D, origin: Vector2i, size: Vector2i) -> Sprite2D:
	var sp: Sprite2D = Sprite2D.new()
	sp.texture = tex
	sp.centered = false
	var sz: Vector2 = tex.get_size()
	sp.offset = Vector2(-sz.x / 2.0, -sz.y)
	sp.position = Vector2(origin.x * T + size.x * T / 2.0, (origin.y + size.y) * T)
	sorted.add_child(sp)
	return sp


func _is_fence(c: Vector2i) -> bool:
	var o: Dictionary = rt.object_at(c)
	return str(o.get("t", "")) == "placed" and str(o.get("p", "")) == "fence"


func _fence_mask(c: Vector2i) -> int:
	var m: int = 0
	for i: int in 4:
		if _is_fence(c + DIRS[i]):
			m |= BITS[i]
	return m


func _texture_for(o: Dictionary, origin: Vector2i) -> Texture2D:
	var t: String = str(o.get("t", ""))
	if t == "forage":
		return Database.icon(str(o.get("id", "")))
	if t == "placed":
		var pid: String = str(o["p"])
		var d: Dictionary = WorldObjects.def_of(o)
		if pid == "fence":
			return Database.sprite("fence_%d" % _fence_mask(origin))
		var sname: String = str(d.get("sprite", ""))
		if sname != "" and Database.sprite(sname) != null:
			return Database.sprite(sname)
		for id: String in Database.items:
			if str(Database.items[id].get("place", "")) == pid:
				return Database.icon(id)
		return null
	var nm: String = WorldObjects.sprite_name(o, season, str(rt.data.get("gem_biome", "1")))
	return Database.sprite(nm) if nm != "" else null


func refresh_object(origin: Vector2i, shake: bool = true) -> void:
	var k: String = GameState.key(origin)
	var old: Sprite2D = _obj_nodes.get(k)
	var o: Dictionary = rt.state["objects"].get(k, {})
	if o.is_empty():
		if old != null:
			old.queue_free()
			_obj_nodes.erase(k)
		return
	var tex: Texture2D = _texture_for(o, origin)
	if tex == null:
		return
	if old != null:
		old.queue_free()
	var sp: Sprite2D = _place(tex, origin, WorldObjects.size_of(o))
	if bool(WorldObjects.def_of(o).get("flat", false)):
		sp.z_index = -5
	_obj_nodes[k] = sp
	if shake and old != null:
		var tw: Tween = create_tween()
		var x0: float = sp.position.x
		tw.tween_property(sp, "position:x", x0 + SHAKE_PX, 0.035)
		tw.tween_property(sp, "position:x", x0 - SHAKE_PX, 0.05)
		tw.tween_property(sp, "position:x", x0, 0.035)


func _on_object_changed(map_id: String, origin: Vector2i) -> void:
	if map_id != rt.id:
		return
	refresh_object(origin)
	if rt.object_at(origin).is_empty() or _is_fence(origin):
		for d: Vector2i in DIRS:
			if _is_fence(origin + d):
				refresh_object(origin + d, false)


func _on_soil_changed(map_id: String, c: Vector2i) -> void:
	if map_id == rt.id:
		refresh_soil(c)
