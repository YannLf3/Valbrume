class_name World
extends Node2D
## La partie en cours : carte, joueur, caméra, HUD, interactions, écrans, transitions, nuit.

signal quit_to_title

const SWING_TIME: float = 0.32
const REACH: int = 2
const FADE_TIME: float = 0.2
const WARP_COOLDOWN: float = 0.8
const MUSIC_NIGHT_HOUR: int = 20

var rt: MapRuntime
var view: MapView
var player: Player
var camera: Camera2D
var fx: Fx
var daylight: DayLight
var hud: Hud
var busy: bool = false

var _screen_layer: CanvasLayer
var _fade: ColorRect
var _cursor: Sprite2D
var _screens: int = 0
var _warp_cooldown: float = 0.0
var _ending: bool = false
var _mouse_target: bool = false
var _debug_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	process_priority = 10
	camera = Camera2D.new()
	camera.position_smoothing_enabled = false
	add_child(camera)
	camera.make_current()
	fx = Fx.new()
	add_child(fx)
	daylight = DayLight.new()
	add_child(daylight)
	player = Player.new()
	add_child(player)
	player.cell_changed.connect(_on_cell)
	player.tool_released.connect(_on_tool_released)
	player.action_pressed.connect(func() -> void: do_action(player.target_cell()))
	_cursor = Sprite2D.new()
	_cursor.texture = Database.sprite("tile_ok")
	_cursor.centered = false
	_cursor.z_index = 40
	add_child(_cursor)
	var hud_layer: CanvasLayer = CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)
	hud = Hud.new()
	hud_layer.add_child(hud)
	hud.hotbar_pressed.connect(select_hotbar)
	_screen_layer = CanvasLayer.new()
	_screen_layer.layer = 20
	add_child(_screen_layer)
	var fade_layer: CanvasLayer = CanvasLayer.new()
	fade_layer.layer = 15
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.1, 0.07, 0.13)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 1.0
	fade_layer.add_child(_fade)
	_debug_label = UIKit.label("", Color.WHITE)
	_debug_label.position = Vector2(6, 22)
	_debug_label.visible = false
	hud_layer.add_child(_debug_label)
	EventBus.day_ended.connect(_on_day_ended)
	EventBus.player_fainted.connect(func(_r: String) -> void: _close_all_screens())
	EventBus.night_started.connect(_update_music)
	EventBus.ui_requested.connect(_on_ui_requested)
	get_viewport().size_changed.connect(_apply_camera_limits)


func start(intro: bool) -> void:
	TimeManager.clear_locks()
	TimeManager._ending = false
	SaveManager.can_quick_save = true
	load_map(GameState.map_id, Vector2(GameState.px, GameState.py), GameState.facing)
	await _fade_to(0.0, 0.6)
	if intro:
		busy = true
		await say([Loc.t("INTRO_1"), Loc.t("INTRO_2"), Loc.t("INTRO_3"), Loc.t("INTRO_4")], Loc.t("INTRO_SPEAKER"))
		busy = false
	TimeManager.running = true
	EventBus.day_started.emit(GameState.day)
	EventBus.hotbar_changed.emit(GameState.hotbar_index)


# --- cartes --------------------------------------------------------------------

func load_map(id: String, foot: Vector2, face: int) -> void:
	if view != null:
		view.sorted.remove_child(player)
		add_child(player)
		view.queue_free()
	rt = MapRuntime.new(id)
	view = MapView.new(rt)
	add_child(view)
	move_child(view, 0)
	remove_child(player)
	view.sorted.add_child(player)
	player.rt = rt
	player.position = foot
	player.facing = face
	player._cell = player.feet_cell()
	GameState.map_id = id
	GameState.px = foot.x
	GameState.py = foot.y
	daylight.indoors = not bool(rt.data.get("outdoor", false))
	daylight.update_color()
	_apply_camera_limits()
	camera.position = player.position.round()
	camera.reset_smoothing()
	_update_music()
	EventBus.map_changed.emit(id)


func _update_music() -> void:
	var m: String = str(rt.data.get("music", ""))
	if m == "season":
		m = "night" if GameState.minutes >= MUSIC_NIGHT_HOUR * 60 else TimeManager.season_id()
	if m != "":
		AudioManager.music(m)


