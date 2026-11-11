class_name NpcManager
extends Node2D
## Présence des PNJ sur la carte courante : apparition, marche vers leur prochain point, sortie par les portes.

const ARRIVAL_WINDOW: int = 20   # minutes pendant lesquelles un PNJ « vient d'arriver » à pied

var rt: MapRuntime
var nav: GridNav
var parent_node: Node2D
var npcs: Dictionary = {}
var _targets: Dictionary = {}


func setup(p_rt: MapRuntime, container: Node2D) -> void:
	rt = p_rt
	parent_node = container
	for n: Npc in npcs.values():
		n.queue_free()
	npcs.clear()
	_targets.clear()
	nav = GridNav.new(rt)
	for id: String in Friendship.ids():
		var e: Dictionary = Schedule.entry_at(id, GameState.minutes)
		if str(e["map"]) != rt.id:
			continue
		var spot: Vector2i = Schedule.spot_cell(rt.id, str(e["spot"]))
		var prev: String = Schedule.previous_map(id, int(e["index"]))
		if prev != rt.id and GameState.minutes - int(e["t"]) < ARRIVAL_WINDOW:
			_spawn_arriving(id, prev, spot)
		else:
			_spawn(id, spot)
		_targets[id] = str(e["spot"])
	if not EventBus.object_changed.is_connected(_on_object_changed):
		EventBus.object_changed.connect(_on_object_changed)


func _on_object_changed(map_id: String, _c: Vector2i) -> void:
	if rt != null and map_id == rt.id and nav != null:
		nav.mark_dirty()


func _spawn(id: String, c: Vector2i) -> Npc:
	var n: Npc = Npc.new()
	n.npc_id = id
	parent_node.add_child(n)
	n.place(c)
	npcs[id] = n
	return n


func _spawn_arriving(id: String, from_map: String, spot: Vector2i) -> void:
	var route: Array[String] = Schedule.route(rt.id, from_map)
	var door: Vector2i = spot
	if route.size() >= 2:
		var d: Vector2i = Schedule.warp_cell_toward(rt.id, route[1])
		if d.x >= 0:
			door = d
	var n: Npc = _spawn(id, door)
	n.walk(nav.path(door, spot))


## Appelé à chaque minute de jeu : fait avancer les programmes.
func on_minute() -> void:
	if rt == null:
		return
	for id: String in Friendship.ids():
		var e: Dictionary = Schedule.entry_at(id, GameState.minutes)
		var present: bool = npcs.has(id)
		var here: bool = str(e["map"]) == rt.id
		var spot_name: String = str(e["spot"])
		if here and not present and GameState.minutes == int(e["t"]):
			var prev: String = Schedule.previous_map(id, int(e["index"]))
			_spawn_arriving(id, prev, Schedule.spot_cell(rt.id, spot_name)) if prev != rt.id else _spawn(id, Schedule.spot_cell(rt.id, spot_name))
			_targets[id] = spot_name
		elif here and present and str(_targets.get(id, "")) != spot_name:
			_targets[id] = spot_name
			var n: Npc = npcs[id]
			n.leaving = false
			n.walk(nav.path(n.cell(), Schedule.spot_cell(rt.id, spot_name)))
		elif not here and present and not (npcs[id] as Npc).leaving:
			_send_away(id, str(e["map"]))


func _send_away(id: String, dest_map: String) -> void:
	var n: Npc = npcs[id]
	var route: Array[String] = Schedule.route(rt.id, dest_map)
	var door: Vector2i = Vector2i(-1, -1)
	if route.size() >= 2:
		door = Schedule.warp_cell_toward(rt.id, route[1])
	n.leaving = true
	if door.x < 0:
		_remove(id)
		return
	var p: Array[Vector2i] = nav.path(n.cell(), door)
	if p.is_empty():
		_remove(id)
		return
	n.walk(p)
	n.arrived.connect(_remove.bind(id), CONNECT_ONE_SHOT)


func _remove(id: String) -> void:
	if npcs.has(id):
		(npcs[id] as Npc).queue_free()
		npcs.erase(id)
		_targets.erase(id)


## PNJ le plus proche d'une case (rayon 1,6 case), ou null.
func npc_near(c: Vector2i) -> Npc:
	var center: Vector2 = Vector2(c * MapRuntime.T) + Vector2(8, 8)
	var best: Npc = null
	var best_d: float = 26.0
	for n: Npc in npcs.values():
		var d: float = (n.position + Vector2(0, -8)).distance_to(center)
		if d < best_d:
			best_d = d
			best = n
	return best
