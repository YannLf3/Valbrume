extends Node
## Sauvegardes JSON versionnées : 3 emplacements, copie de secours, migrations.

const SAVE_VERSION: int = 2
const SLOT_COUNT: int = 3
const DIR: String = "user://saves"

var current_slot: int = -1
## Vrai quand une sauvegarde hors sommeil est sûre (hors cinématique / mini-jeu).
var can_quick_save: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(DIR)


func _notification(what: int) -> void:
	# Android : l'application passe en arrière-plan → on sauvegarde tout de suite.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if GameState.active and can_quick_save and current_slot >= 0:
			save_game(current_slot)


func path(slot: int) -> String:
	return "%s/slot_%d.json" % [DIR, slot]


func backup_path(slot: int) -> String:
	return path(slot) + ".bak"


func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(path(slot)) or FileAccess.file_exists(backup_path(slot))


func save_game(slot: int) -> bool:
	var data: Dictionary = {
		"save_version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"summary": {
			"player": GameState.player_name, "farm": GameState.farm_name,
			"day": GameState.day, "money": GameState.money, "playtime": int(GameState.playtime),
		},
		"state": GameState.to_dict(),
	}
	var tmp: String = path(slot) + ".tmp"
	var file: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_error("Sauvegarde impossible : %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	var dir: DirAccess = DirAccess.open(DIR)
	if dir == null:
		return false
	# L'ancienne sauvegarde valide devient la copie de secours.
	if FileAccess.file_exists(path(slot)) and _read(path(slot)).size() > 0:
		dir.rename(path(slot), backup_path(slot))
	dir.rename(tmp, path(slot))
	current_slot = slot
	Settings.last_slot = slot
	Settings.save_settings()
	return true


func _read(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var json: JSON = JSON.new()   # parse() ne journalise pas d'erreur, contrairement à parse_string()
	if json.parse(FileAccess.get_file_as_string(file_path)) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {}
	var d: Dictionary = Database.normalize(json.data)
	if not d.has("state") or typeof(d["state"]) != TYPE_DICTIONARY or not d.has("save_version"):
		return {}
	return d


## Lit un emplacement ; bascule sur la copie de secours si le fichier est corrompu.
func read_slot(slot: int) -> Dictionary:
	var d: Dictionary = _read(path(slot))
	if d.is_empty():
		d = _read(backup_path(slot))
		if not d.is_empty():
			d["from_backup"] = true
	return d


func slot_summary(slot: int) -> Dictionary:
	var d: Dictionary = read_slot(slot)
	return d.get("summary", {}) if not d.is_empty() else {}


func load_game(slot: int) -> bool:
	var d: Dictionary = read_slot(slot)
	if d.is_empty():
		return false
	d = migrate(d)
	GameState.from_dict(d["state"])
	current_slot = slot
	return true


func delete_slot(slot: int) -> void:
	var dir: DirAccess = DirAccess.open(DIR)
	if dir == null:
		return
	for p: String in [path(slot), backup_path(slot)]:
		if FileAccess.file_exists(p):
			dir.remove(p)


## Applique les migrations successives jusqu'à SAVE_VERSION.
func migrate(d: Dictionary) -> Dictionary:
	var v: int = int(d.get("save_version", 1))
	while v < SAVE_VERSION:
		match v:
			1:
				_migrate_1_to_2(d["state"])
		v += 1
	d["save_version"] = SAVE_VERSION
	return d


## v1 → v2 : « gold » est devenu « money » ; le courrier en attente est apparu.
func _migrate_1_to_2(state: Dictionary) -> void:
	if state.has("gold"):
		state["money"] = int(state["gold"])
		state.erase("gold")
	if not state.has("pending_mail"):
		state["pending_mail"] = []
