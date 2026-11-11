extends Node
## Mesure de coût logique par image (sans rendu) sur la ferme chargée et le village peuplé.
##   godot --headless res://tests/perf.tscn

func _ready() -> void:
	Engine.max_fps = 0
	GameState.new_game("Perf", "Ferme", 0)
	GameState.map_id = "farm"
	var foot: Vector2 = MapRuntime.foot_pixel(Vector2i(31, 14))
	GameState.px = foot.x
	GameState.py = foot.y
	var w: World = World.new()
	add_child(w)
	w.start(false)
	await get_tree().create_timer(0.5).timeout
	var rt: MapRuntime = w.rt
	for y: int in range(15, 40):
		for x: int in range(30, 50):
			GameState.energy = 100.0
			ToolUse.use(rt, "hoe_1", Vector2i(x, y), 0, false)
			Farming.plant(rt, Vector2i(x, y), "seed_turnip")
	GameState.energy = 100.0
	await get_tree().create_timer(0.3).timeout
	print("ferme : %d parcelles plantées, %d objets" % [rt.soil().size(), rt.objects().size()])
	_cpu("ferme", w, 300)
	await _measure("ferme", 120)
	w.transition_to("village", MapRuntime.foot_pixel(Vector2i(36, 28)), 0)
	await get_tree().create_timer(1.0).timeout
	GameState.minutes = 11 * 60
	w.npcs.setup(w.rt, w.view.sorted)
	print("village : %d habitants à l'écran" % w.npcs.npcs.size())
	_cpu("village", w, 300)
	await _measure("village", 120)
	AudioManager.shutdown()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()


func _cpu(label: String, w: World, frames: int) -> void:
	var t0: int = Time.get_ticks_usec()
	for i: int in frames:
		w._process(0.016)
		w.player._process(0.016)
		w.npcs.on_minute()
		w.view.refresh_machines()
	print("%s : %.3f ms de logique de jeu par image (monde + joueur + PNJ)" % [label, float(Time.get_ticks_usec() - t0) / 1000.0 / frames])


func _measure(label: String, frames: int) -> void:
	var t0: int = Time.get_ticks_usec()
	for i: int in frames:
		await get_tree().process_frame
	var ms: float = float(Time.get_ticks_usec() - t0) / 1000.0 / frames
	print("%s : %.2f ms/image (logique + rendu headless)" % [label, ms])
