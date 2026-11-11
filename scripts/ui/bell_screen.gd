class_name BellScreen
extends ScreenBase
## Fonderie du Carillon (chez Bastien) : les six cloches, leurs exigences, la fonte.

signal bell_cast(bell_id: String)

var _list: VBoxContainer


func _ready() -> void:
	var panel: PanelContainer = PanelContainer.new()
	center(panel)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.custom_minimum_size = Vector2(380, 0)
	panel.add_child(v)
	v.add_child(UIKit.label(Loc.t("BELL_TITLE"), UIKit.BARK_D, true))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 190)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 2)
	scroll.add_child(_list)
	var close_b: Button = UIKit.button(Loc.t("COMMON_CLOSE"), 90)
	close_b.pressed.connect(func() -> void: close(null))
	var br: HBoxContainer = HBoxContainer.new()
	br.alignment = BoxContainer.ALIGNMENT_END
	br.add_child(close_b)
	v.add_child(br)
	_refresh()
	close_b.grab_focus()
	AudioManager.sfx("ui_open")


func _refresh() -> void:
	for c: Node in _list.get_children():
		c.queue_free()
	for id: String in Story.BELL_IDS:
		_list.add_child(_row(id))


func _row(id: String) -> PanelContainer:
	var pc: PanelContainer = PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UIKit.box("panel_inset", 3, 3, 2, 2))
	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	pc.add_child(h)
	var at: Texture2D = Database.sprite("bell_on" if Story.is_cast(id) else "bell_off")
	h.add_child(UIKit.icon_rect(at, Vector2(14, 16)))
	var col: VBoxContainer = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	col.add_child(UIKit.label(Loc.t("BELL_" + id.to_upper()), UIKit.RED if not Story.is_cast(id) else UIKit.LEAF))
	var d: Label = UIKit.label(Loc.t("BELLD_" + id.to_upper()), UIKit.STONE)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(250, 0)
	col.add_child(d)
	if not Story.is_cast(id):
		for r: Array in Story.requirements(id):
			var p: Vector2i = Story.progress(r)
			var ok_: bool = p.x >= p.y
			col.add_child(UIKit.label("%s  %d/%d" % [Story.requirement_text(r), mini(p.x, p.y), p.y], UIKit.LEAF if ok_ else UIKit.INK))
	else:
		col.add_child(UIKit.label(Loc.t("BELLR_" + id.to_upper()), UIKit.LEAF))
	h.add_child(col)
	var b: Button = UIKit.button(Loc.t("BELL_DONE" if Story.is_cast(id) else "BELL_CAST"), 64)
	b.disabled = not Story.can_cast(id)
	b.pressed.connect(func() -> void:
		var err: String = Story.cast(id)
		if err != "":
			EventBus.toast.emit(Loc.t(err), "")
		else:
			EventBus.toast.emit(Loc.t("BELLR_" + id.to_upper()), "")
			bell_cast.emit(id)
		_refresh())
	h.add_child(b)
	return pc
