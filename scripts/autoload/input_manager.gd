extends Node
## Actions d'entrée, dispositions clavier, remappage et détection du mode actif.

enum Mode { KEYBOARD, GAMEPAD, TOUCH }

const MOVE_ACTIONS: Array[String] = ["move_left", "move_right", "move_up", "move_down"]
const REMAPPABLE: Array[String] = [
	"move_up", "move_down", "move_left", "move_right", "action", "tool",
	"inventory", "journal", "map", "menu", "hotbar_prev", "hotbar_next",
]
const HOTBAR_SIZE: int = 12
const STICK_DEADZONE: float = 0.3

var mode: Mode = Mode.KEYBOARD
## Vecteur du joystick virtuel (rempli par l'UI tactile).
var virtual_move: Vector2 = Vector2.ZERO

var _hotbar_keys: Array[int] = [
	KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0, KEY_MINUS, KEY_EQUAL,
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if DisplayServer.is_touchscreen_available() and OS.has_feature("mobile"):
		mode = Mode.TOUCH
	rebuild_actions()


func rebuild_actions() -> void:
	for a: String in REMAPPABLE + ["cancel", "debug"]:
		_reset(a)
	var layout: String = Settings.key_layout
	# Déplacement : flèches toujours actives sauf si une autre disposition est imposée.
	var arrows: Array[int] = [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]
	for i: int in 4:
		_add_key(MOVE_ACTIONS[i], arrows[i], true)
	if layout == "auto":
		var phys: Array[int] = [KEY_A, KEY_D, KEY_W, KEY_S]
		for i: int in 4:
			_add_key(MOVE_ACTIONS[i], phys[i], true)
	elif layout == "wasd":
		var lab: Array[int] = [KEY_A, KEY_D, KEY_W, KEY_S]
		for i: int in 4:
			_add_key(MOVE_ACTIONS[i], lab[i], false)
	elif layout == "zqsd":
		var lab2: Array[int] = [KEY_Q, KEY_D, KEY_Z, KEY_S]
		for i: int in 4:
			_add_key(MOVE_ACTIONS[i], lab2[i], false)
	var axes: Array = [[JOY_AXIS_LEFT_X, -1.0], [JOY_AXIS_LEFT_X, 1.0], [JOY_AXIS_LEFT_Y, -1.0], [JOY_AXIS_LEFT_Y, 1.0]]
	var dpad: Array[int] = [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN]
	for i: int in 4:
		var m: InputEventJoypadMotion = InputEventJoypadMotion.new()
		m.axis = axes[i][0]
		m.axis_value = axes[i][1]
		InputMap.action_add_event(MOVE_ACTIONS[i], m)
		_add_joy(MOVE_ACTIONS[i], dpad[i])

	_add_key("action", KEY_E, true)
	_add_key("action", KEY_SPACE, true)
	_add_joy("action", JOY_BUTTON_A)
	_add_key("tool", KEY_F, true)
	_add_key("tool", KEY_C, true)
	_add_joy("tool", JOY_BUTTON_X)
	_add_key("inventory", KEY_TAB, true)
	_add_key("inventory", KEY_I, true)
	_add_joy("inventory", JOY_BUTTON_Y)
	_add_key("journal", KEY_J, true)
	_add_joy("journal", JOY_BUTTON_BACK)
	_add_key("map", KEY_M, false)
	_add_key("menu", KEY_ESCAPE, true)
	_add_joy("menu", JOY_BUTTON_START)
	_add_key("cancel", KEY_ESCAPE, true)
	_add_joy("cancel", JOY_BUTTON_B)
	_add_key("hotbar_prev", KEY_PAGEUP, true)
	_add_joy("hotbar_prev", JOY_BUTTON_LEFT_SHOULDER)
	_add_key("hotbar_next", KEY_PAGEDOWN, true)
	_add_joy("hotbar_next", JOY_BUTTON_RIGHT_SHOULDER)
	_add_key("debug", KEY_F3, true)
	for i: int in HOTBAR_SIZE:
		var a: String = "hotbar_%d" % (i + 1)
		_reset(a)
		_add_key(a, _hotbar_keys[i], true)

	# Remappages personnalisés : remplacent les touches clavier de l'action.
	for a: String in Settings.bindings.keys():
		if not InputMap.has_action(a):
			continue
		var b: Dictionary = Settings.bindings[a]
		_clear_keys(a)
		_add_key(a, int(b.get("key", 0)), bool(b.get("physical", true)))


func _reset(action: String) -> void:
	if InputMap.has_action(action):
		InputMap.action_erase_events(action)
	else:
		InputMap.add_action(action, STICK_DEADZONE)


func _add_key(action: String, key: int, physical: bool) -> void:
	if key == 0:
		return
	var ev: InputEventKey = InputEventKey.new()
	if physical:
		ev.physical_keycode = key as Key
	else:
		ev.keycode = key as Key
	InputMap.action_add_event(action, ev)


func _add_joy(action: String, button: int) -> void:
	var ev: InputEventJoypadButton = InputEventJoypadButton.new()
	ev.button_index = button as JoyButton
	InputMap.action_add_event(action, ev)


func _clear_keys(action: String) -> void:
	for ev: InputEvent in InputMap.action_get_events(action):
		if ev is InputEventKey:
			InputMap.action_erase_event(action, ev)


## Remappe une action sur une touche (physique) et sauvegarde.
func rebind(action: String, event: InputEventKey) -> void:
	var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	Settings.bindings[action] = {"key": key, "physical": event.physical_keycode != 0}
	Settings.save_settings()
	rebuild_actions()


func reset_bindings() -> void:
	Settings.bindings = {}
	Settings.save_settings()
	rebuild_actions()


## Nom lisible de la première touche clavier (ou du bouton manette) d'une action.
func action_label(action: String) -> String:
	if not InputMap.has_action(action):
		return ""
	for ev: InputEvent in InputMap.action_get_events(action):
		if mode == Mode.GAMEPAD and ev is InputEventJoypadButton:
			return "B%d" % (ev as InputEventJoypadButton).button_index
		if mode != Mode.GAMEPAD and ev is InputEventKey:
			var k: InputEventKey = ev
			if k.physical_keycode != 0:
				return OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(k.physical_keycode))
			return OS.get_keycode_string(k.keycode)
	return ""


func _input(event: InputEvent) -> void:
	var new_mode: Mode = mode
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		new_mode = Mode.TOUCH
	elif event is InputEventKey:
		new_mode = Mode.KEYBOARD
	elif event is InputEventMouseButton:
		# Sur mobile, le tactile émule la souris : ne pas quitter le mode tactile.
		if not (mode == Mode.TOUCH and DisplayServer.is_touchscreen_available()):
			new_mode = Mode.KEYBOARD
	elif event is InputEventJoypadButton:
		new_mode = Mode.GAMEPAD
	elif event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5:
		new_mode = Mode.GAMEPAD
	if new_mode != mode:
		mode = new_mode
		EventBus.input_mode_changed.emit(mode)


func touch_ui_visible() -> bool:
	match Settings.touch_mode:
		"on":
			return true
		"off":
			return false
	return mode == Mode.TOUCH


func move_vector() -> Vector2:
	var v: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if virtual_move.length_squared() > v.length_squared():
		v = virtual_move
	return v.limit_length(1.0)
