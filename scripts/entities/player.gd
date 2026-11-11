class_name Player
extends Node2D
## Le joueur : déplacement 8 directions sur grille de collisions, animations, charge d'outil.

signal cell_changed(cell: Vector2i)
signal tool_released(hold_time: float)
signal action_pressed()

const FACING_VEC: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]
const HALF_W: float = 4.0
const BOX_H: float = 5.0
const COLS: int = 15
const WALK_FPS: float = 8.0
const STEP_INTERVAL: float = 0.27
const SWING_FRAMES: Array[int] = [5, 6, 7]
const MOVE_EPS: float = 0.1

var rt: MapRuntime
var facing: int = 0
var blocked: bool = false
var sprite: Sprite2D
var _anim_t: float = 0.0
var _swing_left: float = 0.0
var _swing_total: float = 0.0
var _step_t: float = 0.0
var _cell: Vector2i = Vector2i(-999, -999)
var _hold: float = 0.0
var _holding: bool = false
var _charged_fx: bool = false


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.hframes = COLS
	sprite.vframes = 4
	sprite.offset = Vector2(0, -11)
	add_child(sprite)
	set_outfit(GameState.outfit)
	_update_frame(0, false)


func set_outfit(i: int) -> void:
	sprite.texture = Database.sheet("sprites/chars/player_%d" % clampi(i, 0, 2))


func feet_cell() -> Vector2i:
	return MapRuntime.cell_of_pixel(position + Vector2(0, -2))


func target_cell() -> Vector2i:
	return feet_cell() + FACING_VEC[facing]


func face_cell(c: Vector2i) -> void:
	var d: Vector2i = c - feet_cell()
	if absi(d.x) > absi(d.y):
		facing = 2 if d.x > 0 else 3
	elif d.y != 0:
		facing = 0 if d.y > 0 else 1


func swing(duration: float) -> void:
	_swing_total = duration
	_swing_left = duration


func is_swinging() -> bool:
	return _swing_left > 0.0


func hold_ratio() -> float:
	return _hold


func _blocked_at(p: Vector2) -> bool:
	if rt == null:
		return true
	var x0: int = int(floorf((p.x - HALF_W) / MapRuntime.T))
	var x1: int = int(floorf((p.x + HALF_W - 0.01) / MapRuntime.T))
	var y0: int = int(floorf((p.y - BOX_H) / MapRuntime.T))
	var y1: int = int(floorf((p.y - 0.01) / MapRuntime.T))
	for y: int in range(y0, y1 + 1):
		for x: int in range(x0, x1 + 1):
			if rt.is_solid(Vector2i(x, y)):
				return true
	return false


func _speed() -> float:
	var s: float = Database.bal_f("player_speed", 62.0) + GameState.buff_total("speed") * Database.bal_f("player_speed_buff", 8.0)
	if GameState.energy < Database.bal_f("low_energy_threshold", 12.0):
		s *= Database.bal_f("exhausted_speed_mult", 0.6)
	return s


func _process(delta: float) -> void:
	if _swing_left > 0.0:
		_swing_left = maxf(0.0, _swing_left - delta)
	if blocked:
		_holding = false
		_hold = 0.0
		_update_frame(0, false)
		return
	_handle_tool_key(delta)
	if Input.is_action_just_pressed("action"):
		action_pressed.emit()
	var v: Vector2 = InputManager.move_vector() if _swing_left <= 0.0 else Vector2.ZERO
	var moving: bool = v.length() > MOVE_EPS
	if moving:
		if absf(v.x) > absf(v.y) + 0.05:
			facing = 2 if v.x > 0 else 3
		elif absf(v.y) > 0.05:
			facing = 0 if v.y > 0 else 1
		var step: Vector2 = v * _speed() * delta
		if not _blocked_at(position + Vector2(step.x, 0)):
			position.x += step.x
		if not _blocked_at(position + Vector2(0, step.y)):
			position.y += step.y
		_anim_t += delta
		_step_t += delta
		if _step_t >= STEP_INTERVAL:
			_step_t = 0.0
			_footstep()
	else:
		_anim_t = 0.0
		_step_t = STEP_INTERVAL * 0.6
	var c: Vector2i = feet_cell()
	if c != _cell:
		_cell = c
		cell_changed.emit(c)
	_update_frame(int(_anim_t * WALK_FPS) % 4, moving)


func _handle_tool_key(delta: float) -> void:
	if Input.is_action_just_pressed("tool"):
		_holding = true
		_hold = 0.0
		_charged_fx = false
	if _holding and Input.is_action_pressed("tool"):
		_hold += delta
		var held: String = GameState.held_id()
		if not _charged_fx and _hold >= Database.bal_f("charge_time", 0.45) and ToolUse.can_charge(held):
			_charged_fx = true
			AudioManager.sfx("ui_move", 0.0)
			modulate = Color(1.4, 1.4, 1.1)
			create_tween().tween_property(self, "modulate", Color.WHITE, 0.25)
	elif _holding:
		_holding = false
		tool_released.emit(_hold)
		_hold = 0.0


func _footstep() -> void:
	var tid: String = rt.terrain_id(feet_cell())
	var sfx: String = "step_grass"
	match tid:
		"wood", "floor":
			sfx = "step_wood"
		"cobble", "cliff", "mine_floor_1", "mine_floor_2", "mine_floor_3":
			sfx = "step_stone"
		"dirt", "sand", "path":
			sfx = "step_dirt"
		"grass":
			sfx = "step_snow" if TimeManager.season_id() == "winter" else "step_grass"
	AudioManager.sfx(sfx, 0.08, -9.0)


func _update_frame(walk_phase: int, moving: bool) -> void:
	var col: int = 0
	if _swing_left > 0.0:
		var p: float = 1.0 - _swing_left / maxf(_swing_total, 0.001)
		col = SWING_FRAMES[mini(int(p * SWING_FRAMES.size()), SWING_FRAMES.size() - 1)]
	elif moving:
		col = 1 + walk_phase
	sprite.frame = facing * COLS + col