func _apply_camera_limits() -> void:
	if rt == null:
		return
	var vs: Vector2 = get_viewport_rect().size
	var mw: float = rt.w * MapRuntime.T
	var mh: float = rt.h * MapRuntime.T
	var l: float = 0.0
	var r: float = mw
	var t: float = 0.0
	var b: float = mh
	if mw < vs.x:
		l = -(vs.x - mw) / 2.0
		r = mw + (vs.x - mw) / 2.0
	if mh < vs.y:
		t = -(vs.y - mh) / 2.0
		b = mh + (vs.y - mh) / 2.0
	camera.limit_left = int(l)
	camera.limit_right = int(r)
	camera.limit_top = int(t)
	camera.limit_bottom = int(b)


func _fade_to(alpha: float, time: float) -> void:
	var tw: Tween = create_tween()
	tw.tween_property(_fade, "modulate:a", alpha, time)
	await tw.finished


func transition_to(target: String, foot: Vector2, face: int) -> void:
	busy = true
	await _fade_to(1.0, FADE_TIME)
	load_map(target, foot, face)
	await _fade_to(0.0, FADE_TIME)
	busy = false
	_warp_cooldown = 0.3


func _on_cell(c: Vector2i) -> void:
	if busy or _warp_cooldown > 0.0 or rt == null:
		return
	var wp: Dictionary = rt.warp_at(c)
	if wp.is_empty():
		return
	var target: String = str(wp["to"])
	if target == "farmhouse":
		target = GameState.house_map()
	if not Database.maps.has(target):
		EventBus.toast.emit(Loc.t("TOAST_PATH_CLOSED"), "")
		_warp_cooldown = WARP_COOLDOWN
		player.position -= Vector2(Player.FACING_VEC[player.facing]) * 10.0
		return
	var spot: Array = Database.map(target).get("spots", {}).get(str(wp["spot"]), [1, 1])
	AudioManager.sfx("door")
	transition_to(target, MapRuntime.foot_pixel(Vector2i(int(spot[0]), int(spot[1]))), int(wp["face"]))


# --- boucle --------------------------------------------------------------------

func _process(delta: float) -> void:
	if rt == null:
		return
	_warp_cooldown = maxf(0.0, _warp_cooldown - delta)
	player.blocked = busy or _screens > 0
	if not _ending:  # pendant la nuit, la position de réveil (le lit) ne doit pas être écrasée
		GameState.px = player.position.x
		GameState.py = player.position.y
		GameState.facing = player.facing
	camera.position = player.position.round() - Vector2(0, 8)
	_update_cursor()
	if _debug_label.visible:
		_debug_label.text = "[F4] +1h  [F5] +1 jour  [F6] +1 saison  [F7] +1000\n[F8] kit  [F9] énergie  [F10] météo\n%s  %s  jour %d" % [rt.id, str(player.feet_cell()), GameState.day]


func _update_cursor() -> void:
	var c: Vector2i = player.target_cell()
	var show: bool = not busy and _screens == 0
	if _mouse_target:
		c = MapRuntime.cell_of_pixel(get_global_mouse_position())
		var d: Vector2i = c - player.feet_cell()
		show = show and absi(d.x) <= REACH and absi(d.y) <= REACH
	_cursor.visible = show
	_cursor.position = Vector2(c * MapRuntime.T)
	_cursor.texture = Database.sprite("tile_ok" if _can_act_on(c) else "tile_bad")


func _can_act_on(c: Vector2i) -> bool:
	if not rt.in_bounds(c):
		return false
	var held: Dictionary = Database.item(GameState.held_id())
	var kind: String = str(held.get("tool", ""))
	if kind == "hoe":
		return Farming.can_till(rt, c) or not rt.object_at(c).is_empty()
	if kind == "can":
		return not rt.soil_at(c).is_empty() or rt.terrain_id(c) == "water"
	return true


# --- entrées -------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_target = true
	elif event is InputEventKey and event.pressed:
		_mouse_target = false
	if busy or _screens > 0:
		return
	if event.is_action_pressed("inventory"):
		open_container(GameState.inventory, [], "", false)
	elif event.is_action_pressed("menu"):
		_open_pause()
	elif event is InputEventMouseButton and event.pressed:
		_on_mouse(event)
	elif event.is_action_pressed("hotbar_prev"):
		select_hotbar(posmod(GameState.hotbar_index - 1, InputManager.HOTBAR_SIZE))
	elif event.is_action_pressed("hotbar_next"):
		select_hotbar(posmod(GameState.hotbar_index + 1, InputManager.HOTBAR_SIZE))
	else:
		for i: int in InputManager.HOTBAR_SIZE:
			if event.is_action_pressed("hotbar_%d" % (i + 1)):
				select_hotbar(i)
				return
		if OS.is_debug_build() and event.is_action_pressed("debug"):
			_toggle_debug()
		elif _debug_label.visible and event is InputEventKey and event.pressed:
			_debug_key((event as InputEventKey).keycode)


