class_name TitleScreen
extends Control
## Menu titre : jouer (3 emplacements, nouvelle partie), options, crédits, quitter.

signal play_requested(slot: int, is_new: bool, player_name: String, farm_name: String, outfit: int)

var _page: Control = null
var _logo: Control = null
var _name_edit: LineEdit
var _farm_edit: LineEdit
var _outfit: int = 0
var _outfit_buttons: Array[Button] = []


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UIKit.theme()


func _ready() -> void:
	var bg: TextureRect = TextureRect.new()
	bg.texture = Database.sheet("ui/title_bg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)
	var logo: TextureRect = UIKit.icon_rect(Database.sprite("logo"), Database.sprite("logo").get_size() * 1.0)
	logo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	logo.grow_horizontal = Control.GROW_DIRECTION_BOTH
	logo.position = Vector2(-logo.custom_minimum_size.x / 2.0, 18)
	add_child(logo)
	_logo = logo
	_show_main()


func _set_page(p: Control, with_logo: bool = true) -> void:
	_logo.visible = with_logo
	if _page != null:
		_page.queue_free()
	_page = p
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.position.y += 36
	add_child(p)


func _column(width: int) -> VBoxContainer:
	var v: VBoxContainer = VBoxContainer.new()
	v.custom_minimum_size = Vector2(width, 0)
	v.add_theme_constant_override("separation", 4)
	return v


func _show_main() -> void:
	var v: VBoxContainer = _column(120)
	var play: Button = UIKit.button(Loc.t("TITLE_PLAY"), 120)
	play.pressed.connect(_show_slots)
	var opts: Button = UIKit.button(Loc.t("TITLE_OPTIONS"), 120)
	opts.pressed.connect(_open_options)
	var cred: Button = UIKit.button(Loc.t("TITLE_CREDITS"), 120)
	cred.pressed.connect(_show_credits)
	v.add_child(play)
	v.add_child(opts)
	v.add_child(cred)
	if not OS.has_feature("mobile") and not OS.has_feature("web"):
		var q: Button = UIKit.button(Loc.t("TITLE_QUIT"), 120)
		q.pressed.connect(func() -> void: get_tree().quit())
		v.add_child(q)
	_set_page(v)
	play.grab_focus()


func _open_options() -> void:
	var o: OptionsScreen = OptionsScreen.new()
	add_child(o)
	o.closed.connect(func(_r: Variant) -> void: _show_main())


func _show_credits() -> void:
	var v: VBoxContainer = _column(240)
	var p: PanelContainer = PanelContainer.new()
	var l: Label = UIKit.label(Loc.t("CREDITS_TEXT"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	v.add_child(p)
	var back: Button = UIKit.button(Loc.t("COMMON_BACK"), 120)
	back.pressed.connect(_show_main)
	v.add_child(back)
	_set_page(v)
	back.grab_focus()


func _show_slots() -> void:
	var v: VBoxContainer = _column(300)
	v.add_child(UIKit.label(Loc.t("SLOTS_TITLE"), Color.WHITE))
	var first: Button = null
	for slot: int in SaveManager.SLOT_COUNT:
		var p: PanelContainer = PanelContainer.new()
		var row: HBoxContainer = HBoxContainer.new()
		p.add_child(row)
		var info: Label = UIKit.label("")
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		if SaveManager.slot_exists(slot):
			var sm: Dictionary = SaveManager.slot_summary(slot)
			var d: int = int(sm.get("day", 0))
			var date: String = "%s %d" % [Loc.t("SEASON_" + str(TimeManager.SEASONS[TimeManager.season_of(d)]).to_upper()), TimeManager.day_of_season(d)]
			info.text = "%s\n%s · %s · %d" % [Loc.f("SLOT_INFO", [str(sm.get("player", "?")), str(sm.get("farm", "?")), d + 1]), date, Loc.t("SUMMARY_TOTAL"), int(sm.get("money", 0))]
			var cont: Button = UIKit.button(Loc.t("SLOT_CONTINUE"), 70)
			cont.pressed.connect(func() -> void: play_requested.emit(slot, false, "", "", 0))
			var del: Button = UIKit.button(Loc.t("SLOT_DELETE"), 60)
			del.pressed.connect(_confirm_delete.bind(slot))
			row.add_child(cont)
			row.add_child(del)
			if first == null:
				first = cont
		else:
			info.text = "%s\n%s" % [Loc.f("SLOT_N", [slot + 1]), Loc.t("SLOT_EMPTY")]
			var nb: Button = UIKit.button(Loc.t("SLOT_NEW"), 100)
			nb.pressed.connect(_show_new_game.bind(slot))
			row.add_child(nb)
			if first == null:
				first = nb
		v.add_child(p)
	var back: Button = UIKit.button(Loc.t("COMMON_BACK"), 120)
	back.pressed.connect(_show_main)
	v.add_child(back)
	_set_page(v, false)
	first.grab_focus()


func _confirm_delete(slot: int) -> void:
	var c: ConfirmScreen = ConfirmScreen.new().setup(Loc.t("DELETE_CONFIRM"))
	add_child(c)
	c.closed.connect(func(yes: Variant) -> void:
		if bool(yes):
			SaveManager.delete_slot(slot)
		_show_slots())


func _show_new_game(slot: int) -> void:
	var v: VBoxContainer = _column(240)
	v.add_child(UIKit.label(Loc.t("NEW_TITLE"), Color.WHITE))
	var p: PanelContainer = PanelContainer.new()
	var g: VBoxContainer = VBoxContainer.new()
	p.add_child(g)
	g.add_child(UIKit.label(Loc.t("NEW_NAME")))
	_name_edit = LineEdit.new()
	_name_edit.max_length = 14
	_name_edit.text = Loc.t("DEFAULT_NAME")
	g.add_child(_name_edit)
	g.add_child(UIKit.label(Loc.t("NEW_FARM")))
	_farm_edit = LineEdit.new()
	_farm_edit.max_length = 22
	_farm_edit.text = Loc.t("DEFAULT_FARM")
	g.add_child(_farm_edit)
	g.add_child(UIKit.label(Loc.t("NEW_OUTFIT")))
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_outfit_buttons.clear()
	_outfit = 0
	for i: int in 3:
		var b: Button = Button.new()
		b.toggle_mode = true
		b.button_pressed = i == 0
		b.custom_minimum_size = Vector2(44, 62)
		b.focus_mode = Control.FOCUS_ALL
		var at: AtlasTexture = AtlasTexture.new()
		at.atlas = Database.sheet("sprites/chars/player_%d" % i)
		at.region = Rect2(0, 0, 16, 24)
		b.icon = at
		b.expand_icon = true
		b.pressed.connect(_pick_outfit.bind(i))
		_outfit_buttons.append(b)
		row.add_child(b)
	g.add_child(row)
	v.add_child(p)
	var start: Button = UIKit.button(Loc.t("NEW_START"), 120)
	start.pressed.connect(func() -> void:
		var n: String = _name_edit.text.strip_edges()
		var f: String = _farm_edit.text.strip_edges()
		play_requested.emit(slot, true, n if n != "" else Loc.t("DEFAULT_NAME"), f if f != "" else Loc.t("DEFAULT_FARM"), _outfit))
	var back: Button = UIKit.button(Loc.t("COMMON_BACK"), 120)
	back.pressed.connect(_show_slots)
	v.add_child(start)
	v.add_child(back)
	_set_page(v, false)
	p.get_parent().position.y -= 30
	_name_edit.grab_focus()


func _pick_outfit(i: int) -> void:
	_outfit = i
	for k: int in _outfit_buttons.size():
		_outfit_buttons[k].button_pressed = k == i
