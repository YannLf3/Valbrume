class_name WeatherFx
extends CanvasLayer
## Météo visible : pluie, orage (éclairs et tonnerre), neige, vent, pétales et feuilles de saison. Particules en pool.

const POOL: int = 150

var _sprites: Array[Sprite2D] = []
var _vel: PackedVector2Array = PackedVector2Array()
var _active: int = 0
var _kind: String = ""
var _flash: ColorRect
var _thunder_in: float = 6.0


func _ready() -> void:
	layer = 5
	for i: int in POOL:
		var s: Sprite2D = Sprite2D.new()
		s.visible = false
		add_child(s)
		_sprites.append(s)
	_vel.resize(POOL)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	EventBus.weather_changed.connect(func(w: String) -> void: configure(w, TimeManager.season_id(), _outdoors))
	set_process(false)


var _outdoors: bool = true


func configure(weather: String, season: String, outdoors: bool) -> void:
	_outdoors = outdoors
	var tex_name: String = ""
	var count: int = 0
	_kind = ""
	if outdoors:
		match weather:
			"rain":
				_kind = "rain"
				tex_name = "p_rain"
				count = 110
			"storm":
				_kind = "storm"
				tex_name = "p_rain"
				count = 150
			"snow":
				_kind = "snow"
				tex_name = "p_snow"
				count = 90
			"wind":
				_kind = "wind"
				tex_name = "p_leaf_a" if season == "autumn" else "p_leaf_b"
				count = 26
			_:
				if season == "spring":
					_kind = "petals"
					tex_name = "p_petal"
					count = 10
				elif season == "autumn":
					_kind = "leaves"
					tex_name = "p_leaf_a"
					count = 8
	_active = mini(count, POOL)
	var vs: Vector2 = get_viewport().get_visible_rect().size
	for i: int in POOL:
		var s: Sprite2D = _sprites[i]
		s.visible = i < _active
		if i < _active:
			s.texture = Database.sprite(tex_name)
			s.position = Vector2(randf() * vs.x, randf() * vs.y)
			_vel[i] = _velocity()
	set_process(_active > 0)


func _velocity() -> Vector2:
	match _kind:
		"rain":
			return Vector2(randf_range(-30, -18), randf_range(230, 290))
		"storm":
			return Vector2(randf_range(-90, -55), randf_range(290, 340))
		"snow":
			return Vector2(randf_range(-18, 18), randf_range(26, 52))
		"wind":
			return Vector2(randf_range(130, 200), randf_range(6, 36))
		"petals":
			return Vector2(randf_range(6, 22), randf_range(10, 20))
		"leaves":
			return Vector2(randf_range(-8, 20), randf_range(12, 24))
	return Vector2.ZERO


func _process(delta: float) -> void:
	var vs: Vector2 = get_viewport().get_visible_rect().size
	for i: int in _active:
		var s: Sprite2D = _sprites[i]
		s.position += _vel[i] * delta
		if s.position.y > vs.y + 6.0 or s.position.x > vs.x + 6.0 or s.position.x < -6.0:
			s.position = Vector2(randf() * vs.x if _kind != "wind" else -4.0, -4.0 if _kind != "wind" else randf() * vs.y)
	if _kind == "storm":
		_thunder_in -= delta
		if _thunder_in <= 0.0:
			_thunder_in = randf_range(7.0, 18.0)
			_flash.color.a = 0.55
			create_tween().tween_property(_flash, "color:a", 0.0, 0.45)
			get_tree().create_timer(randf_range(0.4, 1.2)).timeout.connect(func() -> void: AudioManager.sfx("thunder", 0.0))
