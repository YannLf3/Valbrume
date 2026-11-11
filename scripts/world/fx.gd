class_name Fx
extends Node2D
## Particules ponctuelles (poussière, éclats, étincelles, gouttes) : pool de sprites réutilisés.

const POOL_SIZE: int = 64
const CONFIG: Dictionary = {
	"dust": {"tex": "p_dust", "n": 4, "speed": 22.0, "gravity": -6.0, "life": 0.5},
	"chip": {"tex": "p_chip", "n": 5, "speed": 55.0, "gravity": 150.0, "life": 0.55},
	"wood": {"tex": "p_wood", "n": 5, "speed": 50.0, "gravity": 150.0, "life": 0.55},
	"sparkle": {"tex": "p_sparkle", "n": 4, "speed": 28.0, "gravity": -20.0, "life": 0.6},
	"drop": {"tex": "p_drop", "n": 3, "speed": 18.0, "gravity": 120.0, "life": 0.4},
	"splash": {"tex": "p_splash", "n": 5, "speed": 40.0, "gravity": 140.0, "life": 0.5},
	"heart": {"tex": "p_heart", "n": 2, "speed": 14.0, "gravity": -24.0, "life": 0.9},
	"smoke": {"tex": "p_smoke", "n": 2, "speed": 10.0, "gravity": -18.0, "life": 0.9},
}

var _sprites: Array[Sprite2D] = []
var _vel: PackedVector2Array = PackedVector2Array()
var _life: PackedFloat32Array = PackedFloat32Array()
var _max_life: PackedFloat32Array = PackedFloat32Array()
var _grav: PackedFloat32Array = PackedFloat32Array()
var _next: int = 0
var _active: int = 0


func _ready() -> void:
	z_index = 50
	for i: int in POOL_SIZE:
		var s: Sprite2D = Sprite2D.new()
		s.visible = false
		add_child(s)
		_sprites.append(s)
	_vel.resize(POOL_SIZE)
	_life.resize(POOL_SIZE)
	_max_life.resize(POOL_SIZE)
	_grav.resize(POOL_SIZE)
	EventBus.fx_requested.connect(spawn)


func spawn(kind: String, pos: Vector2) -> void:
	if not CONFIG.has(kind):
		return
	var cfg: Dictionary = CONFIG[kind]
	var tex: Texture2D = Database.sprite(str(cfg["tex"]))
	for i: int in int(cfg["n"]):
		var idx: int = _next
		_next = (_next + 1) % POOL_SIZE
		var s: Sprite2D = _sprites[idx]
		s.texture = tex
		s.position = pos + Vector2(randf_range(-4, 4), randf_range(-3, 3))
		s.modulate = Color.WHITE
		s.visible = true
		var ang: float = randf_range(-PI, 0.0) if float(cfg["gravity"]) > 0.0 else randf_range(0.0, TAU)
		_vel[idx] = Vector2(cos(ang), sin(ang)) * float(cfg["speed"]) * randf_range(0.5, 1.0)
		_grav[idx] = float(cfg["gravity"])
		_life[idx] = float(cfg["life"]) * randf_range(0.7, 1.0)
		_max_life[idx] = _life[idx]
	set_process(true)


func _process(delta: float) -> void:
	var any: bool = false
	for i: int in POOL_SIZE:
		if _life[i] <= 0.0:
			continue
		_life[i] -= delta
		var s: Sprite2D = _sprites[i]
		if _life[i] <= 0.0:
			s.visible = false
			continue
		any = true
		_vel[i].y += _grav[i] * delta
		s.position += _vel[i] * delta
		s.modulate.a = clampf(_life[i] / _max_life[i] * 2.0, 0.0, 1.0)
	if not any:
		set_process(false)
