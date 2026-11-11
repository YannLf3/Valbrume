extends Node
## Captures : mine (biomes), pêche, amélioration d'outils.

var out_dir: String = "/tmp"


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.trim_prefix("--out=")
	GameState.new_game("Camille", "Les Trois Sillons", 1)
	GameState.mine["elevator"] = 10
	GameState.money = 9000
	GameState.add_item("ingot_copper", 5)
	GameState.add_item("bait", 8)
	GameState.map_id = "mine_5"
	var sp: Array = Database.map("mine_5")["spots"]["entrance"]
	var foot: Vector2 = MapRuntime.foot_pixel(Vector2i(int(sp[0]), int(sp[1])))
	GameState.px = foot.x
	GameState.py = foot.y
	var w: World = World.new()
	add_child(w)
	w.start(false)
	await get_tree().create_timer(1.2).timeout
	await _shot("m1_mine5")
	w.teleport_floor(45)
	await get_tree().create_timer(1.2).timeout
	var m: MonsterEntity = w.monsters.monsters[0] if not w.monsters.monsters.is_empty() else null
	if m != null:
		w.player.position = m.position + Vector2(-26, 0)
		w.player.facing = 2
	await get_tree().create_timer(0.7).timeout
	await _shot("m2_mine45")
	w.open_screen(ElevatorScreen.new())
	await get_tree().create_timer(0.3).timeout
	await _shot("m3_elevator")
	w._close_all_screens()
	await get_tree().create_timer(0.2).timeout
	w.transition_to("lake", MapRuntime.foot_pixel(Vector2i(28, 33)), 1)
	await get_tree().create_timer(1.0).timeout
	GameState.hotbar_index = 6
	var scr: FishingScreen = FishingScreen.new().setup("pike", 1, true)
	w.open_screen(scr)
	scr.game.wait_left = 0.0
	await get_tree().create_timer(0.3).timeout
	scr.game.press()
	scr.game.angle = scr.game.arc_center - 1.0
	await get_tree().create_timer(0.1).timeout
	await _shot("m4_fishing")
	scr.close(null)
	await get_tree().create_timer(0.2).timeout
	w.open_screen(ToolUpgradeScreen.new())
	await get_tree().create_timer(0.3).timeout
	await _shot("m5_upgrade")
	AudioManager.shutdown()
	get_tree().quit()


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, n])
