class_name ContainerScreen
extends ScreenBase
## Sac du joueur, avec en option un second conteneur (coffre d'expédition, coffre posé).
## Clic gauche : prendre / poser ; clic droit : moitié / un seul. Clavier et manette : curseur.

var other: Array = []
var other_title: String = ""
var sellable: bool = false

var _grid_inv: SlotGrid
var _grid_other: SlotGrid
var _held: Dictionary = {}
var _held_view: Control
var _tip: PanelContainer
var _tip_label: Label
var _total: Label
var _cursor_grid: SlotGrid = null
var _cursor_idx: int = 0


func setup(p_other: Array = [], p_title: String = "", p_sell: bool = false) -> ContainerScreen:
	other = p_other
	other_title = p_title
	sellable = p_sell
	return self


func _ready() -> void:
	var panel: PanelContainer = PanelContainer.new()
	center(panel)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	panel.add_child(v)
	v.add_child(UIKit.label(Loc.t("INV_TITLE")))
	_grid_inv = _make_grid(GameState.inventory)
	v.add_child(_grid_inv)
	if not other.is_empty():
		var head: HBoxContainer = HBoxContainer.new()
		head.add_child(UIKit.label(other_title))
		_total = UIKit.label("")
		_total.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		head.add_child(_total)
		v.add_child(head)
		_grid_other = _make_grid(other)
		v.add_child(_grid_other)
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	var sort: Button = UIKit.button(Loc.t("INV_SORT"), 50)
	sort.pressed.connect(_on_sort)
	var close_b: Button = UIKit.button(Loc.t("COMMON_CLOSE"), 50)
	close_b.pressed.connect(func() -> void: close(null))
	if other.is_empty():
		var craft: Button = UIKit.button(Loc.t("CRAFT_TITLE"), 70)
		craft.pressed.connect(func() -> void:
			close(null)
			EventBus.ui_requested.emit("craft", {}))
		row.add_child(craft)
	row.add_child(sort)
	row.add_child(close_b)
	v.add_child(row)
	_held_view = Control.new()
	_held_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_held_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_held_view.draw.connect(_draw_held)
	add_child(_held_view)
	_tip = PanelContainer.new()
	_tip.visible = false
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_label = UIKit.label("")
	_tip.add_child(_tip_label)
	add_child(_tip)
	_update_total()
	AudioManager.sfx("ui_open")


func _make_grid(arr: Array) -> SlotGrid:
	var g: SlotGrid = SlotGrid.new()
	g.configure(arr, 0, arr.size(), 12)
	g.slot_pressed.connect(_on_pressed.bind(g, arr))
	g.slot_hovered.connect(_on_hover.bind(g, arr))
	return g


func _on_pressed(i: int, button: int, _g: SlotGrid, arr: Array) -> void:
	_click(arr, i, button)


func _click(arr: Array, i: int, button: int) -> void:
	var s: Variant = arr[i]
	if _held.is_empty():
		if s == null:
			return
		var take: int = int(s["n"])
		if button == MOUSE_BUTTON_RIGHT and take > 1:
			take = (take + 1) / 2
		_held = Inv.take(arr, i, take)
	elif button == MOUSE_BUTTON_RIGHT:
		var cap: int = Inv.max_stack(str(_held["id"]))
		if s == null:
			arr[i] = {"id": _held["id"], "n": 1, "q": _held["q"]}
			_held["n"] = int(_held["n"]) - 1
		elif s["id"] == _held["id"] and int(s["q"]) == int(_held["q"]) and int(s["n"]) < cap:
			s["n"] = int(s["n"]) + 1
			_held["n"] = int(_held["n"]) - 1
		if int(_held["n"]) <= 0:
			_held = {}
	else:
		if s == null:
			arr[i] = _held
			_held = {}
		elif s["id"] == _held["id"] and int(s["q"]) == int(_held["q"]):
			var cap2: int = Inv.max_stack(str(_held["id"]))
			var put: int = mini(int(_held["n"]), cap2 - int(s["n"]))
			s["n"] = int(s["n"]) + put
			_held["n"] = int(_held["n"]) - put
			if int(_held["n"]) <= 0:
				_held = {}
		else:
			arr[i] = _held
			_held = s
	AudioManager.sfx("ui_click", 0.03)
	EventBus.inventory_changed.emit()
	_update_total()
	_held_view.queue_redraw()


func _on_sort() -> void:
	Inv.sort(GameState.inventory, 0)
	AudioManager.sfx("ui_click")
	EventBus.inventory_changed.emit()


func _update_total() -> void:
	if _total == null:
		return
	var sum: int = 0
	if sellable:
		for s: Variant in other:
			sum += Economy.slot_value(s)
	_total.text = Loc.f("TIP_SELL", [sum]) if sellable else ""


