class_name MuseumScreen
extends ScreenBase
## Vitrine du musée : donner un exemplaire de chaque minéral, artefact ou poisson.

var category: String = "minerals"
var _list: VBoxContainer
var _head: Label


func setup(p_cat: String) -> MuseumScreen:
	category = p_cat
	return self


func _ready() -> void:
	var panel: PanelContainer = PanelContainer.new()
	center(panel)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.custom_minimum_size = Vector2(360, 0)
	panel.add_child(v)
	v.add_child(UIKit.label(Loc.t("COLL_" + category.to_upper()), UIKit.BARK_D, true))
	_head = UIKit.label("")
	v.add_child(_head)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 170)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 1)
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
	var items: Array = Collections.items(category)
	var rewards: Array = Collections.table()[category]["rewards"]
	var marks: PackedStringArray = []
	for r: Array in rewards:
		marks.append("%d★" % int(r[0]) if Collections.count(category) >= int(r[0]) else str(int(r[0])))
	_head.text = "%s %d/%d   [%s]" % [Loc.t("MUSEUM_PROGRESS"), Collections.count(category), items.size(), " · ".join(marks)]
	for id: Variant in items:
		var item_id: String = str(id)
		var r: HBoxContainer = HBoxContainer.new()
		r.add_theme_constant_override("separation", 4)
		var icon: TextureRect = UIKit.icon_rect(Database.icon(item_id), Vector2(14, 14))
		icon.modulate = Color.WHITE if Collections.is_donated(item_id) else Color(0.35, 0.3, 0.4)
		r.add_child(icon)
		var l: Label = UIKit.label(Database.item_name(item_id) if Collections.is_donated(item_id) or GameState.item_count(item_id) > 0 else "???", UIKit.INK if Collections.is_donated(item_id) else UIKit.STONE)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(l)
		if Collections.is_donated(item_id):
			r.add_child(UIKit.label(Loc.t("MUSEUM_DONATED"), UIKit.LEAF))
		else:
			var b: Button = UIKit.button(Loc.t("MUSEUM_DONATE"), 60)
			b.disabled = not Collections.can_donate(item_id)
			b.pressed.connect(func() -> void:
				var got: Array = Collections.donate(item_id)
				for rw: Dictionary in got:
					EventBus.toast.emit(Loc.t("MUSEUM_REWARD") + (": %d" % int(rw["money"]) if rw.has("money") else ": %s x%d" % [Database.item_name(str(rw["item"])), int(rw["n"])]), "")
				_refresh())
			r.add_child(b)
		_list.add_child(r)
