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
var npcs: NpcManager
var animals: AnimalManager
var monsters: MonsterManager
var weather_fx: WeatherFx
var touch: TouchControls
var _hud_layer: CanvasLayer


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
	npcs = NpcManager.new()
	add_child(npcs)
	animals = AnimalManager.new()
	add_child(animals)
	monsters = MonsterManager.new()
	add_child(monsters)
	weather_fx = WeatherFx.new()
	add_child(weather_fx)
	monsters.player_died.connect(_on_player_died)
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
	_hud_layer = hud_layer
	hud = Hud.new()
	hud_layer.add_child(hud)
	touch = TouchControls.new()
	add_child(touch)
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
	EventBus.minute_passed.connect(_on_minute)
	EventBus.ui_requested.connect(_on_ui_requested)
	get_viewport().size_changed.connect(_apply_camera_limits)
	get_viewport().size_changed.connect(_layout_ui)
	EventBus.settings_changed.connect(_layout_ui)
	EventBus.screen_shake.connect(_on_shake)
	EventBus.item_gained.connect(_popup_item)
	EventBus.skill_level_up.connect(func(_s: String, _l: int) -> void:
		for i: int in 3:
			EventBus.fx_requested.emit("sparkle", player.position + Vector2(randf_range(-8, 8), -14)))
	_layout_ui()


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
	GameState.flags["festival_today"] = Festivals.today() != ""
	if (GameState.quests["board"] as Array).is_empty():
		Quests.refresh_board()
	view.rebuild_objects()
	EventBus.day_started.emit(GameState.day)
	EventBus.hotbar_changed.emit(GameState.hotbar_index)
	_check_wedding()


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
	npcs.setup(rt, view.sorted)
	animals.setup(rt, view.sorted)
	monsters.setup(rt, view.sorted, player)
	view.refresh_machines()
	var mine_floor: int = int(rt.data.get("floor", 0))
	GameState.flags["in_mine"] = mine_floor > 0
	if mine_floor > 0:
		GameState.mine["deepest"] = maxi(int(GameState.mine.get("deepest", 0)), mine_floor)
		if MineGen.is_elevator_floor(mine_floor):
			GameState.mine["elevator"] = maxi(int(GameState.mine.get("elevator", 0)), mine_floor)
	daylight.dark = bool(rt.data.get("dark", false))
	weather_fx.configure(GameState.weather, TimeManager.season_id(), bool(rt.data.get("outdoor", false)))
	view.set_night(_is_night())
	player.position = foot
	player.facing = face
	player._cell = player.feet_cell()
	GameState.map_id = id
	GameState.px = foot.x
	GameState.py = foot.y
	daylight.indoors = not bool(rt.data.get("outdoor", false)) and not bool(rt.data.get("dark", false))
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


## Échelle de l'interface et zones sûres : le HUD occupe la zone utile, agrandie selon l'option.
func _layout_ui() -> void:
	if _hud_layer == null or hud == null:
		return
	var vs: Vector2 = get_viewport().get_visible_rect().size
	var k: float = clampf(Settings.ui_scale, 1.0, 2.0)
	var inset: Rect2 = TouchControls.safe_inset(vs)
	_hud_layer.scale = Vector2(k, k)
	hud.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hud.position = inset.position
	hud.size = (vs - inset.position - inset.size) / k


func _on_shake(strength: float) -> void:
	if not Settings.screen_shake or camera == null:
		return
	var tw: Tween = create_tween()
	for i: int in 5:
		tw.tween_property(camera, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * (1.0 - i / 5.0), 0.04)
	tw.tween_property(camera, "offset", Vector2.ZERO, 0.04)


func _popup_item(id: String, _n: int, _q: int) -> void:
	var icon: Texture2D = Database.icon(id)
	if icon == null or player == null:
		return
	var sp: Sprite2D = Sprite2D.new()
	sp.texture = icon
	sp.position = player.position + Vector2(randf_range(-6, 6), -26)
	sp.z_index = 60
	add_child(sp)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(sp, "position:y", sp.position.y - 14.0, 0.7)
	tw.tween_property(sp, "modulate:a", 0.0, 0.7).set_delay(0.3)
	tw.chain().tween_callback(sp.queue_free)


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


