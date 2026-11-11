extends Node
## Options du joueur, persistées dans user://settings.json (hors sauvegardes).

const PATH: String = "user://settings.json"
const LANGUAGES: Array[String] = ["fr", "en"]
const LAYOUTS: Array[String] = ["auto", "wasd", "zqsd", "arrows"]
const TOUCH_MODES: Array[String] = ["auto", "on", "off"]

var language: String = ""
var volume_master: float = 0.9
var volume_music: float = 0.7
var volume_sfx: float = 0.9
var seconds_per_minute: float = 0.7
var ui_scale: float = 1.0
var touch_mode: String = "auto"
var key_layout: String = "auto"
var fullscreen: bool = false
var show_fps: bool = false
var screen_shake: bool = true
var bindings: Dictionary = {}
var last_slot: int = -1

const _FIELDS: Array[String] = [
	"language", "volume_master", "volume_music", "volume_sfx", "seconds_per_minute",
	"ui_scale", "touch_mode", "key_layout", "fullscreen", "show_fps", "screen_shake",
	"bindings", "last_slot",
]


func _ready() -> void:
	load_settings()
	if language == "":
		language = _detect_language()
	apply_language()
	apply_window()


func _detect_language() -> String:
	var loc: String = OS.get_locale_language()
	return loc if LANGUAGES.has(loc) else "en"


func apply_language() -> void:
	TranslationServer.set_locale(language)
	EventBus.language_changed.emit()


func apply_window() -> void:
	if DisplayServer.get_name() == "headless" or OS.has_feature("mobile"):
		return
	var mode: int = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func set_value(field: String, value: Variant) -> void:
	set(field, value)
	if field == "language":
		apply_language()
	elif field == "fullscreen":
		apply_window()
	save_settings()
	EventBus.settings_changed.emit()


func save_settings() -> void:
	var d: Dictionary = {}
	for f: String in _FIELDS:
		d[f] = get(f)
	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(d, "\t"))
		file.close()


func load_settings() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var d: Dictionary = parsed
	for f: String in _FIELDS:
		if d.has(f) and typeof(d[f]) == typeof(get(f)):
			set(f, d[f])
		elif d.has(f) and typeof(get(f)) == TYPE_INT and typeof(d[f]) == TYPE_FLOAT:
			set(f, int(d[f]))
	if not LANGUAGES.has(language):
		language = ""
	if not LAYOUTS.has(key_layout):
		key_layout = "auto"
	if not TOUCH_MODES.has(touch_mode):
		touch_mode = "auto"
