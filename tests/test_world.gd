extends TestCase
## Test de fumée de la partie complète : monde réel, interactions, nuit, retour dans la maison.


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _frames(n: int) -> void:
	for i: int in n:
		await _tree().process_frame


func _wait(seconds: float) -> void:
	await _tree().create_timer(seconds).timeout


func test_full_day_loop() -> void:
	GameState.new_game("Test", "Ferme", 1)
	GameState.map_id = "farm"
	var foot: Vector2 = MapRuntime.foot_pixel(Vector2i(31, 14))
	GameState.px = foot.x
	GameState.py = foot.y
	var w: World = World.new()
	_tree().current_scene.add_child(w)
	w.start(false)
	await _frames(5)
	w._fade.modulate.a = 0.0
	eq(w.rt.id, "farm")
	var c: Vector2i = Vector2i(32, 16)
	GameState.hotbar_index = 0  # houe
	w.player.facing = 0
	w.player.position = MapRuntime.foot_pixel(Vector2i(32, 15))
	w.do_action(c)
	w.player._swing_left = 0.0
	ok(not w.rt.soil_at(c).is_empty(), "la houe laboure la case visée")
	GameState.hotbar_index = 5  # graines de navet
	w.do_action(c)
	w.player._swing_left = 0.0
	ok(w.rt.soil_at(c).has("crop"), "semis")
	GameState.hotbar_index = 1  # arrosoir
	GameState.can_water = 5
	w.do_action(c)
	eq(int(w.rt.soil_at(c)["w"]), 1, "arrosage")
	await _frames(3)
	w.rt.zone_at(Vector2i(32, 12))
	GameState.shipping[0] = {"id": "turnip", "n": 2, "q": 0}
	TimeManager.running = true
	TimeManager.end_day(false)
	await _wait(1.0)
	var summary: SummaryScreen = null
	for ch: Node in w._screen_layer.get_children():
		if ch is SummaryScreen:
			summary = ch
	ok(summary != null, "le bilan s'affiche")
	if summary != null:
		summary.close(null)
	await _wait(1.6)
	eq(w.rt.id, "farmhouse_1", "réveil dans la maison")
	var f: Vector2i = w.player.feet_cell()
	ok(not w.rt.is_solid(f), "le joueur se réveille sur une case libre %s" % str(f))
	eq(GameState.day, 1)
	eq(int(MapRuntime.new("farm").soil_at(c)["crop"]["age"]), 1, "la culture a poussé pendant la nuit")
	ok(TimeManager.running, "le temps repart")
	w.queue_free()
	await _frames(2)
	TimeManager.running = false
	TimeManager.clear_locks()


func test_warp_to_missing_map_is_refused() -> void:
	GameState.new_game("Test", "Ferme", 0)
	GameState.map_id = "farm"
	var foot: Vector2 = MapRuntime.foot_pixel(Vector2i(61, 13))
	GameState.px = foot.x
	GameState.py = foot.y
	var w: World = World.new()
	_tree().current_scene.add_child(w)
	w.start(false)
	await _frames(5)
	w._fade.modulate.a = 0.0
	w.player.position = MapRuntime.foot_pixel(Vector2i(63, 13))
	w._on_cell(Vector2i(63, 13))
	eq(w.rt.id, "farm", "pas de téléportation vers une carte inexistante")
	w.queue_free()
	await _frames(2)
	TimeManager.running = false
	TimeManager.clear_locks()