func _is_night() -> bool:
	return GameState.minutes >= 18 * 60 + 30 or GameState.minutes < 6 * 60 + 30 or bool(rt.data.get("dark", false))


func _on_minute(m: int) -> void:
	npcs.on_minute()
	if view != null:
		view.set_night(_is_night())
		if m % 10 == 0:
			view.refresh_machines()


func _on_cell(c: Vector2i) -> void:
	if busy or _warp_cooldown > 0.0 or rt == null:
		return
	var lo: Dictionary = rt.object_at(c)
	if not lo.is_empty() and str(lo.get("t", "")) in ["ladder_down", "ladder_up"] and int(rt.data.get("floor", 0)) > 0:
		_change_floor(1 if str(lo["t"]) == "ladder_down" else -1)
		return
	var wp: Dictionary = rt.warp_at(c)
	if wp.is_empty():
		return
	var target: String = str(wp["to"])
	if target == "farmhouse":
		target = GameState.house_map()
	var refusal: String = ""
	if wp.has("need_flag") and not GameState.flag(str(wp["need_flag"])):
		refusal = Loc.t(str(wp.get("msg", "TOAST_PATH_CLOSED")))
	elif wp.has("shop") and not Shops.is_open(str(wp["shop"])):
		var sh: Dictionary = Shops.shop(str(wp["shop"]))
		refusal = Loc.f("TOAST_SHOP_CLOSED", [int(sh.get("open", 0)), int(sh.get("close", 24))])
	elif not Database.has_map(target):
		refusal = Loc.t("TOAST_PATH_CLOSED")
	if refusal != "":
		AudioManager.sfx("error")
		EventBus.toast.emit(refusal, "")
		_warp_cooldown = WARP_COOLDOWN
		player.position -= Vector2(Player.FACING_VEC[player.facing]) * 10.0
		return
	var spot: Array = Database.map(target).get("spots", {}).get(str(wp["spot"]), [1, 1])
	if target.begins_with("mine_"):
		AudioManager.sfx("ladder")
	AudioManager.sfx("door")
	transition_to(target, MapRuntime.foot_pixel(Vector2i(int(spot[0]), int(spot[1]))), int(wp["face"]))


# --- mine ----------------------------------------------------------------------

func _change_floor(delta: int) -> void:
	var f: int = int(rt.data.get("floor", 0)) + delta
	AudioManager.sfx("ladder")
	_warp_cooldown = 0.6
	if f < 1:
		var lake: Array = Database.map("lake")["spots"]["mine_door"]
		transition_to("lake", MapRuntime.foot_pixel(Vector2i(int(lake[0]), int(lake[1]))), 0)
		return
	var spot_name: String = "entrance" if delta > 0 else "exit"
	var sp: Array = Database.map(MineGen.map_id(f))["spots"][spot_name]
	transition_to(MineGen.map_id(f), MapRuntime.foot_pixel(Vector2i(int(sp[0]), int(sp[1]))), 0)


func teleport_floor(f: int) -> void:
	if f <= 0:
		var lake: Array = Database.map("lake")["spots"]["mine_door"]
		transition_to("lake", MapRuntime.foot_pixel(Vector2i(int(lake[0]), int(lake[1]))), 0)
		return
	var sp: Array = Database.map(MineGen.map_id(f))["spots"]["entrance"]
	transition_to(MineGen.map_id(f), MapRuntime.foot_pixel(Vector2i(int(sp[0]), int(sp[1]))), 0)


func _open_elevator() -> void:
	var scr: ElevatorScreen = ElevatorScreen.new()
	open_screen(scr)
	var res: Variant = await scr.closed
	if res != null:
		await get_tree().process_frame
		teleport_floor(int(res))


func _on_player_died() -> void:
	if _ending:
		return
	_close_all_screens()
	GameState.flags["died"] = true
	TimeManager.end_day(false)


