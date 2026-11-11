extends Node
## Captures du monde vivant : village la nuit sous la pluie, festival, journal, fonderie, beffroi.

var out_dir: String = "/tmp"


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.trim_prefix("--out=")
	GameState.new_game("Camille", "Les Trois Sillons", 1)
	GameState.day = 13   # fête des semis
	GameState.minutes = 20 * 60 + 40
	GameState.weather = "rain"
	GameState.money = 20000
	GameState.flags["bell_furrows"] = true
	GameState.flags["bell_waves"] = true
	GameState.map_id = "village"
	var foot: Vector2 = MapRuntime.foot_pixel(Vector2i(36, 28))
	GameState.px = foot.x
	GameState.py = foot.y
	var w: World = World.new()
	add_child(w)
	w.start(false)
	await get_tree().create_timer(1.5).timeout
	await _shot("s1_night_rain")
	GameState.minutes = 11 * 60
	GameState.weather = "sun"
	w.daylight.update_color()
	w.weather_fx.configure("sun", "spring", true)
	w.view.set_night(false)
	w.view.rebuild_objects()
	w.npcs.setup(w.rt, w.view.sorted)
	await get_tree().create_timer(1.0).timeout
	await _shot("s2_festival")
	w.open_screen(BellScreen.new())
	await get_tree().create_timer(0.3).timeout
	await _shot("s3_bells")
	w._close_all_screens()
	await get_tree().create_timer(0.2).timeout
	w.open_screen(JournalScreen.new())
	await get_tree().create_timer(0.3).timeout
	await _shot("s4_journal")
	w._close_all_screens()
	await get_tree().create_timer(0.2).timeout
	w.transition_to("belfry", MapRuntime.foot_pixel(Vector2i(6, 8)), 1)
	await get_tree().create_timer(1.0).timeout
	await _shot("s5_belfry")
	w.open_screen(FestivalScreen.new().setup("timing"))
	await get_tree().create_timer(0.4).timeout
	await _shot("s6_festival_game")
	AudioManager.shutdown()
	get_tree().quit()


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, n])
