class_name AnimalShopScreen
extends ScreenBase
## Achat d'animaux : le nom se choisit à l'arrivée.

signal bought(type: String, animal_name: String)

var _list: VBoxContainer


func _ready() -> void:
	var panel: PanelContainer = PanelContainer.new()
	center(panel)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.custom_minimum_size = Vector2(330, 0)
	panel.add_child(v)
	v.add_child(UIKit.label(Loc.t("ANIMAL_SHOP_TITLE"), UIKit.BARK_D, true))
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
	var types: Array = Animals.table().keys()
	types.sort_custom(func(a: String, b: String) -> bool: return int(Animals.table()[a]["price"]) < int(Animals.table()[b]["price"]))
	for t: String in types:
		_list.add_child(_row(t))


func _row(type: String) -> PanelContainer:
	var d: Dictionary = Animals.table()[type]
	var pc: PanelContainer = PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UIKit.box("panel_inset", 3, 3, 2, 2))
	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", 5)
	pc.add_child(h)
	var at: AtlasTexture = AtlasTexture.new()
	at.atlas = Database.sheet("sprites/creatures/animal_" + type)
	at.region = Rect2(0, 0, 24, 20)
	h.add_child(UIKit.icon_rect(at, Vector2(26, 20)))
	var col: VBoxContainer = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	col.add_child(UIKit.label(Loc.t("ANIMAL_" + type.to_upper())))
	var sub: HBoxContainer = HBoxContainer.new()
	sub.add_theme_constant_override("separation", 4)
	sub.add_child(UIKit.icon_rect(Database.sprite("coin"), Vector2(10, 10)))
	sub.add_child(UIKit.label(str(int(d["price"])), UIKit.STONE))
	sub.add_child(UIKit.icon_rect(Database.icon(str(d["product"])), Vector2(10, 10)))
	sub.add_child(UIKit.label("%s %d" % [Loc.t("BUILDING_" + str(d["home"]).to_upper()), int(d["min_level"])], UIKit.STONE))
	col.add_child(sub)
	h.add_child(col)
	var b: Button = UIKit.button(Loc.t("SHOP_BUY"), 60)
	var err: String = Animals.can_buy(type)
	b.disabled = err != ""
	b.tooltip_text = Loc.t(err) if err != "" else ""
	b.pressed.connect(_ask_name.bind(type))
	h.add_child(b)
	return pc


func _ask_name(type: String) -> void:
	var p: NamePrompt = NamePrompt.new()
	p.default_name = Animals.NAMES_FR[WorldObjects.rng.randi_range(0, Animals.NAMES_FR.size() - 1)]
	add_child(p)
	p.closed.connect(func(result: Variant) -> void:
		if result == null:
			return
		var err: String = Animals.buy(type, str(result))
		if err != "":
			EventBus.toast.emit(Loc.t(err), "")
		else:
			EventBus.toast.emit(Loc.f("ANIMAL_BOUGHT", [str(result)]), "")
			bought.emit(type, str(result))
		_refresh())
