class_name AnimalManager
extends Node
## Animaux présents sur la carte courante (dans leur bâtiment) et chien de la ferme.

var rt: MapRuntime
var nav: GridNav
var entities: Array[AnimalEntity] = []


func setup(p_rt: MapRuntime, container: Node2D) -> void:
	rt = p_rt
	for e: AnimalEntity in entities:
		e.queue_free()
	entities.clear()
	nav = GridNav.new(rt)
	var home: String = _home_of(rt.id)
	if home != "":
		var pen: Array = rt.data.get("pen", [1, 3, 5, 4])
		var rect: Rect2i = Rect2i(int(pen[0]), int(pen[1]), int(pen[2]) - int(pen[0]), int(pen[3]) - int(pen[1]))
		for a: Dictionary in Animals.in_building(home):
			var e: AnimalEntity = _make(container, str(a["type"]), not Animals.is_adult(a), rect, rt.spot("door"))
			e.animal = a
	elif rt.id == "farm" and not GameState.pet.is_empty() and not GameState.pet.get("away", false):
		var pc: Vector2i = rt.spot("pet")
		_make(container, "dog", false, Rect2i(pc.x - 3, pc.y - 2, 7, 4), pc)


func _home_of(map_id: String) -> String:
	if map_id.begins_with("coop_in_"):
		return "coop"
	if map_id.begins_with("barn_in_"):
		return "barn"
	return ""


func _make(container: Node2D, kind: String, baby: bool, pen: Rect2i, start: Vector2i) -> AnimalEntity:
	var e: AnimalEntity = AnimalEntity.new()
	e.kind = kind
	e.baby = baby
	e.pen = pen
	e.nav = nav
	container.add_child(e)
	var c: Vector2i = Vector2i(WorldObjects.rng.randi_range(pen.position.x, pen.end.x), WorldObjects.rng.randi_range(pen.position.y, pen.end.y))
	e.place(c if not rt.is_solid(c) else start)
	entities.append(e)
	return e


func animal_near(c: Vector2i) -> AnimalEntity:
	var center: Vector2 = Vector2(c * MapRuntime.T) + Vector2(8, 8)
	var best: AnimalEntity = null
	var best_d: float = 18.0
	for e: AnimalEntity in entities:
		var d: float = (e.position + Vector2(0, -6)).distance_to(center)
		if d < best_d:
			best_d = d
			best = e
	return best
