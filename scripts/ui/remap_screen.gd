class_name RemapScreen
extends ScreenBase
## Remappage des touches clavier ; enregistré dans les options.

var _listening: String = ""
var _list: VBoxContainer
var _hint: Label


func _ready() -> void:
	var panel: PanelContainer = PanelContainer.new()
	center(panel)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.custom_minimum_size = Vector2(280, 0)
	panel.add_child(v)
	v.add_child(UIKit.label(Loc.t("REMAP_TITLE"), UIKit.BARK_D, true))
	_hint = UIKit.label("")
	v.add_child(_hint)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 160)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	var reset: Button = UIKit.button(Loc.t("REMAP_RESET"), 90)
	reset.pressed.connect(func() -> void:
		InputManager.reset_bindings()
		_refresh())
	var back: Button = UIKit.button(Loc.t("COMMON_BACK"), 70)
	back.pressed.connect(func() -> void: close(null))
	row.add_child(reset)
	row.add_child(back)
	v.add_child(row)
	_refresh()
	back.grab_focus()


func _refresh() -> void:
	for c: Node in _list.get_children():
		c.queue_free()
	_hint.text = Loc.t("REMAP_PRESS") if _listening != "" else ""
	for a: String in InputManager.REMAPPABLE:
		var r: HBoxContainer = HBoxContainer.new()
		var l: Label = UIKit.label(Loc.t("ACT_" + a.to_upper()))
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(l)
		var b: Button = UIKit.button("…" if _listening == a else InputManager.action_label(a), 90)
		b.pressed.connect(func() -> void:
			_listening = a
			_refresh())
		r.add_child(b)
		_list.add_child(r)


func _input(event: InputEvent) -> void:
	if _listening != "":
		if event is InputEventKey and event.pressed:
			get_viewport().set_input_as_handled()
			if (event as InputEventKey).keycode != KEY_ESCAPE:
				InputManager.rebind(_listening, event)
			_listening = ""
			_refresh()
		return
	super(event)