func _open_treasure(origin: Vector2i, o: Dictionary) -> void:
	if bool(o.get("opened", false)):
		return
	o["opened"] = true
	var f: int = int(o.get("floor", 0))
	GameState.mine["chests"] = GameState.mine.get("chests", {})
	GameState.mine["chests"][str(f)] = true
	AudioManager.sfx("chest")
	var names: PackedStringArray = []
	for e: Array in Database.table("mine")["treasures"].get(str(f), []):
		Loot.give(str(e[0]), int(e[1]))
		names.append("%s x%d" % [Database.item_name(str(e[0])), int(e[1])])
	var money: int = int(Database.table("mine")["treasure_money"].get(str(f), 0))
	if money > 0:
		GameState.add_money(money)
	EventBus.toast.emit(Loc.f("MINE_TREASURE", [", ".join(names)]), "")
	rt.touch_object(origin)


# --- pêche ---------------------------------------------------------------------

func _fish(c: Vector2i, level: int) -> void:
	if rt.terrain_id(c) != "water":
		EventBus.toast.emit(Loc.t("FISH_NEED_WATER"), "")
		return
	var cost: float = Database.bal_f("energy_rod", 4.0)
	if GameState.energy < cost:
		AudioManager.sfx("error")
		EventBus.toast.emit(Loc.t("TOAST_NO_ENERGY"), "")
		return
	GameState.change_energy(-cost)
	var place: String = Fishing.place_for(rt)
	var fish: String = Fishing.pick(place if place != "" else "river", level)
	var bait: bool = Fishing.use_bait()
	AudioManager.sfx("cast")
	var scr: FishingScreen = FishingScreen.new().setup(fish, level, bait)
	open_screen(scr)
	var res: Dictionary = await scr.closed
	if bool(res.get("caught", false)):
		Fishing.land(str(res["fish"]), int(res["q"]))
		if bool(res.get("treasure", false)):
			Fishing.treasure()


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
		_debug_label.text = "[F4] +1h  [F5] +1 jour  [F6] +1 saison  [F7] +1000\n[F8] kit  [F9] énergie  [F10] météo\n%s  %s  jour %d" % [rt.id, str(player.feet_cell()), GameState.day]  # i18n:ignore


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
	elif event.is_action_pressed("journal"):
		open_screen(JournalScreen.new())
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
			if touch != null and touch.covers(event.position):
				return
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
	var n: Npc = npcs.npc_near(c)
	if n != null:
		_talk_or_gift(n)
		return
	var an: AnimalEntity = animals.animal_near(c)
	if an != null:
		_pet(an)
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
			EventBus.toast.emit(Loc.f(str(z.get("text", "FORECAST")), [Loc.t("WEATHER_" + GameState.weather_tomorrow.to_upper())]), "")
			return true
		"shop":
			open_shop(str(z["arg"]))
			return true
		"mailbox":
			EventBus.toast.emit(Loc.t("MAILBOX_EMPTY"), "")
			return true
		"elevator":
			_open_elevator()
			return true
		"bell":
			var bid: String = str(z["arg"])
			AudioManager.sfx("bell" if Story.is_cast(bid) else "error", 0.1)
			EventBus.toast.emit(Loc.t("BELL_RING") if Story.is_cast(bid) else Loc.t("BELL_DARK"), "")
			return true
		"festival":
			_enter_festival()
			return true
		"quest_board":
			open_screen(QuestBoardScreen.new())
			return true
		"museum":
			open_screen(MuseumScreen.new().setup(str(z["arg"])))
			return true
		"heal_bed":
			GameState.change_health(float(GameState.max_health))
			AudioManager.sfx("heart")
			EventBus.toast.emit(Loc.t("HEAL_OK"), "")
			return true
		"kitchen":
			if Buildings.level("house") >= 2:
				open_screen(CraftingScreen.new().setup("cook"))
			else:
				EventBus.toast.emit(Loc.t("KITCHEN_LOCKED"), "")
			return true
		"collect":
			var got: int = Animals.collect(str(z["arg"]))
			if got == 0:
				EventBus.toast.emit(Loc.t("COLLECT_NOTHING"), "")
			return true
		"silo":
			var put: int = Animals.store_hay(GameState.item_count("hay")) if GameState.held_id() == "hay" else 0
			EventBus.toast.emit(Loc.f("SILO_STATUS", [Animals.hay_stored(), Database.bal_i("silo_capacity", 240)]), "hay")
			if put > 0:
				AudioManager.sfx("plant")
			return true
		"well":
			var lvl: int = _best_can_level()
			if lvl > 0:
				ToolUse.refill_can(lvl)
			return true
	return false


