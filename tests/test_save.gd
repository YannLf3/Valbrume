extends TestCase

const SLOT: int = 2


func before_each() -> void:
	GameState.reset()
	GameState.active = true


func test_roundtrip() -> void:
	GameState.player_name = "Élodie"
	GameState.money = 1234
	GameState.day = 40
	GameState.energy = 55.5
	GameState.flags["x"] = true
	GameState.map_state("farm")["soil"]["3,4"] = {"w": 1}
	ok(SaveManager.save_game(SLOT), "écriture")
	var before: Dictionary = GameState.to_dict()
	GameState.reset()
	ok(SaveManager.load_game(SLOT), "lecture")
	eq(GameState.player_name, "Élodie")
	eq(GameState.money, 1234)
	eq(GameState.day, 40)
	near(GameState.energy, 55.5)
	eq(JSON.stringify(GameState.to_dict()), JSON.stringify(before), "état identique après aller-retour")
	ok(typeof(GameState.map_state("farm")["soil"]["3,4"]["w"]) == TYPE_INT, "entiers préservés")
	SaveManager.delete_slot(SLOT)


func test_backup_on_corruption() -> void:
	GameState.money = 111
	SaveManager.save_game(SLOT)
	GameState.money = 222
	SaveManager.save_game(SLOT)
	var f: FileAccess = FileAccess.open(SaveManager.path(SLOT), FileAccess.WRITE)
	f.store_string("{ceci n'est pas du json")
	f.close()
	GameState.reset()
	ok(SaveManager.load_game(SLOT), "chargement depuis la copie de secours")
	eq(GameState.money, 111, "la copie de secours est la sauvegarde précédente")
	SaveManager.delete_slot(SLOT)
	ok(not SaveManager.slot_exists(SLOT), "suppression")


func test_migration() -> void:
	var old: Dictionary = {"save_version": 1, "state": {"gold": 77, "player_name": "Vieux"}}
	var d: Dictionary = SaveManager.migrate(old)
	eq(d["save_version"], SaveManager.SAVE_VERSION)
	eq(d["state"]["money"], 77, "gold → money")
	ok(not d["state"].has("gold"))
	ok(d["state"].has("pending_mail"))
