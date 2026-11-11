class_name Hud
extends Control
## Interface de jeu : horloge, date, météo, argent, énergie, santé, barre d'objets rapide, messages.

signal hotbar_pressed(index: int)

const TOAST_TIME: float = 2.6
const MAX_TOASTS: int = 4
const MARGIN: int = 4

var _date: Label
var _time: Label
var _money: Label
var _season_icon: TextureRect
var _weather_icon: TextureRect
var _energy: Control
var _health: Control
var _hotbar: SlotGrid
var _water: Label
var _toasts: VBoxContainer
var _banner: Label
var _fps: Label
var _bars_need_redraw: bool = true


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UIKit.theme()


func _ready() -> void:
	_build_clock()
	_build_bars()
	_build_hotbar()
	_build_toasts()
	EventBus.money_changed.connect(func(_m: int) -> void: refresh())
	EventBus.energy_changed.connect(func(_a: float, _b: float) -> void: _energy.queue_redraw())
	EventBus.health_changed.connect(func(_a: float, _b: float) -> void: _health.queue_redraw())
	EventBus.minute_passed.connect(func(_m: int) -> void: refresh())
	EventBus.day_started.connect(func(_d: int) -> void: refresh())
	EventBus.weather_changed.connect(func(_w: String) -> void: refresh())
	EventBus.hotbar_changed.connect(func(_i: int) -> void: _on_hotbar())
	EventBus.inventory_changed.connect(_on_hotbar)
	EventBus.language_changed.connect(refresh)
	EventBus.toast.connect(show_toast)
	EventBus.item_gained.connect(_on_item_gained)
	EventBus.map_changed.connect(_on_map_changed)
	refresh()
	_on_hotbar()


func _build_clock() -> void:
	var p: PanelContainer = PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	p.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	p.position = Vector2(-MARGIN, MARGIN)
	add_child(p)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	p.add_child(v)
	var r1: HBoxContainer = HBoxContainer.new()
	_season_icon = UIKit.icon_rect(null, Vector2(12, 12))
	_date = UIKit.label("")
	r1.add_child(_season_icon)
	r1.add_child(_date)
	var r2: HBoxContainer = HBoxContainer.new()
	_weather_icon = UIKit.icon_rect(null, Vector2(12, 12))
	_time = UIKit.label("")
	r2.add_child(_weather_icon)
	r2.add_child(_time)
	var r3: HBoxContainer = HBoxContainer.new()
	r3.add_child(UIKit.icon_rect(Database.sprite("coin"), Vector2(12, 12)))
	_money = UIKit.label("")
	r3.add_child(_money)
	v.add_child(r1)
	v.add_child(r2)
	v.add_child(r3)
	_fps = UIKit.label("", Color.WHITE)
	_fps.position = Vector2(MARGIN, MARGIN)
	_fps.visible = false
	add_child(_fps)


func _build_bars() -> void:
	_energy = _make_bar(func() -> float: return GameState.energy / maxf(1.0, float(GameState.max_energy)), "bar_energy")
	_health = _make_bar(func() -> float: return GameState.health / maxf(1.0, float(GameState.max_health)), "bar_health")
	_energy.position = Vector2(-MARGIN - 12, -MARGIN - 62)
	_health.position = Vector2(-MARGIN - 26, -MARGIN - 62)


func _make_bar(ratio: Callable, sprite: String) -> Control:
	var c: Control = Control.new()
	c.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	c.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	c.grow_vertical = Control.GROW_DIRECTION_BEGIN
	c.custom_minimum_size = Vector2(12, 62)
	c.size = Vector2(12, 62)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func() -> void:
		c.draw_rect(Rect2(0, 0, 12, 62), UIKit.INK)
		c.draw_rect(Rect2(1, 1, 10, 60), Color("4a3228"))
		var r: float = clampf(ratio.call(), 0.0, 1.0)
		var h: int = int(round(58.0 * r))
		if h > 0:
			c.draw_texture_rect(Database.sprite(sprite), Rect2(2, 60 - h, 8, h), true)
		c.draw_rect(Rect2(0, 0, 12, 62), Color(0, 0, 0, 0), false))
	add_child(c)
	return c


