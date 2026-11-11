extends Node
## Racine de l'application : écran titre ↔ partie.

var _title: TitleScreen = null
var _world: World = null


func _ready() -> void:
	get_tree().auto_accept_quit = false
	_show_title()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if GameState.active and SaveManager.current_slot >= 0:
			SaveManager.save_game(SaveManager.current_slot)
		AudioManager.shutdown()
		get_tree().quit()


func _show_title() -> void:
	if _world != null:
		_world.queue_free()
		_world = null
	GameState.active = false
	SaveManager.can_quick_save = false
	TimeManager.running = false
	TimeManager.clear_locks()
	_title = TitleScreen.new()
	add_child(_title)
	_title.play_requested.connect(_on_play)
	AudioManager.music("title")


func _on_play(slot: int, is_new: bool, p_name: String, farm: String, outfit: int) -> void:
	if is_new:
		GameState.new_game(p_name, farm, outfit)
		SaveManager.current_slot = slot
		SaveManager.save_game(slot)
	else:
		if not SaveManager.load_game(slot):
			return
	_title.queue_free()
	_title = null
	_world = World.new()
	add_child(_world)
	_world.quit_to_title.connect(_show_title)
	_world.start(is_new)
