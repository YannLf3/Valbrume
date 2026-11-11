extends Node
## Capture de l'interface tactile (joystick, boutons, échelle 1,5).

var out_dir: String = "/tmp"


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.trim_prefix("--out=")
	Settings.touch_mode = "on"
	Settings.ui_scale = 1.5
	GameState.new_game("Camille", "Les Trois Sillons", 2)
	GameState.map_id = "farm"
	var foot: Vector2 = MapRuntime.foot_pixel(Vector2i(31, 14))
	GameState.px = foot.x
	GameState.py = foot.y
	var w: World = World.new()
	add_child(w)
	w.start(false)
	await get_tree().create_timer(1.2).timeout
	w.touch._touch_down(5, Vector2(40, 200))
	w.touch._joy_knob.position += Vector2(14, -6)
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/t_touch.png" % out_dir)
	Settings.ui_scale = 1.0
	Settings.touch_mode = "auto"
	AudioManager.shutdown()
	get_tree().quit()
