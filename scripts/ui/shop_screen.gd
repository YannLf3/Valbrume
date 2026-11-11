class_name ShopScreen
extends ScreenBase
## Magasin : acheter (stock de saison, recettes, grand sac) ou vendre depuis le sac.

signal talk_requested(npc_id: String)
signal service_requested(service: String)

const SERVICES: Dictionary = {"build": "SERVICE_BUILD", "animals": "SERVICE_ANIMALS", "tool_upgrade": "SERVICE_UPGRADE", "bell_cast": "SERVICE_BELLS"}

var shop_id: String = ""

var _tab: String = "buy"
var _list: VBoxContainer
var _money: Label
var _buy_btn: Button
var _sell_btn: Button
var _scroll: ScrollContainer


func setup(p_shop: String) -> ShopScreen:
	shop_id = p_shop
	return self


func _ready() -> void:
	var s: Dictionary = Shops.shop(shop_id)
	var npc_id: String = str(s.get("npc", ""))
	var panel: PanelContainer = PanelContainer.new()
	center(panel)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.custom_minimum_size = Vector2(300, 0)
	panel.add_child(v)
	var head: HBoxContainer = HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	if npc_id != "" and Database.sheet("sprites/chars/portrait_" + npc_id) != null:
		var at: AtlasTexture = AtlasTexture.new()
		at.atlas = Database.sheet("sprites/chars/portrait_" + npc_id)
		at.region = Rect2(48, 0, 48, 48)
		head.add_child(UIKit.icon_rect(at, Vector2(40, 40)))
	var names: VBoxContainer = VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_child(UIKit.label(Loc.t("SHOP_" + shop_id.to_upper()), UIKit.BARK_D, true))
	if npc_id != "":
		names.add_child(UIKit.label("%s · %s" % [Loc.t("NPC_" + npc_id.to_upper()), Loc.t("JOB_" + npc_id.to_upper())]))
	head.add_child(names)
	if npc_id != "":
		var talk: Button = UIKit.button(Loc.t("SHOP_TALK"), 56)
		talk.pressed.connect(func() -> void:
			talk_requested.emit(npc_id)
			close(null))
		head.add_child(talk)
	v.add_child(head)
	var tabs: HBoxContainer = HBoxContainer.new()
	_buy_btn = UIKit.button(Loc.t("SHOP_BUY"), 80)
	_sell_btn = UIKit.button(Loc.t("SHOP_SELL"), 80)
	_buy_btn.pressed.connect(_set_tab.bind("buy"))
	_sell_btn.pressed.connect(_set_tab.bind("sell"))
	tabs.add_child(_buy_btn)
	tabs.add_child(_sell_btn)
	for svc: String in s.get("services", []):
		if SERVICES.has(svc):
			var sb: Button = UIKit.button(Loc.t(str(SERVICES[svc])), 80)
			sb.pressed.connect(func() -> void:
				service_requested.emit(svc)
				close(null))
			tabs.add_child(sb)
	_money = UIKit.label("")
	_money.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_money.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tabs.add_child(_money)
	v.add_child(tabs)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(0, 124)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 1)
	_scroll.add_child(_list)
	var close_b: Button = UIKit.button(Loc.t("COMMON_CLOSE"), 90)
	close_b.pressed.connect(func() -> void: close(null))
	var br: HBoxContainer = HBoxContainer.new()
	br.alignment = BoxContainer.ALIGNMENT_END
	br.add_child(close_b)
	v.add_child(br)
	_refresh()
	_buy_btn.grab_focus()
	AudioManager.sfx("ui_open")


func _set_tab(t: String) -> void:
	_tab = t
	_refresh()


func _refresh() -> void:
	for c: Node in _list.get_children():
		c.queue_free()
	_money.text = str(GameState.money)
	_buy_btn.disabled = _tab == "buy"
	_sell_btn.disabled = _tab == "sell"
	if _tab == "buy":
		var lines: Array[Dictionary] = Shops.stock(shop_id)
		if lines.is_empty():
			_list.add_child(UIKit.label(Loc.t("SHOP_EMPTY"), UIKit.STONE))
		for line: Dictionary in lines:
			_list.add_child(_buy_row(line))
	else:
		var any: bool = false
		for i: int in GameState.inventory.size():
			var s: Variant = GameState.inventory[i]
			if s == null or Database.item(str(s["id"])).has("tool") or int(Database.item(str(s["id"])).get("price", 0)) <= 0:
				continue
			any = true
			_list.add_child(_sell_row(i, s))
		if not any:
			_list.add_child(UIKit.label(Loc.t("SHOP_NOTHING_TO_SELL"), UIKit.STONE))


func _row(icon: Texture2D, text: String, price: int) -> HBoxContainer:
	var r: HBoxContainer = HBoxContainer.new()
	r.add_theme_constant_override("separation", 4)
	r.add_child(UIKit.icon_rect(icon, Vector2(14, 14)))
	var l: Label = UIKit.label(text)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.clip_text = true
	r.add_child(l)
	r.add_child(UIKit.icon_rect(Database.sprite("coin"), Vector2(10, 10)))
	var p: Label = UIKit.label(str(price))
	p.custom_minimum_size = Vector2(36, 0)
	p.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	r.add_child(p)
	return r


func _buy_row(line: Dictionary) -> HBoxContainer:
	var id: String = str(line["id"])
	var kind: String = str(line["kind"])
	var text: String = Database.item_name(id)
	var icon: Texture2D = Database.icon(id)
	if kind == "recipe":
		text = Loc.f("SHOP_RECIPE", [text])
	elif kind == "service":
		text = Loc.t("SHOP_BACKPACK")
		icon = Database.icon("chest")
	var r: HBoxContainer = _row(icon, text, int(line["price"]))
	var counts: Array = [1] if kind != "item" else [1, 5]
	for n: int in counts:
		var b: Button = UIKit.button("x%d" % n, 30)
		b.disabled = GameState.money < int(line["price"]) * n
		b.pressed.connect(func() -> void:
			var err: String = Shops.buy(line, n)
			if err != "":
				AudioManager.sfx("error")
				EventBus.toast.emit(Loc.t(err), "")
			_refresh())
		r.add_child(b)
	return r


func _sell_row(index: int, s: Dictionary) -> HBoxContainer:
	var id: String = str(s["id"])
	var q: int = int(s["q"])
	var r: HBoxContainer = _row(Database.icon(id), "%s x%d" % [UIKit.stack_name(id, q), int(s["n"])], Shops.sell_price(id, q))
	var one: Button = UIKit.button("x1", 30)
	one.pressed.connect(func() -> void:
		Shops.sell(index, 1)
		_refresh())
	var all: Button = UIKit.button(Loc.t("SHOP_ALL"), 40)
	all.pressed.connect(func() -> void:
		Shops.sell(index, int(s["n"]))
		_refresh())
	r.add_child(one)
	r.add_child(all)
	return r
