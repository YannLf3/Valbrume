class_name MonsterEntity
extends Node2D
## Un monstre de la mine : IA selon son type (poursuite, saut, zigzag, tir, essaim, charge).

signal died(monster: MonsterEntity)
signal shot(origin: Vector2, direction: Vector2, damage: int)

const FRAMES: int = 3
const ANIM_FPS: float = 6.0
const AGGRO_RANGE: float = 110.0
const HIT_FLASH: float = 0.12
const KNOCK_DECAY: float = 7.0

var kind: String = "pebbler"
var def: Dictionary = {}
var hp: int = 1
var rt: MapRuntime
var target: Node2D
var sprite: Sprite2D
var index: int = -1
var _knock: Vector2 = Vector2.ZERO
var _t: float = 0.0
var _state: String = "idle"
var _state_t: float = 0.0
var _dir: Vector2 = Vector2.ZERO
var _flash: float = 0.0
var _seed_phase: float = 0.0


func _ready() -> void:
	def = Database.table("monsters")[kind]
	hp = int(def["hp"])
	sprite = Sprite2D.new()
	sprite.texture = Database.sheet("sprites/creatures/monster_" + kind)
	sprite.hframes = FRAMES
	sprite.offset = Vector2(0, -12)
	add_child(sprite)
	_seed_phase = WorldObjects.rng.randf() * TAU
	_state_t = WorldObjects.rng.randf_range(0.2, 1.2)


func place_cell(c: Vector2i) -> void:
	position = MapRuntime.foot_pixel(c)


func cell() -> Vector2i:
	return MapRuntime.cell_of_pixel(position + Vector2(0, -2))


func is_flying() -> bool:
	return bool(def.get("fly", false))


func contact_damage() -> int:
	return int(def["damage"])


func hurt(amount: int, from: Vector2) -> bool:
	hp -= amount
	_flash = HIT_FLASH
	var away: Vector2 = (position - from).normalized()
	_knock = away * Database.bal_f("knockback", 90.0)
	AudioManager.sfx("monster_hit")
	if hp <= 0:
		died.emit(self)
		return true
	return false


func _free_at(p: Vector2) -> bool:
	if is_flying():
		return rt.in_bounds(MapRuntime.cell_of_pixel(p))
	return not rt.is_solid(MapRuntime.cell_of_pixel(p + Vector2(0, -3)))


func _step(v: Vector2, delta: float) -> bool:
	var moved: bool = false
	var nx: Vector2 = position + Vector2(v.x * delta, 0)
	if _free_at(nx):
		position = nx
		moved = true
	var ny: Vector2 = position + Vector2(0, v.y * delta)
	if _free_at(ny):
		position = ny
		moved = true
	return moved


func _process(delta: float) -> void:
	if target == null or rt == null:
		return
	_t += delta
	if _flash > 0.0:
		_flash -= delta
		sprite.modulate = Color(2.2, 2.2, 2.2) if _flash > 0.0 else Color.WHITE
	if _knock.length() > 4.0:
		_step(_knock, delta)
		_knock = _knock.lerp(Vector2.ZERO, KNOCK_DECAY * delta)
		return
	var to_p: Vector2 = (target.position - position)
	var dist: float = to_p.length()
	var speed: float = float(def["speed"])
	match str(def["ai"]):
		"chase":
			if dist < AGGRO_RANGE:
				_step(to_p.normalized() * speed, delta)
		"zigzag":
			if dist < AGGRO_RANGE * 1.5:
				var side: Vector2 = to_p.normalized().rotated(PI * 0.5) * sin(_t * 5.0 + _seed_phase) * 0.9
				_step((to_p.normalized() + side).normalized() * speed, delta)
		"swarm":
			if dist < AGGRO_RANGE * 1.4:
				var jitter: Vector2 = Vector2(cos(_t * 9.0 + _seed_phase), sin(_t * 7.0 + _seed_phase)) * 0.6
				_step((to_p.normalized() + jitter).normalized() * speed, delta)
		"hop":
			_state_t -= delta
			if _state == "idle" and _state_t <= 0.0 and dist < AGGRO_RANGE:
				_state = "hop"
				_state_t = 0.28
				_dir = to_p.normalized()
			elif _state == "hop":
				_step(_dir * speed, delta)
				if _state_t <= 0.0:
					_state = "idle"
					_state_t = 0.9
		"shoot":
			_state_t -= delta
			if dist < AGGRO_RANGE * 1.2 and _state_t <= 0.0:
				_state_t = 2.2
				shot.emit(position + Vector2(0, -12), to_p.normalized(), contact_damage())
		"charge":
			_state_t -= delta
			match _state:
				"idle":
					if dist < AGGRO_RANGE * 1.5 and _state_t <= 0.0:
						_state = "windup"
						_state_t = 0.55
				"windup":
					sprite.modulate = Color(1.6, 0.8, 0.8) if int(_t * 12) % 2 == 0 else Color.WHITE
					_dir = to_p.normalized()
					if _state_t <= 0.0:
						_state = "charge"
						_state_t = 0.6
						sprite.modulate = Color.WHITE
				"charge":
					if not _step(_dir * speed, delta) or _state_t <= 0.0:
						_state = "stun"
						_state_t = 1.1
				"stun":
					if _state_t <= 0.0:
						_state = "idle"
						_state_t = 0.8
	sprite.flip_h = to_p.x < 0.0
	sprite.frame = int(_t * ANIM_FPS) % FRAMES
