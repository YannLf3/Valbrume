class_name Npc
extends Node2D
## Un habitant : sprite animé, marche le long d'un chemin A*, s'arrête face au joueur pour parler.

signal arrived()

const WALK_SPEED: float = 36.0
const COLS: int = 5
const WALK_FPS: float = 6.0

var npc_id: String = ""
var sprite: Sprite2D
var facing: int = 0
var path: Array[Vector2i] = []
var leaving: bool = false
var talking: bool = false
var _anim_t: float = 0.0


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = Database.sheet("sprites/chars/npc_" + npc_id)
	sprite.hframes = COLS
	sprite.vframes = 4
	sprite.offset = Vector2(0, -11)
	add_child(sprite)
	_update_frame(false)


func cell() -> Vector2i:
	return MapRuntime.cell_of_pixel(position + Vector2(0, -2))


func place(c: Vector2i) -> void:
	position = MapRuntime.foot_pixel(c)
	path.clear()


func walk(p: Array[Vector2i]) -> void:
	path = p.duplicate()
	if not path.is_empty() and path[0] == cell():
		path.remove_at(0)


func face_toward(pos: Vector2) -> void:
	var d: Vector2 = pos - position
	if absf(d.x) > absf(d.y):
		facing = 2 if d.x > 0 else 3
	else:
		facing = 0 if d.y > 0 else 1


func _process(delta: float) -> void:
	if talking:
		_update_frame(false)
		return
	var moving: bool = false
	if not path.is_empty():
		var target: Vector2 = MapRuntime.foot_pixel(path[0])
		var d: Vector2 = target - position
		var step: float = WALK_SPEED * delta
		if d.length() <= step:
			position = target
			path.remove_at(0)
			if path.is_empty():
				arrived.emit()
		else:
			position += d.normalized() * step
			if absf(d.x) > absf(d.y):
				facing = 2 if d.x > 0 else 3
			else:
				facing = 0 if d.y > 0 else 1
		moving = true
	_anim_t = _anim_t + delta if moving else 0.0
	_update_frame(moving)


func _update_frame(moving: bool) -> void:
	var col: int = 1 + int(_anim_t * WALK_FPS) % 4 if moving else 0
	sprite.frame = facing * COLS + col
