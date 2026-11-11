class_name DialogScreen
extends ScreenBase
## Boîte de dialogue : portrait, nom, texte défilant lettre par lettre (passable), choix multiples.

const CHARS_PER_SECOND: float = 48.0
const PANEL_HEIGHT: int = 72

var lines: Array = []
var speaker: String = ""
var portrait: String = ""
var expression: int = 0
var choices: Array = []

var _label: Label
var _name: Label
var _buttons: HBoxContainer
var _idx: int = 0
var _t: float = 0.0
var _last_blip: int = 0
var _done_typing: bool = false


func _init() -> void:
	super()
	cancelable = false
	dim = false


func setup(p_lines: Array, p_speaker: String = "", p_portrait: String = "", p_expression: int = 0, p_choices: Array = []) -> DialogScreen:
	lines = p_lines
	speaker = p_speaker
	portrait = p_portrait
	expression = p_expression
	choices = p_choices
	return self


func _ready() -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_left = 20
	panel.offset_right = -20
	panel.offset_bottom = -6
	panel.custom_minimum_size = Vector2(0, PANEL_HEIGHT)
	add_child(panel)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	if portrait != "":
		var tex: Texture2D = Database.sheet("sprites/chars/portrait_" + portrait)
		if tex != null:
			var at: AtlasTexture = AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(expression * 48, 0, 48, 48)
			row.add_child(UIKit.icon_rect(at, Vector2(48, 48)))
	var col: VBoxContainer = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	if speaker != "":
		_name = UIKit.label(speaker, Color("a8432e"))
		col.add_child(_name)
	_label = UIKit.label("")
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_label.custom_minimum_size = Vector2(0, 28)
	col.add_child(_label)
	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(_buttons)
	_show_line()


func _show_line() -> void:
	_label.text = str(lines[_idx]).replace("{player}", GameState.player_name).replace("{farm}", GameState.farm_name)
	_label.visible_characters = 0
	_t = 0.0
	_last_blip = 0
	_done_typing = false


func _process(delta: float) -> void:
	if _done_typing:
		return
	_t += delta * CHARS_PER_SECOND
	var n: int = int(_t)
	_label.visible_characters = n
	if n - _last_blip >= 3:
		_last_blip = n
		AudioManager.sfx("text_blip", 0.1, -8.0)
	if n >= _label.text.length():
		_finish_typing()


func _finish_typing() -> void:
	_done_typing = true
	_label.visible_characters = -1
	if _idx == lines.size() - 1 and not choices.is_empty():
		for i: int in choices.size():
			var b: Button = UIKit.button(str(choices[i]))
			b.pressed.connect(close.bind(i))
			_buttons.add_child(b)
		(_buttons.get_child(0) as Button).grab_focus()


func _advance() -> void:
	if not _done_typing:
		_finish_typing()
		return
	if _idx == lines.size() - 1:
		if choices.is_empty():
			close(0)
		return
	_idx += 1
	_show_line()


func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("action") or event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)):
		if _done_typing and _idx == lines.size() - 1 and not choices.is_empty():
			return  # les boutons gèrent le choix
		get_viewport().set_input_as_handled()
		_advance()
