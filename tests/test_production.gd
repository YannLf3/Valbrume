extends TestCase


func before_each() -> void:
	GameState.new_game("Test", "Ferme", 0)
	WorldObjects.rng.seed = 5
	Farming.rng.seed = 5


func _place(rt: MapRuntime, item: String, c: Vector2i) -> Dictionary:
	GameState.add_item(item, 1)
	eq(Placement.place(rt, item, c, 0), "", "pose de " + item)
	return rt.object_at(c)


func _hold(item: String) -> int:
	for i: int in GameState.inventory.size():
		if GameState.inventory[i] != null and GameState.inventory[i]["id"] == item:
			GameState.hotbar_index = i
			return i
	return -1


func test_furnace_cycle_and_fuel() -> void:
	var rt: MapRuntime = MapRuntime.new("farm")
	var o: Dictionary = _place(rt, "furnace", Vector2i(32, 17))
	GameState.add_item("ore_copper", 5)
	var i: int = _hold("ore_copper")
	eq(Machines.interact(o, "ore_copper", i), "MACHINE_NEEDS_FUEL", "sans charbon")
	GameState.add_item("coal", 2)
	eq(Machines.interact(o, "ore_copper", i), "")
	eq(GameState.item_count("coal"), 1, "un charbon consommé")
	eq(GameState.item_count("ore_copper"), 0)
	eq(Machines.interact(o, "", -1), "MACHINE_BUSY", "elle travaille")
	ok(Machines.minutes_left(o["m"]) > 0)
	GameState.minutes += 61
	ok(Machines.is_ready(o["m"]))
	eq(Machines.interact(o, "", -1), "")
	eq(GameState.item_count("ingot_copper"), 1, "lingot de cuivre")
	GameState.add_item("egg", 1)
	eq(Machines.interact(o, "egg", _hold("egg")), "MACHINE_BAD_INPUT", "le fourneau refuse les œufs")
	GameState.add_item("ore_copper", 3)
	eq(Machines.interact(o, "ore_copper", _hold("ore_copper")), "MACHINE_NEED_MORE", "il faut 5 minerais")


func test_machines_keep_quality_and_recipes() -> void:
	var rt: MapRuntime = MapRuntime.new("farm")
	var press: Dictionary = _place(rt, "cheese_press", Vector2i(31, 17))
	GameState.add_item("milk", 1, 2)
	eq(Machines.interact(press, "milk", _hold("milk")), "")
	GameState.minutes += 200
	Machines.interact(press, "", -1)
	var s: Variant = GameState.inventory[_slot_of("cheese")]
	eq(int(s["q"]), 2, "la fromagerie garde la qualité")
	var jar: Dictionary = _place(rt, "preserve_jar", Vector2i(33, 17))
	GameState.add_item("apple", 1)
	Machines.interact(jar, "apple", _hold("apple"))
	eq(str(jar["m"]["out"]["id"]), "jam", "fruit → confiture")
	GameState.minutes += 500
	Machines.interact(jar, "", -1)
	GameState.add_item("turnip", 1)
	Machines.interact(jar, "turnip", _hold("turnip"))
	eq(str(jar["m"]["out"]["id"]), "pickles", "légume → bocal")
	var sorter: Dictionary = _place(rt, "seed_sorter", Vector2i(34, 17))
	GameState.add_item("tomato", 1)
	Machines.interact(sorter, "tomato", _hold("tomato"))
	eq(str(sorter["m"]["out"]["id"]), "seed_tomato", "la trieuse rend des graines")
	ok(int(sorter["m"]["out"]["n"]) >= 1 and int(sorter["m"]["out"]["n"]) <= 3)


func _slot_of(id: String) -> int:
	for i: int in GameState.inventory.size():
		if GameState.inventory[i] != null and GameState.inventory[i]["id"] == id:
			return i
	return 0


func test_beehive_seasons() -> void:
	var rt: MapRuntime = MapRuntime.new("farm")
	var hive: Dictionary = _place(rt, "beehive", Vector2i(32, 18))
	for i: int in 2:
		Machines.nightly(rt)
	ok(not hive["m"].has("out"), "pas encore")
	Machines.nightly(rt)
	eq(str(hive["m"]["out"]["id"]), "honey", "du miel au bout de 3 nuits")
	eq(Machines.interact(hive, "", -1), "")
	eq(GameState.item_count("honey"), 1)
	GameState.day = 84   # hiver
	for i: int in 5:
		Machines.nightly(rt)
	ok(not hive["m"].has("out"), "les abeilles dorment en hiver")