func _on_mouse(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			select_hotbar(posmod(GameState.hotbar_index - 1, InputManager.HOTBAR_SIZE))
		MOUSE_BUTTON_WHEEL_DOWN:
			select_hotbar(posmod(GameState.hotbar_index + 1, InputManager.HOTBAR_SIZE))
		MOUSE_BUTTON_LEFT:
			var c: Vector2i = MapRuntime.cell_of_pixel(get_global_mouse_position())
			var d: Vector2i = c - player.feet_cell()
			if absi(d.x) <= REACH and absi(d.y) <= REACH:
				if d != Vector2i.ZERO:
					player.face_cell(c)
				do_action(c)


func select_hotbar(i: int) -> void:
	GameState.hotbar_index = clampi(i, 0, InputManager.HOTBAR_SIZE - 1)
	AudioManager.sfx("ui_move", 0.0)
	EventBus.hotbar_changed.emit(GameState.hotbar_index)


func _on_tool_released(hold: float) -> void:
	if busy or _screens > 0:
		return
	_use_held(player.target_cell(), hold)


# --- interactions ----------------------------------------------------------------

func do_action(c: Vector2i) -> void:
	if busy or _screens > 0 or rt == null or player.is_swinging():
		return
	var z: Dictionary = rt.zone_at(c)
	if not z.is_empty() and await _interact_zone(z):
		return
	var o: Dictionary = rt.object_at(c)
	if not o.is_empty() and _interact_object(rt.origin_at(c), o):
		return
	if Farming.harvest(rt, c):
		return
	_use_held(c, 0.0)


func _interact_zone(z: Dictionary) -> bool:
	match str(z["kind"]):
		"bin":
			open_container(GameState.inventory, GameState.shipping, Loc.t("BIN_TITLE"), true)
			return true
		"bed":
			var choice: int = await say([Loc.t("SLEEP_ASK")], "", "", 0, [Loc.t("SLEEP_YES"), Loc.t("SLEEP_NO")])
			if choice == 0:
				TimeManager.end_day(false)
			return true
		"forecast":
			EventBus.toast.emit(Loc.f("FORECAST", [Loc.t("WEATHER_" + GameState.weather_tomorrow.to_upper())]), "")
			return true
		"mailbox":
			EventBus.toast.emit(Loc.t("MAILBOX_EMPTY"), "")
			return true
		"well":
			var lvl: int = _best_can_level()
			if lvl > 0:
				ToolUse.refill_can(lvl)
			return true
	return false


func _best_can_level() -> int:
	var best: int = 0
	for s: Variant in GameState.inventory:
		if s != null and str(Database.item(str(s["id"])).get("tool", "")) == "can":
			best = maxi(best, int(Database.item(str(s["id"])).get("level", 1)))
	return best


func _interact_object(origin: Vector2i, o: Dictionary) -> bool:
	match str(o.get("t", "")):
		"forage":
			var q: int = 1 if randf() < Skills.perk("forage_quality") else 0
			var id: String = str(o["id"])
			if not Loot.give(id, 1, q):
				return true
			if randf() < Skills.perk("double_forage"):
				Loot.give(id, 1, q)
			Skills.add_xp("foraging", Database.bal_i("xp_forage", 8))
			GameState.add_stat("forage_picked", 1, id)
			AudioManager.sfx("pickup")
			rt.remove_object(origin)
			return true
		"ftree":
			return Farming.harvest_tree(rt, origin)
		"placed":
			if o.has("slots"):
				AudioManager.sfx("chest")
				open_container(GameState.inventory, o["slots"], Loc.t("CHEST_TITLE"), false)
				return true
	return false


func _use_held(c: Vector2i, hold: float) -> bool:
	var id: String = GameState.held_id()
	if id == "" or rt == null:
		return false
	var it: Dictionary = Database.item(id)
	if it.has("tool"):
		var kind: String = str(it["tool"])
		player.swing(SWING_TIME)
		if kind != "rod" and kind != "sword":
			var charged: bool = hold >= Database.bal_f("charge_time", 0.45) and ToolUse.can_charge(id)
			ToolUse.use(rt, id, c, player.facing, charged)
		return true
	var err: String = ""
	if str(it.get("cat", "")) == "seed":
		err = Farming.plant(rt, c, id)
		if err == "":
			GameState.remove_item(id, 1)
			AudioManager.sfx("plant")
	elif str(it.get("cat", "")) == "fertilizer":
		if Farming.fertilize(rt, c, id):
			GameState.remove_item(id, 1)
			AudioManager.sfx("plant")
		else:
			err = "TOAST_NEED_SOIL"
	elif str(it.get("cat", "")) == "sapling":
		err = Farming.plant_tree(rt, c, id)
		if err == "":
			GameState.remove_item(id, 1)
			AudioManager.sfx("plant")
	elif it.has("place"):
		err = Placement.place(rt, id, c, player.facing)
	elif Consumables.is_edible(id):
		Consumables.eat(id)
	else:
		return false
	if err != "":
		AudioManager.sfx("error")
		EventBus.toast.emit(Loc.t(err), "")
		return false
	return true


# --- écrans et dialogues -----------------------------------------------------------

func open_screen(s: ScreenBase) -> void:
	_screen_layer.add_child(s)
	_screens += 1
	TimeManager.lock()
	s.tree_exited.connect(_on_screen_gone)


func _on_screen_gone() -> void:
	_screens = maxi(0, _screens - 1)
	TimeManager.unlock()


func _close_all_screens() -> void:
	for ch: Node in _screen_layer.get_children():
		ch.queue_free()


func say(lines: Array, speaker: String = "", portrait: String = "", expression: int = 0, choices: Array = []) -> int:
	var d: DialogScreen = DialogScreen.new().setup(lines, speaker, portrait, expression, choices)
	open_screen(d)
	var r: Variant = await d.closed
	return int(r) if r != null else 0


func open_container(inv: Array, other: Array, title: String, sellable: bool) -> void:
	var s: ContainerScreen = ContainerScreen.new().setup(other, title, sellable)
	open_screen(s)


func _open_pause() -> void:
	var p: PauseScreen = PauseScreen.new()
	open_screen(p)
	p.action_chosen.connect(_on_pause_action)


func _on_pause_action(action: String) -> void:
	match action:
		"save":
			if SaveManager.save_game(maxi(SaveManager.current_slot, 0)):
				EventBus.toast.emit(Loc.t("TOAST_SAVED"), "")
		"options":
			_on_ui_requested("options", {})
		"title":
			SaveManager.save_game(maxi(SaveManager.current_slot, 0))
			AudioManager.music("")
			quit_to_title.emit()


func _on_ui_requested(screen: String, _args: Dictionary) -> void:
	if screen == "options":
		open_screen(OptionsScreen.new())


# --- nuit ---------------------------------------------------------------------

func _on_day_ended(summary: Dictionary) -> void:
	if _ending:
		return
	_ending = true
	busy = true
	_close_all_screens()
	AudioManager.sfx("sleep")
	await _fade_to(1.0, 0.6)
	var s: SummaryScreen = SummaryScreen.new().setup(summary)
	open_screen(s)
	await s.closed
	await get_tree().process_frame
	load_map(GameState.map_id, Vector2(GameState.px, GameState.py), GameState.facing)
	TimeManager.begin_day()
	EventBus.weather_changed.emit(GameState.weather)
	await _fade_to(0.0, 0.6)
	busy = false
	_ending = false


# --- débogage (désactivé dans les exports release) ------------------------------

func _toggle_debug() -> void:
	var on: bool = not bool(GameState.flags.get("debug", false))
	GameState.flags["debug"] = on
	_debug_label.visible = on


func _debug_key(key: int) -> void:
	match key:
		KEY_F4:
			TimeManager.advance(60)
		KEY_F5:
			GameState.minutes = TimeManager.DAY_END - 1
			TimeManager.advance(1)
		KEY_F6:
			GameState.day = (GameState.day / TimeManager.DAYS_PER_SEASON + 1) * TimeManager.DAYS_PER_SEASON - 1
			GameState.minutes = TimeManager.DAY_END - 1
			TimeManager.advance(1)
		KEY_F7:
			GameState.add_money(1000)
		KEY_F8:
			for id: String in ["hoe_4", "can_4", "axe_4", "pick_4", "scythe_4", "sprinkler_1", "scarecrow", "chest", "fence", "compost", "seed_turnip", "seed_carrot", "seed_tomato", "seed_pumpkin", "sapling_apple"]:
				GameState.add_item(id, 10 if id.begins_with("seed") or id == "fence" else 1)
		KEY_F9:
			GameState.energy = float(GameState.max_energy)
			GameState.health = float(GameState.max_health)
			EventBus.energy_changed.emit(GameState.energy, float(GameState.max_energy))
		KEY_F10:
			var kinds: Array = Database.table("weather").get("kinds", ["sun"])
			GameState.weather = str(kinds[(kinds.find(GameState.weather) + 1) % kinds.size()])
			EventBus.weather_changed.emit(GameState.weather)
