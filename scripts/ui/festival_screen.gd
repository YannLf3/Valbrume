class_name FestivalScreen
extends ScreenBase
## Jeux de fête : mémoire (semis), cadence (régate), jury (potiron), cible (lanternes). Résultat : score 0 à 100.

const SEED_ICONS: Array[String] = ["seed_turnip", "seed_carrot", "seed_pea", "seed_spinach"]

var mode: String = "memory"
var _canvas: Control
var _memory: FestivalGames.Memory
var _timing: FestivalGames.Timing
var _target: FestivalGames.Target
var _show_i: int = -1
var _show_t: float = 0.0
var _showing: bool = true
var _flash: float = 0.0
var _flash_ok: bool = true
var _end_t: float = -1.0
var _score: int = 0
var _buttons: Array[Button] = []
var _info: Label


func _init() -> void:
	super()
	cancelable = false


func setup(p_mode: String) -> FestivalScreen:
	mode = p_mode
	return self


func _ready() -> void:
	var panel: PanelContainer = PanelContainer.new()
	center(panel)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.custom_minimum_size = Vector2(260, 0)
	panel.add_child(v)
	v.add_child(UIKit.label(Loc.t("FEST_GAME_" + mode.to_upper()), UIKit.BARK_D, true))
	_info = UIKit.label("")
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size = Vector2(250, 0)
	v.add_child(_info)
	match mode:
		"memory":
			_memory = FestivalGames.Memory.new(WorldObjects.rng)
			var row: HBoxContainer = HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			for i: int in 4:
				var b: Button = Button.new()
				b.custom_minimum_size = Vector2(46, 46)
				b.icon = Database.icon(SEED_ICONS[i])
				b.expand_icon = true
				b.pressed.connect(_memory_press.bind(i))
				row.add_child(b)
				_buttons.append(b)
			v.add_child(row)
			_info.text = Loc.t("FEST_MEMORY_WATCH")
			_set_buttons(false)
		"timing":
			_timing = FestivalGames.Timing.new()
			_canvas = _make_canvas(260, 60)
			v.add_child(_canvas)
			_info.text = Loc.t("FEST_PRESS")
		"target":
			_target = FestivalGames.Target.new()
			_canvas = _make_canvas(260, 150)
			v.add_child(_canvas)
			_info.text = Loc.t("FEST_PRESS")
		"judging":
			_judging_list(v)
	AudioManager.sfx("ui_open")


func _make_canvas(w: int, h: int) -> Control:
	var c: Control = Control.new()
	c.custom_minimum_size = Vector2(w, h)
	c.draw.connect(_draw_canvas.bind(c))
	return c


func _set_buttons(enabled: bool) -> void:
	for b: Button in _buttons:
		b.disabled = not enabled


func _judging_list(v: VBoxContainer) -> void:
	_info.text = Loc.t("FEST_JUDGE_PICK")
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 130)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var found: bool = false
	for i: int in GameState.inventory.size():
		var s: Variant = GameState.inventory[i]
		if s == null:
			continue
		var cat: String = str(Database.item(str(s["id"])).get("cat", ""))
		if cat != "crop" and cat != "fruit":
			continue
		found = true
		var b: Button = UIKit.button(UIKit.stack_name(str(s["id"]), int(s["q"])), 240)
		b.icon = Database.icon(str(s["id"]))
		b.pressed.connect(func() -> void:
			var rng: RandomNumberGenerator = WorldObjects.rng
			_finish(FestivalGames.judge(str(s["id"]), int(s["q"]), rng)))
		list.add_child(b)
	if not found:
		_info.text = Loc.t("FEST_JUDGE_NONE")
		var skip: Button = UIKit.button(Loc.t("FEST_JUDGE_SKIP"), 240)
		skip.pressed.connect(func() -> void: _finish(10))
		list.add_child(skip)
	var first: Node = list.get_child(0)
	if first is Button:
		(first as Button).grab_focus()