func open_shop(shop_id: String) -> void:
	if not Shops.is_open(shop_id):
		var sh: Dictionary = Shops.shop(shop_id)
		EventBus.toast.emit(Loc.f("TOAST_SHOP_CLOSED", [int(sh.get("open", 0)), int(sh.get("close", 24))]), "")
		return
	var scr: ShopScreen = ShopScreen.new().setup(shop_id)
	scr.talk_requested.connect(_talk_by_id)
	scr.service_requested.connect(_on_service)
	open_screen(scr)


func _on_service(service: String) -> void:
	await get_tree().process_frame
	match service:
		"build":
			open_screen(BuildScreen.new())
		"animals":
			open_screen(AnimalShopScreen.new())
		"tool_upgrade":
			open_screen(ToolUpgradeScreen.new())
		"bell_cast":
			var bs: BellScreen = BellScreen.new()
			bs.bell_cast.connect(_on_bell_cast)
			open_screen(bs)


func _pet(a: AnimalEntity) -> void:
	var nm: String = ""
	var ok_: bool = false
	if a.kind == "dog":
		nm = str(GameState.pet.get("name", ""))
		if not bool(GameState.pet.get("petted", false)):
			GameState.pet["petted"] = true
			GameState.pet["affection"] = mini(int(GameState.pet.get("affection", 0)) + int(Database.bal_f("affection_pet", 15.0)), Database.bal_i("affection_max", 1000))
			Skills.add_xp("husbandry", Database.bal_i("xp_pet", 5))
			ok_ = true
		AudioManager.sfx("bark")
	else:
		nm = str(a.animal["name"])
		ok_ = Animals.pet(a.animal)
		AudioManager.sfx(str(Animals.table()[str(a.animal["type"])].get("sfx", "pickup")))
	if ok_:
		EventBus.fx_requested.emit("heart", a.position + Vector2(0, -18))
		EventBus.toast.emit(Loc.f("PET_OK", [nm]), "")
	else:
		EventBus.toast.emit(Loc.f("PET_ALREADY", [nm]), "")


func _talk_by_id(npc_id: String) -> void:
	await get_tree().process_frame
	if npcs.npcs.has(npc_id):
		_talk_or_gift(npcs.npcs[npc_id])


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
		"treasure":
			_open_treasure(origin, o)
			return true
		"placed":
			if o.has("slots"):
				AudioManager.sfx("chest")
				open_container(GameState.inventory, o["slots"], Loc.t("CHEST_TITLE"), false)
				return true
			var pdef: Dictionary = WorldObjects.def_of(o)
			if str(pdef.get("kind", "")) == "crab_pot":
				if not Fishing.collect_pot(o):
					EventBus.toast.emit(Loc.t("POT_EMPTY"), "")
				rt.touch_object(origin)
				return true
			if str(pdef.get("kind", "")) == "machine":
				var res: String = Machines.interact(o, GameState.held_id(), GameState.hotbar_index)
				if res == "MACHINE_BUSY":
					EventBus.toast.emit(Loc.f("MACHINE_BUSY", [Machines.minutes_left(o["m"])]), "")
				elif res != "":
					AudioManager.sfx("error")
					EventBus.toast.emit(Loc.t(res), "")
				rt.touch_object(origin)
				return true
			if str(pdef.get("kind", "")) == "furniture" and not Placement.is_placeable(GameState.held_id()):
				o["rot"] = (int(o.get("rot", 0)) + 1) % 4
				AudioManager.sfx("ui_click")
				rt.touch_object(origin)
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
		if kind == "sword":
			if GameState.energy > 0.0:
				GameState.change_energy(-Database.bal_f("energy_sword", 0.5))
			monsters.attack(int(it.get("level", 1)))
		elif kind == "rod":
			_fish(c, int(it.get("level", 1)))
		else:
			var charged: bool = hold >= Database.bal_f("charge_time", 0.45) and ToolUse.can_charge(id)
			ToolUse.use(rt, id, c, player.facing, charged)
		return true
	var err: String = ""
	if id == "ledger_page":
		_read_page()
		return true
	if it.has("wallpaper") or it.has("floor"):
		if rt.data.get("interior", "") != "house":
			err = "TOAST_INDOORS_ONLY"
		else:
			if it.has("wallpaper"):
				GameState.house["wallpaper"] = int(it["wallpaper"])
			else:
				GameState.house["floor"] = int(it["floor"])
			GameState.remove_item(id, 1)
			AudioManager.sfx("plant")
			view.rebuild_all()
	elif str(it.get("cat", "")) == "seed":
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
	elif screen == "craft":
		open_screen(CraftingScreen.new().setup("craft"))


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
	view.rebuild_objects()
	npcs.setup(rt, view.sorted)
	await _fade_to(0.0, 0.6)
	busy = false
	_ending = false
	_check_wedding()
	if Festivals.today() != "":
		EventBus.toast.emit(Loc.t("FEST_" + Festivals.today().to_upper()), "")


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