func _build_hotbar() -> void:
	_hotbar = SlotGrid.new()
	_hotbar.configure(GameState.inventory, 0, InputManager.HOTBAR_SIZE, InputManager.HOTBAR_SIZE)
	_hotbar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hotbar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hotbar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hotbar.position = Vector2(-_hotbar.size.x / 2.0, -_hotbar.size.y - MARGIN)
	_hotbar.slot_pressed.connect(func(i: int, _b: int) -> void: hotbar_pressed.emit(i))
	add_child(_hotbar)
	_water = UIKit.label("", Color.WHITE)
	_water.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_water.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_water.position = Vector2(-20, -_hotbar.size.y - MARGIN - 13)
	add_child(_water)


func _build_toasts() -> void:
	_toasts = VBoxContainer.new()
	_toasts.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toasts.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toasts.position = Vector2(0, MARGIN + 18)
	_toasts.alignment = BoxContainer.ALIGNMENT_BEGIN
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toasts.add_theme_constant_override("separation", 1)
	add_child(_toasts)
	_banner = UIKit.label("", Color.WHITE, true)
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.position = Vector2(0, 96)
	_banner.modulate.a = 0.0
	add_child(_banner)


func refresh() -> void:
	if not GameState.active:
		return
	_date.text = TimeManager.date_text()
	_season_icon.texture = Database.sprite("season_" + TimeManager.season_id())
	_time.text = TimeManager.format_time(GameState.minutes)
	_weather_icon.texture = Database.sprite("weather_" + GameState.weather)
	_money.text = str(GameState.money)
	_energy.queue_redraw()
	_health.queue_redraw()
	_health.visible = GameState.health < float(GameState.max_health) or bool(GameState.flags.get("in_mine", false))


func _on_hotbar() -> void:
	if _hotbar == null:
		return
	_hotbar.slots = GameState.inventory
	_hotbar.selected = GameState.hotbar_index
	_hotbar.queue_redraw()
	_update_water()


func _update_water() -> void:
	var id: String = GameState.held_id()
	var it: Dictionary = Database.item(id)
	var txt: String = ""
	if str(it.get("tool", "")) == "can":
		txt = "%d/%d" % [GameState.can_water, ToolUse.can_capacity(int(it.get("level", 1)))]
	if txt != _water.text:
		_water.text = txt


func _process(_delta: float) -> void:
	_fps.visible = Settings.show_fps or bool(GameState.flags.get("debug", false))
	if _fps.visible:
		_fps.text = "%d FPS" % Engine.get_frames_per_second()
	_update_water()


func show_toast(text: String, icon_id: String = "") -> void:
	if _toasts == null:
		return
	if _toasts.get_child_count() >= MAX_TOASTS:
		_toasts.get_child(0).queue_free()
	var p: PanelContainer = PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var h: HBoxContainer = HBoxContainer.new()
	if icon_id != "" and Database.icon(icon_id) != null:
		h.add_child(UIKit.icon_rect(Database.icon(icon_id), Vector2(14, 14)))
	h.add_child(UIKit.label(text))
	p.add_child(h)
	_toasts.add_child(p)
	var tw: Tween = create_tween()
	tw.tween_interval(TOAST_TIME)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)


func _on_item_gained(id: String, n: int, q: int) -> void:
	show_toast("+%d %s" % [n, UIKit.stack_name(id, q)], id)


func _on_map_changed(map_id: String) -> void:
	var key: String = str(Database.map(map_id).get("name", ""))
	if key == "":
		return
	_banner.text = Loc.t(key)
	_banner.modulate.a = 1.0
	var tw: Tween = create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.8)