func _memory_press(i: int) -> void:
	if _showing or _end_t >= 0.0:
		return
	var r: String = _memory.press(i)
	AudioManager.sfx("fish_beat" if r in ["ok", "round"] else ("fanfare" if r == "done" else "fish_miss"), 0.03)
	_flash = 0.25
	_flash_ok = r != "wrong"
	match r:
		"round":
			_showing = true
			_show_i = -1
			_show_t = 0.0
			_set_buttons(false)
			_info.text = Loc.f("FEST_MEMORY_ROUND", [_memory.round_n + 1, FestivalGames.Memory.ROUNDS])
		"done", "wrong":
			_finish(_memory.score())


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta
	if _end_t >= 0.0:
		_end_t -= delta
		if _end_t <= 0.0:
			close(_score)
		return
	match mode:
		"memory":
			if _showing:
				_show_t += delta
				var idx: int = int(_show_t / 0.7)
				if idx >= _memory.seq.size() + 1:
					_showing = false
					_show_i = -1
					_set_buttons(true)
					_info.text = Loc.t("FEST_MEMORY_GO")
				else:
					var new_i: int = _memory.seq[idx] if idx < _memory.seq.size() and fmod(_show_t, 0.7) < 0.5 else -1
					if new_i != _show_i and new_i >= 0:
						AudioManager.sfx("ui_move", 0.0)
					_show_i = new_i
				for k: int in _buttons.size():
					_buttons[k].modulate = Color(1.7, 1.7, 1.2) if k == _show_i else Color.WHITE
		"timing":
			_timing.update(delta)
			_canvas.queue_redraw()
		"target":
			_target.update(delta)
			_canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if mode == "timing" or mode == "target":
		var pressed: bool = event.is_action_pressed("action") or event.is_action_pressed("tool") \
			or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
		if pressed and _end_t < 0.0:
			get_viewport().set_input_as_handled()
			var acc: float = _timing.press() if mode == "timing" else _target.press()
			AudioManager.sfx("fish_perfect" if acc > 0.8 else ("fish_beat" if acc > 0.4 else "fish_miss"), 0.03)
			_flash = 0.2
			var g_fin: bool = _timing.finished if mode == "timing" else _target.finished
			if g_fin:
				_finish(_timing.score() if mode == "timing" else _target.score())
	elif mode == "memory":
		for i: int in 4:
			if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_1 + i:
				get_viewport().set_input_as_handled()
				_memory_press(i)


func _finish(score: int) -> void:
	_score = score
	_end_t = 1.1
	_info.text = Loc.f("FEST_SCORE", [score])
	AudioManager.sfx("fanfare" if score >= Festivals.TIER_SCORES[0] else "ui_close")


func _draw_canvas(c: Control) -> void:
	if mode == "timing":
		var w: float = c.size.x - 20.0
		c.draw_rect(Rect2(10, 24, w, 12), Color("453a4f"))
		c.draw_rect(Rect2(10 + w * 0.46, 22, w * 0.08, 16), Color("f0ae3f"))
		c.draw_rect(Rect2(10 + w * 0.49, 22, w * 0.02, 16), Color("f7dc6a"))
		var x: float = 10.0 + w * _timing.position()
		c.draw_rect(Rect2(x - 3, 18, 6, 24), Color("fbf7ec"))
		for i: int in FestivalGames.Timing.BEATS:
			c.draw_circle(Vector2(c.size.x / 2.0 + (i - 2.5) * 12.0, 52.0), 3.0, Color("f0ae3f") if i < _timing.beats else Color("453a4f"))
	else:
		var center_p: Vector2 = c.size / 2.0
		var r: float = 56.0
		for k: int in range(4, 0, -1):
			c.draw_circle(center_p, r * k / 4.0, [Color("c8413f"), Color("fbf7ec"), Color("5fa3d6"), Color("fbf7ec")][4 - k])
		c.draw_circle(center_p, 4.0, Color("c8413f"))
		var ch: Vector2 = center_p + _target.crosshair() * r
		c.draw_arc(ch, 6.0, 0.0, TAU, 16, Color("2b2233"), 2.0)
		c.draw_line(ch - Vector2(9, 0), ch + Vector2(9, 0), Color("2b2233"), 1.0)
		c.draw_line(ch - Vector2(0, 9), ch + Vector2(0, 9), Color("2b2233"), 1.0)
		for i: int in FestivalGames.Target.THROWS:
			c.draw_circle(Vector2(12.0 + i * 10.0, 10.0), 3.0, Color("f0ae3f") if i < _target.throws else Color("453a4f"))
