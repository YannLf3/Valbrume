class_name UIKit
extends RefCounted
## Thème pixel du jeu (police bitmap, panneaux 9-slice, boutons) et fabriques de contrôles.

const INK: Color = Color("2b2233")
const BARK_D: Color = Color("4a3228")
const CREAM: Color = Color("f4e8c8")
const STONE: Color = Color("7c8394")
const AMBER: Color = Color("f0ae3f")
const RED: Color = Color("c8413f")
const LEAF: Color = Color("4c9a4f")
const FONT_PATH: String = "res://assets/fonts/valbrume.fnt"
const FONT_BIG_PATH: String = "res://assets/fonts/valbrume_big.fnt"
const FONT_SIZE: int = 12
const FONT_BIG_SIZE: int = 24

static var _theme: Theme = null
static var _font: Font = null
static var _font_big: Font = null


static func font() -> Font:
	if _font == null:
		_font = load(FONT_PATH)
	return _font


static func font_big() -> Font:
	if _font_big == null:
		_font_big = load(FONT_BIG_PATH)
	return _font_big


static func box(sprite_name: String, margin: int, pad_h: int = -1, pad_top: int = -1, pad_bottom: int = -1) -> StyleBoxTexture:
	var sb: StyleBoxTexture = StyleBoxTexture.new()
	sb.texture = Database.sprite(sprite_name)
	sb.texture_margin_left = margin
	sb.texture_margin_right = margin
	sb.texture_margin_top = margin
	sb.texture_margin_bottom = margin
	sb.content_margin_left = margin + 2 if pad_h < 0 else pad_h
	sb.content_margin_right = margin + 2 if pad_h < 0 else pad_h
	sb.content_margin_top = margin + 1 if pad_top < 0 else pad_top
	sb.content_margin_bottom = margin + 1 if pad_bottom < 0 else pad_bottom
	return sb


static func _flat(col: Color, h: int = 0) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = col
	if h > 0:
		sb.content_margin_top = h / 2.0
		sb.content_margin_bottom = h / 2.0
	return sb


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t: Theme = Theme.new()
	t.default_font = font()
	t.default_font_size = FONT_SIZE
	t.set_color("font_color", "Label", INK)
	t.set_constant("line_spacing", "Label", 1)
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var sprite: String = {"normal": "button_normal", "hover": "button_hover", "pressed": "button_pressed",
			"disabled": "button_disabled", "focus": "button_hover"}[state]
		t.set_stylebox(state, "Button", box(sprite, 5, 8, 3, 5))
	t.set_color("font_color", "Button", BARK_D)
	t.set_color("font_hover_color", "Button", INK)
	t.set_color("font_focus_color", "Button", INK)
	t.set_color("font_pressed_color", "Button", INK)
	t.set_color("font_disabled_color", "Button", STONE)
	t.set_stylebox("panel", "PanelContainer", box("panel", 5))
	t.set_stylebox("panel", "Panel", box("panel", 5))
	for state2: String in ["normal", "focus", "read_only"]:
		t.set_stylebox(state2, "LineEdit", box("panel_inset", 4, 5, 3, 3))
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("caret_color", "LineEdit", BARK_D)
	t.set_color("selection_color", "LineEdit", Color(AMBER, 0.6))
	t.set_stylebox("slider", "HSlider", _flat(BARK_D, 4))
	t.set_stylebox("grabber_area", "HSlider", _flat(AMBER, 4))
	t.set_stylebox("grabber_area_highlight", "HSlider", _flat(AMBER, 4))
	t.set_icon("grabber", "HSlider", Database.sprite("g_knob"))
	t.set_icon("grabber_highlight", "HSlider", Database.sprite("g_knob"))
	t.set_icon("grabber_disabled", "HSlider", Database.sprite("g_knob"))
	t.set_icon("checked", "CheckBox", Database.sprite("g_check_on"))
	t.set_icon("unchecked", "CheckBox", Database.sprite("g_check_off"))
	t.set_color("font_color", "CheckBox", INK)
	t.set_color("font_hover_color", "CheckBox", INK)
	t.set_color("font_pressed_color", "CheckBox", INK)
	t.set_stylebox("scroll", "VScrollBar", _flat(Color(BARK_D, 0.35)))
	t.set_stylebox("grabber", "VScrollBar", _flat(BARK_D))
	t.set_stylebox("grabber_highlight", "VScrollBar", _flat(BARK_D))
	t.set_stylebox("grabber_pressed", "VScrollBar", _flat(INK))
	_theme = t
	return t


static func label(text: String, color: Color = INK, big: bool = false) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	if big:
		l.add_theme_font_override("font", font_big())
		l.add_theme_font_size_override("font_size", FONT_BIG_SIZE)
	return l


static func button(text: String, min_width: int = 0) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, 18)
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(func() -> void: AudioManager.sfx("ui_click", 0.02))
	return b


static func icon_rect(tex: Texture2D, size: Vector2 = Vector2(16, 16)) -> TextureRect:
	var r: TextureRect = TextureRect.new()
	r.texture = tex
	r.custom_minimum_size = size
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func spacer(h: int) -> Control:
	var c: Control = Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


## Nom d'un objet avec qualité et pile, pour les infobulles et listes.
static func stack_name(id: String, q: int) -> String:
	var n: String = Database.item_name(id)
	if q > 0:
		n += " (%s)" % Loc.t("QUALITY_%d" % q)
	return n