# --- conversations, cadeaux, événements ------------------------------------------

func _talk_or_gift(n: Npc) -> void:
	var held: String = GameState.held_id()
	if held != "" and Friendship.is_giftable(held):
		await _gift(n, held)
	else:
		await _talk(n)


func _speak(n: Npc, text: String, expression: int = 0, choices: Array = []) -> int:
	return await say([text], Loc.t("NPC_" + n.npc_id.to_upper()), n.npc_id, expression, choices)


func _talk(n: Npc) -> void:
	n.talking = true
	n.face_toward(player.position)
	var ev: String = Dialogue.pending_event(n.npc_id)
	if ev != "":
		await _play_event(n, ev)
	else:
		var first: bool = Friendship.talk(n.npc_id)
		var happy: bool = Friendship.is_birthday(n.npc_id) or Friendship.hearts(n.npc_id) >= 5
		await _speak(n, Loc.t(Dialogue.pick_talk(n.npc_id)), 1 if happy else 0)
		if first:
			EventBus.fx_requested.emit("heart", n.position + Vector2(0, -26))
			AudioManager.sfx("heart")
	n.talking = false


func _gift(n: Npc, item_id: String) -> void:
	n.talking = true
	n.face_toward(player.position)
	var npc_name: String = Loc.t("NPC_" + n.npc_id.to_upper())
	var block: String = Friendship.gift_block(n.npc_id)
	if block != "":
		EventBus.toast.emit(Loc.f(block, [npc_name]), "")
		n.talking = false
		return
	var ask: int = await say([Loc.f("GIFT_ASK", [Database.item_name(item_id), npc_name])], "", "", 0, [Loc.t("COMMON_YES"), Loc.t("COMMON_NO")])
	if ask != 0:
		n.talking = false
		return
	var res: Dictionary = Friendship.give_gift(n.npc_id, item_id)
	var taste: String = str(res["taste"])
	match str(res["special"]):
		"dating":
			AudioManager.sfx("heart")
			await _speak(n, Loc.t("GIFT_DATING"), 1)
		"refused":
			await _speak(n, Loc.t("GIFT_REFUSED"), 2)
		"engaged":
			AudioManager.sfx("heart")
			await _speak(n, Loc.t("GIFT_ENGAGED"), 1)
		_:
			var good: bool = taste == "love" or taste == "like"
			AudioManager.sfx("gift")
			await _speak(n, Loc.t(Dialogue.gift_reaction(n.npc_id, taste)), 1 if good else (2 if taste != "neutral" else 0))
			if taste == "love":
				EventBus.fx_requested.emit("heart", n.position + Vector2(0, -26))
	n.talking = false


