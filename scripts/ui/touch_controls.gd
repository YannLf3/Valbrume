class_name TouchControls
extends CanvasLayer
## Commandes tactiles : joystick flottant à gauche, boutons Action / Outil / Sac / Menu à droite.
## N'apparaît que sur écran tactile (ou si l'option le force). Zones de toucher agrandies selon l'échelle d'interface.

const BUTTON_SIZE: float = 36.0
const JOY_RADIUS: float = 26.0
const JOY_ZONE: Vector2 = Vector2(0.32, 0.55)   # part gauche / basse de l'écran où naît le joystick

var _root: Control
var _joy_base: TextureRect
var _joy_knob: TextureRect
var _joy_id: int = -1
var _joy_origin: Vector2 = Vector2.ZERO
var _buttons: Dictionary = {}       # action -> TextureRect
var _finger_btn: Dictionary = {}    # index de doigt -> action
var _scale: float = 1.0


func _ready() -> void:
	layer = 12
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	for entry: Array in [["action", "touch_action"], ["tool", "touch_tool"], ["inventory", "touch_bag"], ["menu", "touch_menu"]]:
		var b: TextureRect = TextureRect.new()
		b.texture = Database.sprite(str(entry[1]))
		b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.modulate = Color(1, 1, 1, 0.85)
		_root.add_child(b)
		_buttons[str(entry[0])] = b
	_joy_base = _make_joy("joy_base")
	_joy_knob = _make_joy("joy_knob")
	EventBus.input_mode_changed.connect(func(_m: int) -> void: refresh())
	EventBus.settings_changed.connect(refresh)
	get_viewport().size_changed.connect(layout)
	refresh()


func _make_joy(sprite_name: String) -> TextureRect:
	var t: TextureRect = TextureRect.new()
	t.texture = Database.sprite(sprite_name)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.modulate = Color(1, 1, 1, 0.7)
	t.visible = false
	_root.add_child(t)
	return t


func refresh() -> void:
	var on: bool = InputManager.touch_ui_visible()
	_root.visible = on
	if not on:
		_release_all()
	layout()


## Place les boutons selon la taille de l'écran, les zones sûres (encoche, barre de navigation) et l'échelle.
func layout() -> void:
	_scale = clampf(Settings.ui_scale, 1.0, 2.0)
	var vs: Vector2 = get_viewport().get_visible_rect().size
	var inset: Rect2 = safe_inset(vs)
	var s: float = BUTTON_SIZE * _scale
	var right: float = vs.x - inset.size.x - 8.0
	var bottom: float = vs.y - inset.size.y - 8.0
	var left: float = inset.position.x + 8.0
	var top: float = inset.position.y + 8.0
	_place("action", Vector2(right - s * 1.15, bottom - s * 1.15), s * 1.15)
	_place("tool", Vector2(right - s * 2.3, bottom - s * 0.8), s)
	_place("inventory", Vector2(right - s * 0.95, bottom - s * 2.45), s * 0.8)
	_place("menu", Vector2(left, top), s * 0.8)


func _place(action: String, pos: Vector2, size: float) -> void:
	var b: TextureRect = _buttons[action]
	b.position = pos
	b.size = Vector2(size, size)


## Marges (gauche, haut, droite, bas) en unités de canvas, issues de la zone d'affichage sûre. Nulles hors mobile.
static func safe_inset(vs: Vector2) -> Rect2:
	if not OS.has_feature("mobile"):
		return Rect2()
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var win: Vector2i = DisplayServer.window_get_size()
	if win.x <= 0 or win.y <= 0 or safe.size.x <= 0:
		return Rect2()
	var k: float = vs.x / float(win.x)
	return Rect2(safe.position.x * k, safe.position.y * k, maxf(0.0, (win.x - safe.end.x) * k), maxf(0.0, (win.y - safe.end.y) * k))


func covers(pos: Vector2) -> bool:
	if not _root.visible:
		return false
	for b: TextureRect in _buttons.values():
		if Rect2(b.position, b.size).has_point(pos):
			return true
	var vs: Vector2 = get_viewport().get_visible_rect().size
	return pos.x < vs.x * JOY_ZONE.x and pos.y > vs.y * (1.0 - JOY_ZONE.y)


func _input(event: InputEvent) -> void:
	if not _root.visible:
		return
	if event is InputEventScreenTouch:
		var t: InputEventScreenTouch = event
		if t.pressed:
			_touch_down(t.index, t.position)
		else:
			_touch_up(t.index)
	elif event is InputEventScreenDrag:
		var d: InputEventScreenDrag = event
		if d.index == _joy_id:
			var v: Vector2 = (d.position - _joy_origin).limit_length(JOY_RADIUS * _scale)
			_joy_knob.position = _joy_origin + v - _joy_knob.size / 2.0
			InputManager.virtual_move = v / (JOY_RADIUS * _scale)


func _touch_down(index: int, pos: Vector2) -> void:
	for action: String in _buttons:
		var b: TextureRect = _buttons[action]
		if Rect2(b.position, b.size).has_point(pos):
			_finger_btn[index] = action
			_send(action, true)
			b.modulate = Color(1.3, 1.3, 1.3, 1.0)
			get_viewport().set_input_as_handled()
			return
	var vs: Vector2 = get_viewport().get_visible_rect().size
	if _joy_id == -1 and pos.x < vs.x * JOY_ZONE.x and pos.y > vs.y * (1.0 - JOY_ZONE.y):
		_joy_id = index
		_joy_origin = pos
		_joy_base.size = Vector2(56, 56) * _scale
		_joy_knob.size = Vector2(26, 26) * _scale
		_joy_base.position = pos - _joy_base.size / 2.0
		_joy_knob.position = pos - _joy_knob.size / 2.0
		_joy_base.visible = true
		_joy_knob.visible = true
		get_viewport().set_input_as_handled()


func _touch_up(index: int) -> void:
	if _finger_btn.has(index):
		var action: String = _finger_btn[index]
		_send(action, false)
		(_buttons[action] as TextureRect).modulate = Color(1, 1, 1, 0.85)
		_finger_btn.erase(index)
	if index == _joy_id:
		_joy_id = -1
		_joy_base.visible = false
		_joy_knob.visible = false
		InputManager.virtual_move = Vector2.ZERO


## Les boutons envoient de vrais événements d'action (menus et inventaire réagissent aux événements).
func _send(action: String, pressed: bool) -> void:
	var ev: InputEventAction = InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _release_all() -> void:
	for index: int in _finger_btn.keys():
		_touch_up(index)
	_touch_up(_joy_id)
	InputManager.virtual_move = Vector2.ZERO
