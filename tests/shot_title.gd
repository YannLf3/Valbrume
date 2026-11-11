extends Node
## Captures du menu titre : accueil, sauvegardes, nouvelle partie.

var out_dir: String = "/tmp"


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.trim_prefix("--out=")
	var t: TitleScreen = TitleScreen.new()
	add_child(t)
	await get_tree().create_timer(0.6).timeout
	await _shot("t1_main")
	t._show_slots()
	await get_tree().create_timer(0.3).timeout
	await _shot("t2_slots")
	t._show_new_game(0)
	await get_tree().create_timer(0.3).timeout
	await _shot("t3_new")
	AudioManager.shutdown()
	get_tree().quit()


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, n])