func _play_event(n: Npc, event_id: String) -> void:
	var e: Dictionary = Database.table("events")[event_id]
	var lines: Array = []
	for k: String in e["lines"]:
		lines.append(Loc.t(k))
	var labels: Array = []
	for o: Dictionary in e["options"]:
		labels.append(Loc.t(str(o["label"])))
	var choice: int = await say(lines, Loc.t("NPC_" + n.npc_id.to_upper()), n.npc_id, 0, labels)
	var opt: Dictionary = e["options"][clampi(choice, 0, labels.size() - 1)]
	Friendship.rel(n.npc_id)["events"][event_id] = true
	Friendship.rel(n.npc_id)["talked"] = GameState.day
	var pts: int = int(opt["points"])
	Friendship.add_points(n.npc_id, pts)
	await _speak(n, Loc.t(str(opt["reply"])), 1 if pts > 15 else 0)
	var reward: Dictionary = e["reward"]
	if Loot.give(str(reward["item"]), int(reward["n"])):
		AudioManager.sfx("gift")
	if pts > 0:
		EventBus.fx_requested.emit("heart", n.position + Vector2(0, -26))


# --- fil rouge, festivals, mariage -------------------------------------------------

func _read_page() -> void:
	var key: String = Story.read_next_page()
	if key == "":
		EventBus.toast.emit(Loc.t("LORE_NONE"), "")
		return
	await say([Loc.t(key)], Loc.t("INTRO_SPEAKER"))


func _on_bell_cast(id: String) -> void:
	if id == "furrows" and view != null:
		view.rebuild_objects()
	if id == "great":
		await get_tree().create_timer(0.4).timeout
		_close_all_screens()
		await get_tree().process_frame
		_play_ending()


func _play_ending() -> void:
	busy = true
	for i: int in 4:
		AudioManager.sfx("bell_big", 0.0)
		await get_tree().create_timer(0.9).timeout
	await say([Loc.t("ENDING_1"), Loc.t("ENDING_2"), Loc.t("ENDING_3"), Loc.t("ENDING_4")], Loc.t("INTRO_SPEAKER"))
	await say([Loc.t("CREDITS_TEXT")])
	busy = false


func _enter_festival() -> void:
	var id: String = Festivals.today()
	if id == "" or not Festivals.window_open():
		EventBus.toast.emit(Loc.t("FEST_NOT_NOW"), "")
		return
	if Festivals.is_done(id):
		EventBus.toast.emit(Loc.t("FEST_DONE"), "")
		return
	await say([Loc.t("FESTI_" + id.to_upper())], Loc.t("FEST_" + id.to_upper()))
	var scr: FestivalScreen = FestivalScreen.new().setup(str(Festivals.table()[id]["game"]))
	open_screen(scr)
	var score: Variant = await scr.closed
	var r: Dictionary = Festivals.conclude(id, int(score))
	var lines: Array = [Loc.t("FEST_RESULT_%d" % int(r["tier"]))]
	if str(r["item"]) != "":
		lines.append(Loc.f("FEST_PRIZE", [int(r["money"]), Database.item_name(str(r["item"])), int(r["n"])]))
	else:
		lines.append(Loc.f("FEST_MONEY", [int(r["money"])]))
	await say(lines, Loc.t("FEST_" + id.to_upper()))


func _check_wedding() -> void:
	if int(GameState.flags.get("wedding_day", -1)) != GameState.day or str(GameState.flags.get("engaged_to", "")) == "":
		return
	var npc: String = str(GameState.flags["engaged_to"])
	busy = true
	AudioManager.sfx("fanfare")
	await say([Loc.t("WEDDING_1"), Loc.t("WEDDING_2"), Loc.t("WEDDING_3")], Loc.t("NPC_" + npc.to_upper()), npc, 1)
	GameState.spouse = npc
	Friendship.rel(npc)["married"] = true
	GameState.flags.erase("wedding_day")
	GameState.flags.erase("engaged_to")
	AudioManager.sfx("bell_big")
	EventBus.toast.emit(Loc.f("WEDDING_DONE", [Loc.t("NPC_" + npc.to_upper())]), "")
	busy = false
