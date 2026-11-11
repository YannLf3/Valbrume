extends Node
## Lecture des SFX (pool de lecteurs réutilisés) et de la musique (fondu enchaîné).

const SFX_DIR: String = "res://assets/audio/sfx/"
const MUSIC_DIR: String = "res://assets/audio/music/"
const POOL_SIZE: int = 10
const FADE_TIME: float = 1.2

var _pool: Array[AudioStreamPlayer] = []
var _next: int = 0
var _cache: Dictionary = {}
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _current_music: String = ""
var _last_played: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	for i: int in POOL_SIZE:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_music_a = _make_music_player()
	_music_b = _make_music_player()
	EventBus.settings_changed.connect(apply_volumes)
	apply_volumes()


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		var idx: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")


func _make_music_player() -> AudioStreamPlayer:
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.bus = "Music"
	p.volume_db = -60.0
	add_child(p)
	p.finished.connect(_on_music_finished.bind(p))
	return p


func apply_volumes() -> void:
	_set_bus("Master", Settings.volume_master)
	_set_bus("Music", Settings.volume_music)
	_set_bus("SFX", Settings.volume_sfx)


func _set_bus(bus_name: String, linear: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_mute(idx, linear <= 0.001)
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.001)))


func _stream(dir: String, id: String) -> AudioStream:
	var path: String = dir + id + ".wav"
	if _cache.has(path):
		return _cache[path]
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path)
	_cache[path] = s
	return s


## Joue un effet. `pitch_var` ajoute une légère variation de hauteur.
func sfx(id: String, pitch_var: float = 0.06, volume_db: float = 0.0) -> void:
	var s: AudioStream = _stream(SFX_DIR, id)
	if s == null:
		return
	var now: int = Time.get_ticks_msec()
	if now - int(_last_played.get(id, -1000)) < 40:
		return  # évite l'empilement du même son dans la même image
	_last_played[id] = now
	var p: AudioStreamPlayer = _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = s
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.volume_db = volume_db
	p.play()


func music(id: String) -> void:
	if id == _current_music:
		return
	_current_music = id
	var s: AudioStream = _stream(MUSIC_DIR, id) if id != "" else null
	var old: AudioStreamPlayer = _music_a
	_music_a = _music_b
	_music_b = old
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(_music_b, "volume_db", -60.0, FADE_TIME)
	tw.chain().tween_callback(_music_b.stop)
	if s != null:
		_music_a.stream = s
		_music_a.volume_db = -60.0
		_music_a.play()
		create_tween().tween_property(_music_a, "volume_db", 0.0, FADE_TIME)


func current_music() -> String:
	return _current_music


func _on_music_finished(p: AudioStreamPlayer) -> void:
	if p == _music_a and _current_music != "":
		p.play()
