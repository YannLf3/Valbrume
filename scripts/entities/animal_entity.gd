class_name AnimalEntity
extends Node2D
## Un animal de la ferme ou le chien : erre au hasard dans son enclos le long de chemins A*.

const COLS: int = 4
const SPEED: float = 14.0
const WALK_FPS: float = 5.0

var animal: Dictionary = {}       # entrée de GameState.animals (vide pour le chien)
var kind: String = "chicken"
var baby: bool = false
var pen: Rect2i = Rect2i()
var nav: GridNav
var sprite: Sprite2D
var path: Array[Vector2i] = []
var _wait: float = 0.0
var _anim_t: float = 0.0
var _eating: float = 0.0


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = Database.sheet("sprites/creatures/animal_" + kind)
	sprite.hframes = COLS
	sprite.vframes = 2
	sprite.offset = Vector2(0, -9)
	add_child(sprite)
	_wait = WorldObjects.rng.randf_range(0.2, 2.5)
	_update_frame(false)


func cell() -> Vector2i:
	return MapRuntime.cell_of_pixel(position + Vector2(0, -2))


func place(c: Vector2i) -> void:
	position = MapRuntime.foot_pixel(c)


func _process(delta: float) -> void:
	if _eating > 0.0:
		_eating -= delta
		_update_frame(false, true)
		return
	var moving: bool = false
	if not path.is_empty():
		var target: Vector2 = MapRuntime.foot_pixel(path[0])
		var d: Vector2 = target - position
		var step: float = SPEED * delta
		if d.length() <= step:
			position = target
			path.remove_at(0)
		else:
			position += d.normalized() * step
			if absf(d.x) > 0.1:
				sprite.flip_h = d.x < 0.0
		moving = true
	else:
		_wait -= delta
		if _wait <= 0.0:
			_wait = WorldObjects.rng.randf_range(1.5, 5.0)
			if WorldObjects.rng.randf() < 0.3:
				_eating = 1.6
			elif nav != null and pen.size.x > 0:
				var t: Vector2i = Vector2i(WorldObjects.rng.randi_range(pen.position.x, pen.end.x), WorldObjects.rng.randi_range(pen.position.y, pen.end.y))
				var p: Array[Vector2i] = nav.path(cell(), t)
				if p.size() > 1:
					p.remove_at(0)
					path = p
	_anim_t = _anim_t + delta if moving else 0.0
	_update_frame(moving)


func _update_frame(moving: bool, eating: bool = false) -> void:
	var col: int = 3 if eating else (1 + int(_anim_t * WALK_FPS) % 2 if moving else 0)
	sprite.frame = (1 if baby else 0) * COLS + col
