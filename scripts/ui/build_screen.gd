class_name BuildScreen
extends ScreenBase
## Chantiers du charpentier : poulailler, étable, silo, agrandissement de la maison.


var _list: VBoxContainer
var _status: Label


func _ready() -> void:
	var panel: PanelContainer = PanelContainer.new()
	center(panel)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.custom_minimum_size = Vector2(340, 0)
	panel.add_child(v)
	v.add_child(UIKit.label(Loc.t("BUILD_TITLE"), UIKit.BARK_D, true))
	_status = UIKit.label("")
	v.add_child(_status)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 2)
	v.add_child(_list)
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
	if Buildings.builder_busy():
		var cs: Dictionary = GameState.flags["construction"]
		_status.text = Loc.f("BUILD_NOW", [Loc.t("BUILDING_" + str(cs["type"]).to_upper()), int(cs["days"])])
	else:
		_status.text = ""
	for type: String in Buildings.TYPES:
		_list.add_child(_row(type))


func _row(type: String) -> PanelContainer:
	var pc: PanelContainer = PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UIKit.box("panel_inset", 3, 3, 2, 2))
	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", 5)
	pc.add_child(h)
	var col: VBoxContainer = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	var lv: int = Buildings.level(type)
	col.add_child(UIKit.label("%s  (%s %d)" % [Loc.t("BUILDING_" + type.to_upper()), Loc.t("BUILD_LEVEL"), lv]))
	var cost: Dictionary = Buildings.next_cost(type)
	var b: Button = UIKit.button(Loc.t("BUILD_START"), 70)
	if cost.is_empty():
		col.add_child(UIKit.label(Loc.t("BUILD_MAXED"), UIKit.STONE))
		b.disabled = true
	else:
		var ing: HBoxContainer = HBoxContainer.new()
		ing.add_theme_constant_override("separation", 6)
		var money_ok: bool = GameState.money >= int(cost["price"])
		ing.add_child(UIKit.icon_rect(Database.sprite("coin"), Vector2(10, 10)))
		ing.add_child(UIKit.label(str(int(cost["price"])), UIKit.LEAF if money_ok else UIKit.RED))
		for id: String in cost["items"]:
			var have: int = GameState.item_count(id)
			ing.add_child(UIKit.icon_rect(Database.icon(id), Vector2(10, 10)))
			ing.add_child(UIKit.label("%d/%d" % [have, int(cost["items"][id])], UIKit.LEAF if have >= int(cost["items"][id]) else UIKit.RED))
		ing.add_child(UIKit.label(Loc.f("BUILD_DAYS", [int(cost["days"])]), UIKit.STONE))
		col.add_child(ing)
		b.disabled = Buildings.can_start(type) != ""
	h.add_child(col)
	b.pressed.connect(func() -> void:
		var err: String = Buildings.start(type)
		if err != "":
			AudioManager.sfx("error")
			EventBus.toast.emit(Loc.t(err), "")
		else:
			EventBus.toast.emit(Loc.t("BUILD_STARTED"), "")
		_refresh())
	h.add_child(b)
	return pc
