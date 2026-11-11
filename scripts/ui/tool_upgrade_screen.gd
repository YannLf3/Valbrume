class_name ToolUpgradeScreen
extends ScreenBase
## Atelier du forgeron : choisir un outil du sac à améliorer.

var _list: VBoxContainer
var _status: Label


func _ready() -> void:
	var panel: PanelContainer = PanelContainer.new()
	center(panel)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.custom_minimum_size = Vector2(340, 0)
	panel.add_child(v)
	v.add_child(UIKit.label(Loc.t("UPGRADE_TITLE"), UIKit.BARK_D, true))
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
	if not GameState.tool_upgrade.is_empty():
		_status.text = Loc.f("UPGRADE_NOW", [Database.item_name(str(GameState.tool_upgrade["item"])), int(GameState.tool_upgrade["days"])])
	else:
		_status.text = ""
	var seen: Dictionary = {}
	for s: Variant in GameState.inventory:
		if s == null:
			continue
		var id: String = str(s["id"])
		if seen.has(id) or not Database.item(id).has("tool"):
			continue
		seen[id] = true
		_list.add_child(_row(id))


func _row(id: String) -> PanelContainer:
	var pc: PanelContainer = PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UIKit.box("panel_inset", 3, 3, 2, 2))
	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", 5)
	pc.add_child(h)
	h.add_child(UIKit.icon_rect(Database.icon(id), Vector2(16, 16)))
	var col: VBoxContainer = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	col.add_child(UIKit.label(Database.item_name(id)))
	var cost: Dictionary = ToolUpgrades.cost(id)
	var b: Button = UIKit.button(Loc.t("UPGRADE_START"), 70)
	if cost.is_empty() or not Database.has_item(ToolUpgrades.next_id(id)):
		col.add_child(UIKit.label(Loc.t("UPGRADE_MAX"), UIKit.STONE))
		b.disabled = true
	else:
		var ing: HBoxContainer = HBoxContainer.new()
		ing.add_theme_constant_override("separation", 6)
		ing.add_child(UIKit.icon_rect(Database.sprite("coin"), Vector2(10, 10)))
		ing.add_child(UIKit.label(str(int(cost["price"])), UIKit.LEAF if GameState.money >= int(cost["price"]) else UIKit.RED))
		for it: String in cost["items"]:
			var have: int = GameState.item_count(it)
			ing.add_child(UIKit.icon_rect(Database.icon(it), Vector2(10, 10)))
			ing.add_child(UIKit.label("%d/%d" % [have, int(cost["items"][it])], UIKit.LEAF if have >= int(cost["items"][it]) else UIKit.RED))
		col.add_child(ing)
		b.disabled = ToolUpgrades.can_start(id) != ""
	h.add_child(col)
	b.pressed.connect(func() -> void:
		var err: String = ToolUpgrades.start(id)
		if err != "":
			AudioManager.sfx("error")
			EventBus.toast.emit(Loc.t(err), "")
		_refresh())
	h.add_child(b)
	return pc
