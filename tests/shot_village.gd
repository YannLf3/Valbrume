extends Node
## Captures du village habité : PNJ, magasin, dialogue.

var out_dir: String = "/tmp"


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.trim_prefix("--out=")
	GameState.new_game("Camille", "Les Trois Sillons", 2)
	GameState.day = 2
	GameState.minutes = 17 * 60 + 30
	GameState.map_id = "village"
	var foot: Vector2 = MapRuntime.foot_pixel(Vector2i(36, 27))
	GameState.px = foot.x
	GameState.py = foot.y
	GameState.money = 1500
	var w: World = World.new()
	add_child(w)
	w.start(false)
	await get_tree().create_timer(1.2).timeout
	await _shot("v1_village")
	var n: Npc = w.npcs.npcs.values()[0] if not w.npcs.npcs.is_empty() else null
	print("PNJ présents : ", w.npcs.npcs.keys())
	w.open_shop("store")
	await get_tree().create_timer(0.5).timeout
	await _shot("v2_shop")
	w._close_all_screens()
	await get_tree().create_timer(0.3).timeout
	w.transition_to("inn", MapRuntime.foot_pixel(Vector2i(9, 7)), 1)
	await get_tree().create_timer(1.0).timeout
	GameState.minutes = 19 * 60
	w.npcs.setup(w.rt, w.view.sorted)
	await get_tree().create_timer(0.3).timeout
	await _shot("v3_inn")
	if w.npcs.npcs.has("gaspard"):
		w._talk(w.npcs.npcs["gaspard"])
		await get_tree().create_timer(1.6).timeout
		await _shot("v4_talk")
	AudioManager.shutdown()
	get_tree().quit()


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, n])