func test_crafting_and_cooking() -> void:
	eq(Crafting.make("craft", "chest"), "CRAFT_MISSING")
	GameState.add_item("wood", 100)
	ok(Crafting.can_make("craft", "chest"))
	eq(Crafting.make("craft", "chest"), "")
	eq(GameState.item_count("wood"), 60)
	eq(GameState.item_count("chest"), 1)
	eq(Crafting.make("craft", "sprinkler_1"), "CRAFT_UNKNOWN", "recette non débloquée")
	# cuisine : « n'importe quel poisson » consomme le moins cher
	GameState.add_item("tuna", 1)
	GameState.add_item("gudgeon", 1)
	ok(Crafting.can_make("cook", "grilled_fish"))
	eq(Crafting.make("cook", "grilled_fish"), "")
	eq(GameState.item_count("gudgeon"), 0, "le goujon part avant le thon")
	eq(GameState.item_count("tuna"), 1)
	eq(GameState.item_count("grilled_fish"), 1)
	GameState.add_item("egg", 2)
	eq(Crafting.make("cook", "omelette"), "")
	eq(GameState.item_count("omelette"), 1)
	eq(Crafting.known_ids("craft").has("chest"), true)
	var n_recipes: int = Recipes.table("craft").size() + Recipes.table("cook").size()
	ok(n_recipes >= 65, "au moins 40 recettes d'artisanat et 25 plats (%d)" % n_recipes)
	ok(Recipes.table("craft").size() >= 40 and Recipes.table("cook").size() >= 25)


func test_construction_and_capacity() -> void:
	GameState.money = 20000
	GameState.add_item("wood", 400)
	GameState.add_item("stone", 200)
	eq(Buildings.level("coop"), 0)
	eq(Buildings.start("coop"), "")
	ok(Buildings.builder_busy())
	eq(Buildings.start("barn"), "BUILD_BUSY", "un seul chantier à la fois")
	eq(GameState.money, 16000)
	eq(Buildings.nightly(), "", "premier jour")
	eq(Buildings.nightly(), "coop", "terminé au bout de 2 jours")
	eq(Buildings.level("coop"), 1)
	eq(Buildings.capacity("coop"), 4)
	var rt: MapRuntime = MapRuntime.new("farm")
	var f: Dictionary = Buildings.footprint("coop")
	var door: Vector2i = Vector2i(int(f["door"][0]), int(f["door"][1]))
	ok(rt.is_solid(Vector2i(int(f["x"]), int(f["y"]))), "le poulailler est un obstacle")
	ok(not rt.is_solid(door), "sa porte est franchissable")
	eq(str(rt.warp_at(door).get("to", "")), "coop_in_1")
	ok(Database.maps.has("coop_in_1") and Database.maps.has("barn_in_2"))
	eq(GameState.item_count("wood"), 250)
	eq(Buildings.start("coop"), "", "niveau 2 : 8 000 + 250 bois + 100 pierre")
	eq(GameState.item_count("wood"), 0)
	eq(GameState.money, 16000 - 8000)


func test_house_upgrade_changes_map_and_kitchen() -> void:
	eq(GameState.house_map(), "farmhouse_1")
	GameState.money = 50000
	GameState.add_item("wood", 800)
	GameState.add_item("stone", 300)
	eq(Buildings.start("house"), "")
	for i: int in 3:
		Buildings.nightly()
	eq(GameState.house_map(), "farmhouse_2")
	var f: Dictionary = Buildings.house_footprint()
	eq(int(f["w"]), 6)
	var rt: MapRuntime = MapRuntime.new("farm")
	ok(not rt.is_solid(Vector2i(28, 10)), "la porte reste en place")
	ok(rt.is_solid(Vector2i(31, 9)), "la maison s'est élargie")
	var inner: MapRuntime = MapRuntime.new("farmhouse_2")
	var has_kitchen: bool = false
	for z: Dictionary in inner.all_zones():
		has_kitchen = has_kitchen or str(z["kind"]) == "kitchen"
	ok(has_kitchen, "cuisine au niveau 2")


