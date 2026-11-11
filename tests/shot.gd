extends Node
## Outil de contrôle visuel : lance une partie, joue quelques actions et enregistre des captures.
## Usage : godot --path . res://tests/shot.tscn -- --out=/chemin/dossier

var out_dir: String = "/tmp"


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.trim_prefix("--out=")
	GameState.new_game("Camille", "Les Trois Sillons", 1)
	GameState.map_id = "farm"
	var foot: Vector2 = MapRuntime.foot_pixel(Vector2i(31, 14))
	GameState.px = foot.x
	GameState.py = foot.y
	GameState.day = 5
	var w: World = World.new()
	add_child(w)
	w.start(false)
	await get_tree().create_timer(1.0).timeout
	await _shot("01_farm")
	# labour 3x3, semis, arrosage
	var rt: MapRuntime = w.rt
	for y: int in range(16, 19):
		for x: int in range(31, 34):
			ToolUse.use(rt, "hoe_1", Vector2i(x, y), 0, false)
	for x: int in range(31, 34):
		Farming.plant(rt, Vector2i(x, 16), "seed_turnip")
		Farming.plant(rt, Vector2i(x, 17), "seed_carrot")
	GameState.can_water = 20
	for x: int in range(31, 33):
		ToolUse.use(rt, "can_1", Vector2i(x, 16), 0, false)
	GameState.add_item("ratatouille", 3)
	GameState.add_item("ore_copper", 12, 1)
	GameState.add_item("egg", 5, 2)
	w.player.position = MapRuntime.foot_pixel(Vector2i(32, 15))
	await get_tree().create_timer(0.5).timeout
	await _shot("02_field")
	w.open_container(GameState.inventory, GameState.shipping, "Coffre", true)
	await get_tree().create_timer(0.4).timeout
	await _shot("03_inventory")
	w._close_all_screens()
	await get_tree().create_timer(0.3).timeout
	w.transition_to("farmhouse_1", MapRuntime.foot_pixel(Vector2i(5, 6)), 1)
	await get_tree().create_timer(1.0).timeout
	await _shot("04_house")
	w.transition_to("farm", MapRuntime.foot_pixel(Vector2i(32, 15)), 0)
	await get_tree().create_timer(1.0).timeout
	GameState.minutes = 21 * 60 + 10
	w.daylight.update_color()
	await _shot("05_night")
	GameState.shipping[0] = {"id": "turnip", "n": 4, "q": 0}
	GameState.shipping[1] = {"id": "egg", "n": 2, "q": 2}
	GameState.minutes = 25 * 60
	TimeManager.running = true
	TimeManager.end_day(false)
	await get_tree().create_timer(1.4).timeout
	await _shot("06_summary")
	for ch: Node in w._screen_layer.get_children():
		if ch is SummaryScreen:
			(ch as SummaryScreen).close(null)
	await get_tree().create_timer(1.6).timeout
	await _shot("07_next_morning")
	print("jour=%d argent=%d carte=%s heure=%d" % [GameState.day, GameState.money, GameState.map_id, GameState.minutes])
	get_tree().quit()


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, shot_name])
