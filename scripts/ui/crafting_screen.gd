class_name CraftingScreen
extends ScreenBase
## Menu d'artisanat (« craft ») ou de cuisine (« cook ») : recettes connues, ingrédients, fabrication.

var kind: String = "craft"

var _list: VBoxContainer


func setup(p_kind: String) -> CraftingScreen:
	kind = p_kind
	return self


func _ready() -> void:
	var panel: PanelContainer = PanelContainer.new()
	center(panel)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.custom_minimum_size = Vector2(330, 0)
	panel.add_child(v)
	v.add_child(UIKit.label(Loc.t("CRAFT_TITLE" if kind == "craft" else "COOK_TITLE"), UIKit.BARK_D, true))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 170)
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
	AudioManager.sfx("ui_open")
	close_b.grab_focus()


func _refresh() -> void:
	for c: Node in _list.get_children():
		c.queue_free()
	var ids: Array[String] = Crafting.known_ids(kind)
	if ids.is_empty():
		_list.add_child(UIKit.label(Loc.t("CRAFT_NONE"), UIKit.STONE))
	for id: String in ids:
		_list.add_child(_row(id))


func _row(id: String) -> PanelContainer:
	var r: Dictionary = Crafting.table(kind)[id]
	var pc: PanelContainer = PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UIKit.box("panel_inset", 3, 3, 2, 2))
	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", 5)
	pc.add_child(h)
	h.add_child(UIKit.icon_rect(Database.icon(id), Vector2(16, 16)))
	var col: VBoxContainer = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	var title: String = Database.item_name(id)
	if int(r["n"]) > 1:
		title += " x%d" % int(r["n"])
	col.add_child(UIKit.label(title))
	var ing: HBoxContainer = HBoxContainer.new()
	ing.add_theme_constant_override("separation", 6)
	var ings: Dictionary = r["in"]
	for key: String in ings:
		var have: int = Crafting.count(key)
		var need: int = int(ings[key])
		var cell: HBoxContainer = HBoxContainer.new()
		cell.add_theme_constant_override("separation", 1)
		if not key.begins_with("@"):
			cell.add_child(UIKit.icon_rect(Database.icon(key), Vector2(10, 10)))
		else:
			cell.add_child(UIKit.label(Crafting.ingredient_name(key), UIKit.STONE))
		cell.add_child(UIKit.label("%d/%d" % [have, need], UIKit.LEAF if have >= need else UIKit.RED))
		ing.add_child(cell)
	col.add_child(ing)
	h.add_child(col)
	var b: Button = UIKit.button(Loc.t("CRAFT_MAKE" if kind == "craft" else "COOK_MAKE"), 62)
	b.disabled = not Crafting.can_make(kind, id)
	b.pressed.connect(func() -> void:
		var err: String = Crafting.make(kind, id)
		if err != "":
			AudioManager.sfx("error")
			EventBus.toast.emit(Loc.t(err), "")
		_refresh())
	h.add_child(b)
	return pc