func _build_coop_and_buy() -> void:
	GameState.buildings["coop"] = {"level": 1, "out": [], "hay": 0}
	GameState.money = 5000


func test_animals_buy_grow_produce() -> void:
	GameState.money = 5000
	eq(Animals.can_buy("chicken"), "ANIMAL_NO_HOME")
	_build_coop_and_buy()
	eq(Animals.buy("chicken", "Poulette"), "")
	eq(GameState.money, 4600)
	eq(Animals.can_buy("duck"), "ANIMAL_NO_HOME", "la cane exige le poulailler niveau 2")
	GameState.weather = "sun"
	GameState.day = 0
	var made: int = 0
	for i: int in 2:
		made += Animals.nightly()
	eq(made, 0, "poussin : rien avant 3 jours")
	made = Animals.nightly()
	eq(made, 1, "une poule adulte pond un œuf par jour")
	eq(((GameState.buildings["coop"]["out"]) as Array).size(), 1)
	eq(Animals.collect("coop"), 1)
	eq(GameState.item_count("egg"), 1)
	for i: int in 3:
		GameState.buildings["coop"]["out"].append({"id": "egg", "n": 1, "q": 0})
	GameState.buildings["coop"]["level"] = 1
	for i: int in 3:
		GameState.add_item("egg", 1)
	eq(Animals.collect("coop"), 3)
	eq(Animals.collect("coop"), 0)


func test_animals_affection_feeding_quality() -> void:
	_build_coop_and_buy()
	Animals.buy("chicken", "Poulette")
	var a: Dictionary = GameState.animals[0]
	ok(Animals.pet(a), "caresse")
	ok(not Animals.pet(a), "une fois par jour")
	eq(int(a["affection"]), 15)
	GameState.weather = "rain"
	GameState.buildings["silo"] = {"level": 1, "out": [], "hay": 0}
	Animals.nightly()
	eq(bool(a["fed"]), false, "sous la pluie et sans foin : affamée")
	eq(int(a["affection"]), 0)
	GameState.add_item("hay", 5)
	eq(Animals.store_hay(5), 5)
	eq(Animals.hay_stored(), 5)
	Animals.pet(a)
	Animals.nightly()
	eq(Animals.hay_stored(), 4, "un foin mangé")
	ok(bool(a["fed"]))
	a["affection"] = 800
	WorldObjects.rng.seed = 1
	eq(Animals.quality_of(a), 2, "affection élevée → qualité or")
	a["affection"] = 450
	ok(Animals.quality_of(a) >= 1)
	GameState.weather = "sun"
	GameState.day = 84
	Animals.nightly()
	ok(not Animals.grazing_today(), "pas de pâturage en hiver")


func test_wallpaper_and_floor_items_exist() -> void:
	for id: String in ["wallpaper_1", "wallpaper_4", "floor_1", "floor_4", "table", "chair", "bookshelf"]:
		ok(Database.has_item(id), id)
	eq(int(Database.item("wallpaper_3")["wallpaper"]), 2)
	eq(int(Database.item("floor_2")["floor"]), 1)


func test_animals_appear_in_their_building() -> void:
	GameState.map_id = "coop_in_1"
	_build_coop_and_buy()
	Animals.buy("chicken", "Poulette")
	Animals.buy("chicken", "Plume")
	var w: World = World.new()
	(Engine.get_main_loop() as SceneTree).current_scene.add_child(w)
	w.start(false)
	await (Engine.get_main_loop() as SceneTree).process_frame
	w._fade.modulate.a = 0.0
	eq(w.rt.id, "coop_in_1")
	eq(w.animals.entities.size(), 2, "deux poules dans le poulailler")
	for e: AnimalEntity in w.animals.entities:
		ok(not w.rt.is_solid(e.cell()), "les animaux restent sur des cases libres")
	w.load_map("farm", MapRuntime.foot_pixel(Vector2i(31, 14)), 0)
	eq(w.animals.entities.size(), 1, "sur la ferme : seulement le chien")
	w.queue_free()
	await (Engine.get_main_loop() as SceneTree).process_frame
	TimeManager.running = false
	TimeManager.clear_locks()