func _on_hover(i: int, _g: SlotGrid, arr: Array) -> void:
	if i < 0 or i >= arr.size() or arr[i] == null:
		_tip.visible = false
		return
	var s: Dictionary = arr[i]
	var id: String = str(s["id"])
	var it: Dictionary = Database.item(id)
	var lines: PackedStringArray = [UIKit.stack_name(id, int(s["q"])), Loc.t("CAT_" + str(it.get("cat", "misc")).to_upper())]
	if it.has("tool"):
		lines.append(Loc.f("TIP_TOOL_LEVEL", [int(it.get("level", 1))]))
	if bool(it.get("desc", false)):
		lines.append(Database.item_desc(id))
	if it.has("energy"):
		lines.append(Loc.f("TIP_ENERGY", [int(it["energy"])]))
	if int(it.get("health", 0)) > 0:
		lines.append(Loc.f("TIP_HEALTH", [int(it["health"])]))
	if int(it.get("price", 0)) > 0:
		lines.append(Loc.f("TIP_SELL", [Economy.sell_value(id, int(s["q"]))]))
	_tip_label.text = "\n".join(lines)
	_tip.visible = true
	_tip.reset_size()
	_place_tip()


func _place_tip() -> void:
	var m: Vector2 = get_local_mouse_position() + Vector2(10, 10)
	m.x = minf(m.x, size.x - _tip.size.x - 2)
	m.y = minf(m.y, size.y - _tip.size.y - 2)
	_tip.position = m


func _process(_delta: float) -> void:
	if _tip.visible:
		_place_tip()
	if not _held.is_empty():
		_held_view.queue_redraw()


func _draw_held() -> void:
	if _held.is_empty():
		return
	var m: Vector2 = _held_view.get_local_mouse_position()
	var icon: Texture2D = Database.icon(str(_held["id"]))
	if icon != null:
		_held_view.draw_texture(icon, m - Vector2(8, 8))
	if int(_held["n"]) > 1:
		_held_view.draw_string(UIKit.font(), m + Vector2(2, 14), str(_held["n"]), HORIZONTAL_ALIGNMENT_LEFT, -1, UIKit.FONT_SIZE, Color.WHITE)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel") or event.is_action_pressed("inventory"):
		get_viewport().set_input_as_handled()
		close(null)
		return
	var dir: Vector2i = Vector2i.ZERO
	if event.is_action_pressed("move_left"):
		dir = Vector2i(-1, 0)
	elif event.is_action_pressed("move_right"):
		dir = Vector2i(1, 0)
	elif event.is_action_pressed("move_up"):
		dir = Vector2i(0, -1)
	elif event.is_action_pressed("move_down"):
		dir = Vector2i(0, 1)
	if dir != Vector2i.ZERO:
		get_viewport().set_input_as_handled()
		_move_cursor(dir)
	elif (event.is_action_pressed("action") or event.is_action_pressed("tool")) and _cursor_grid != null:
		get_viewport().set_input_as_handled()
		_click(_cursor_grid.slots, _cursor_idx, MOUSE_BUTTON_RIGHT if event.is_action_pressed("tool") else MOUSE_BUTTON_LEFT)


func _move_cursor(dir: Vector2i) -> void:
	if _cursor_grid == null:
		_cursor_grid = _grid_inv
		_cursor_idx = 0
	else:
		var cols: int = _cursor_grid.cols
		var x: int = _cursor_idx % cols + dir.x
		var y: int = _cursor_idx / cols + dir.y
		var rows: int = (_cursor_grid.count + cols - 1) / cols
		if y < 0 and _cursor_grid == _grid_other:
			_cursor_grid = _grid_inv
			y = (_grid_inv.count + cols - 1) / cols - 1
		elif y >= rows and _cursor_grid == _grid_inv and _grid_other != null:
			_cursor_grid = _grid_other
			y = 0
		x = posmod(x, cols)
		y = clampi(y, 0, (_cursor_grid.count + cols - 1) / cols - 1)
		_cursor_idx = mini(y * cols + x, _cursor_grid.count - 1)
	_grid_inv.cursor = _cursor_idx if _cursor_grid == _grid_inv else -1
	if _grid_other != null:
		_grid_other.cursor = _cursor_idx if _cursor_grid == _grid_other else -1
	_grid_inv.queue_redraw()
	if _grid_other != null:
		_grid_other.queue_redraw()
	AudioManager.sfx("ui_move", 0.0)
	_on_hover(_cursor_idx, _cursor_grid, _cursor_grid.slots)


func close(result: Variant = null) -> void:
	if not _held.is_empty():
		var left: int = Inv.add(GameState.inventory, str(_held["id"]), int(_held["n"]), int(_held["q"]))
		if left > 0 and not other.is_empty():
			left = Inv.add(other, str(_held["id"]), left, int(_held["q"]))
		if left > 0:
			EventBus.toast.emit(Loc.t("TOAST_INV_FULL"), str(_held["id"]))
		_held = {}
	EventBus.inventory_changed.emit()
	AudioManager.sfx("ui_close")
	super(result)
