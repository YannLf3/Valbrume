class_name OptionsScreen
extends ScreenBase
## Options : langue, volumes, touches, plein écran, commandes tactiles, vitesse du temps.

const SPEEDS: Array[float] = [0.4, 0.55, 0.7, 0.9, 1.2]


func _ready() -> void:
	var panel: PanelContainer = PanelContainer.new()
	center(panel)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.custom_minimum_size = Vector2(260, 0)
	panel.add_child(v)
	v.add_child(UIKit.label(Loc.t("OPT_TITLE"), UIKit.BARK_D, true))
	v.add_child(_cycle("OPT_LANGUAGE", Settings.LANGUAGES, "language", func(x: String) -> String: return Loc.t("LANG_" + x.to_upper())))
	v.add_child(_slider("OPT_MASTER", "volume_master"))
	v.add_child(_slider("OPT_MUSIC", "volume_music"))
	v.add_child(_slider("OPT_SFX", "volume_sfx"))
	v.add_child(_cycle("OPT_KEYS", Settings.LAYOUTS, "key_layout", func(x: String) -> String: return Loc.t("OPT_KEYS_" + x.to_upper())))
	var mobile: bool = OS.has_feature("mobile")
	if not mobile:
		v.add_child(_check("OPT_FULLSCREEN", "fullscreen"))
	v.add_child(_cycle("OPT_TOUCH", Settings.TOUCH_MODES, "touch_mode", func(x: String) -> String: return Loc.t("OPT_TOUCH_" + x.to_upper())))
	v.add_child(_speed_row())
	v.add_child(_check("OPT_SHAKE", "screen_shake"))
	v.add_child(_check("OPT_FPS", "show_fps"))
	var b: Button = UIKit.button(Loc.t("COMMON_BACK"), 80)
	b.pressed.connect(func() -> void: close(null))
	var br: HBoxContainer = HBoxContainer.new()
	br.alignment = BoxContainer.ALIGNMENT_CENTER
	br.add_child(b)
	v.add_child(br)
	b.grab_focus()


func _row(key: String) -> HBoxContainer:
	var r: HBoxContainer = HBoxContainer.new()
	var l: Label = UIKit.label(Loc.t(key))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(l)
	return r


func _slider(key: String, field: String) -> HBoxContainer:
	var r: HBoxContainer = _row(key)
	var s: HSlider = HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(Settings.get(field))
	s.custom_minimum_size = Vector2(100, 12)
	s.value_changed.connect(func(val: float) -> void:
		Settings.set_value(field, val)
		AudioManager.sfx("ui_move", 0.0))
	r.add_child(s)
	return r


func _check(key: String, field: String) -> HBoxContainer:
	var r: HBoxContainer = _row(key)
	var c: CheckBox = CheckBox.new()
	c.button_pressed = bool(Settings.get(field))
	c.toggled.connect(func(on: bool) -> void: Settings.set_value(field, on))
	r.add_child(c)
	return r


func _cycle(key: String, values: Array, field: String, shown: Callable) -> HBoxContainer:
	var r: HBoxContainer = _row(key)
	var b: Button = UIKit.button("", 110)
	var refresh: Callable = func() -> void: b.text = shown.call(str(Settings.get(field)))
	refresh.call()
	b.pressed.connect(func() -> void:
		var i: int = values.find(Settings.get(field))
		Settings.set_value(field, values[(i + 1) % values.size()])
		if field == "key_layout":
			InputManager.rebuild_actions()
		if field == "language":
			close(null)
			EventBus.ui_requested.emit("options", {})
		else:
			refresh.call())
	r.add_child(b)
	return r


func _speed_row() -> HBoxContainer:
	var r: HBoxContainer = _row("OPT_SPEED")
	var b: Button = UIKit.button("%.2f" % Settings.seconds_per_minute, 110)
	b.pressed.connect(func() -> void:
		var i: int = 0
		for k: int in SPEEDS.size():
			if absf(SPEEDS[k] - Settings.seconds_per_minute) < 0.01:
				i = k
		Settings.set_value("seconds_per_minute", SPEEDS[(i + 1) % SPEEDS.size()])
		b.text = "%.2f" % Settings.seconds_per_minute)
	r.add_child(b)
	return r
