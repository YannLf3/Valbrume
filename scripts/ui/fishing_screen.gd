class_name FishingScreen
extends ScreenBase
## Écran du mini-jeu de pêche « Ondes ». Dessin de l'anneau, de la bille et de l'arc ; la logique est dans FishingGame.

const RING_R: float = 40.0
const END_DELAY: float = 1.0

var fish_id: String = ""
var rod_level: int = 1
var bait: bool = false
var game: FishingGame

var _canvas: Control
var _end_t: float = -1.0
var _result: Dictionary = {}
var _t: float = 0.0


func _init() -> void:
	super()
	cancelable = false


func setup(p_fish: String, p_rod: int, p_bait: bool) -> FishingScreen:
	fish_id = p_fish
	rod_level = p_rod
	bait = p_bait
	game = FishingGame.new(fish_id, rod_level, bait, Fishing.rng)
	return self


func _ready() -> void:
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_game)
	add_child(_canvas)


func _process(delta: float) -> void:
	_t += delta
	if _end_t >= 0.0:
		_end_t -= delta
		if _end_t <= 0.0:
			close(_result)
		_canvas.queue_redraw()
		return
	var ev: String = game.update(delta)
	_react(ev)
	_check_end(ev)
	_canvas.queue_redraw()


func _react(ev: String) -> void:
	match ev:
		"bite":
			AudioManager.sfx("bite")
		"hook":
			AudioManager.sfx("splash")
		"hit":
			AudioManager.sfx("fish_beat")
		"perfect":
			AudioManager.sfx("fish_perfect")
		"miss", "escaped", "early":
			AudioManager.sfx("fish_miss")
		"lose":
			AudioManager.sfx("line_snap")


func _check_end(ev: String) -> void:
	if game.state == FishingGame.State.WON:
		_result = {"caught": true, "fish": fish_id, "q": game.quality(), "treasure": game.treasure}
		_end_t = END_DELAY
	elif game.state == FishingGame.State.LOST:
		_result = {"caught": false, "reason": ev}
		_end_t = END_DELAY


func _input(event: InputEvent) -> void:
	var pressed: bool = event.is_action_pressed("action") or event.is_action_pressed("tool") \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	if pressed:
		get_viewport().set_input_as_handled()
		if _end_t < 0.0:
			var ev: String = game.press()
			_react(ev)
			_check_end(ev)
		return
	if event.is_action_pressed("cancel") and game.state == FishingGame.State.WAIT and _end_t < 0.0:
		get_viewport().set_input_as_handled()
		_result = {"caught": false, "reason": "cancel"}
		close(_result)


func _hint() -> String:
	if _end_t >= 0.0:
		if bool(_result.get("caught", false)):
			return Loc.t("FISH_WON")
		return Loc.t({"lose": "FISH_LOST", "escaped": "FISH_ESCAPED", "nothing": "FISH_NOTHING", "early": "FISH_ESCAPED"}.get(str(_result.get("reason", "")), "FISH_ESCAPED"))
	match game.state:
		FishingGame.State.WAIT:
			return Loc.t("FISH_WAIT")
		FishingGame.State.BITE:
			return Loc.t("FISH_BITE")
	return Loc.t("FISH_PRESS")


func _draw_game() -> void:
	var vs: Vector2 = get_viewport_rect().size
	var panel_rect: Rect2 = Rect2(vs / 2.0 - Vector2(110, 84), Vector2(220, 168))
	_canvas.draw_style_box(UIKit.box("panel_dark", 5), panel_rect)
	var c: Vector2 = vs / 2.0 + Vector2(0, -6)
	var f: Font = UIKit.font()
	_canvas.draw_arc(c, RING_R, 0.0, TAU, 64, Color("453a4f"), 7.0)
	_canvas.draw_arc(c, RING_R, 0.0, TAU, 64, Color("2b2233"), 1.0)
	if game.state == FishingGame.State.FIGHT or game.state == FishingGame.State.WON:
		var a0: float = game.arc_center - game.arc_half
		_canvas.draw_arc(c, RING_R, a0, a0 + game.arc_half * 2.0, 24, Color("f0ae3f"), 7.0)
		_canvas.draw_arc(c, RING_R, game.arc_center - game.arc_half * Database.bal_f("fish_perfect_ratio", 0.38),
			game.arc_center + game.arc_half * Database.bal_f("fish_perfect_ratio", 0.38), 8, Color("f7dc6a"), 7.0)
		var mp: Vector2 = c + Vector2.from_angle(game.angle) * RING_R
		_canvas.draw_circle(mp, 5.0, Color("2b2233"))
		_canvas.draw_circle(mp, 3.5, Color("fbf7ec"))
	elif game.state == FishingGame.State.BITE:
		var pulse: float = 0.5 + 0.5 * sin(_t * 18.0)
		_canvas.draw_arc(c, RING_R, 0.0, TAU, 64, Color(0.97, 0.86, 0.42, pulse), 7.0)
		_canvas.draw_string(f, c + Vector2(-3, 8), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, UIKit.FONT_BIG_SIZE, Color("c8413f"))
	else:
		for i: int in 3:
			var rr: float = fmod(_t * 14.0 + i * 12.0, 36.0)
			_canvas.draw_arc(c, rr, 0.0, TAU, 32, Color(0.64, 0.85, 0.91, 1.0 - rr / 36.0), 1.0)
	if _end_t >= 0.0 and bool(_result.get("caught", false)):
		var icon: Texture2D = Database.icon(fish_id)
		if icon != null:
			_canvas.draw_texture_rect(icon, Rect2(c - Vector2(12, 12), Vector2(24, 24)), false)
	# progression et ratés
	if game.state == FishingGame.State.FIGHT or game.state == FishingGame.State.WON:
		for i: int in game.beats_total:
			_canvas.draw_circle(c + Vector2((i - (game.beats_total - 1) / 2.0) * 10.0, RING_R + 16.0), 3.0, Color("f0ae3f") if i < game.progress else Color("453a4f"))
		for i: int in Database.bal_i("fish_misses_allowed", 3):
			_canvas.draw_texture(Database.sprite("heart_full" if i >= game.misses else "heart_empty"), c + Vector2(-RING_R - 22.0, -RING_R + i * 10.0))
	var hint: String = _hint()
	var w: float = f.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, UIKit.FONT_SIZE).x
	_canvas.draw_string(f, Vector2(vs.x / 2.0 - w / 2.0, panel_rect.end.y - 9), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, UIKit.FONT_SIZE, Color("f4e8c8"))
