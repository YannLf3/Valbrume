extends Node
## Captures de la ferme aménagée : bâtiments, machines, intérieur du poulailler, artisanat.

var out_dir: String = "/tmp"


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.trim_prefix("--out=")
	GameState.new_game("Camille", "Les Trois Sillons", 0)
	GameState.day = 30
	GameState.minutes = 11 * 60
	GameState.house["level"] = 3
	for t: String in ["coop", "barn", "silo"]:
		GameState.buildings[t] = {"level": 2 if t != "silo" else 1, "out": [], "hay": 30}
	for i: int in 4:
		GameState.animals.append({"id": i, "type": "chicken", "name": "Poule %d" % i, "home": "coop", "age": 9, "affection": 300, "fed": true, "petted": false})
	GameState.animals.append({"id": 9, "type": "cow", "name": "Marguerite", "home": "barn", "age": 9, "affection": 500, "fed": true, "petted": false})
	GameState.animals.append({"id": 10, "type": "goat", "name": "Noisette", "home": "barn", "age": 9, "affection": 200, "fed": true, "petted": false})
	GameState.animals.append({"id": 11, "type": "sheep", "name": "Nuage", "home": "barn", "age": 1, "affection": 0, "fed": true, "petted": false})
	GameState.map_id = "farm"
	var foot: Vector2 = MapRuntime.foot_pixel(Vector2i(40, 12))
	GameState.px = foot.x
	GameState.py = foot.y
	var w: World = World.new()
	add_child(w)
	w.start(false)
	await get_tree().create_timer(1.0).timeout
	var rt: MapRuntime = w.rt
	for i: int in 5:
		var item: String = ["furnace", "cheese_press", "preserve_jar", "beehive", "scarecrow"][i]
		GameState.add_item(item, 1)
		Placement.place(rt, item, Vector2i(34 + i, 13 + 0), 0)
	var press: Dictionary = rt.object_at(Vector2i(35, 13))
	press["m"]["out"] = {"id": "cheese", "n": 1, "q": 1}
	press["m"]["done_at"] = 0
	w.view.refresh_machines()
	await get_tree().create_timer(0.4).timeout
	await _shot("f1_farm")
	w.load_map("barn_in_2", MapRuntime.foot_pixel(Vector2i(7, 7)), 1)
	await get_tree().create_timer(2.5).timeout
	await _shot("f2_barn")
	w.load_map("farmhouse_3", MapRuntime.foot_pixel(Vector2i(8, 8)), 1)
	await get_tree().create_timer(0.5).timeout
	w.open_screen(CraftingScreen.new().setup("cook"))
	GameState.add_item("egg", 4)
	GameState.add_item("flour", 4)
	GameState.add_item("milk", 2)
	GameState.add_item("tuna", 1)
	await get_tree().create_timer(0.5).timeout
	await _shot("f3_cook")
	AudioManager.shutdown()
	get_tree().quit()


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, n])
