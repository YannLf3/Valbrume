extends TestCase

const CELL: Vector2i = Vector2i(32, 17)


func before_each() -> void:
	GameState.new_game("Test", "Ferme", 0)
	Farming.rng.seed = 7
	WorldObjects.rng.seed = 7


func _farm() -> MapRuntime:
	return MapRuntime.new("farm")


func _tilled_planted(rt: MapRuntime, seed_id: String = "seed_turnip") -> void:
	ok(ToolUse.use(rt, "hoe_1", CELL, 0, false), "labour")
	eq(Farming.plant(rt, CELL, seed_id), "", "semis")


func test_maps_load() -> void:
	for id: String in ["farm", "farmhouse_1", "farmhouse_2", "farmhouse_3"]:
		ok(Database.maps.has(id), "carte " + id)
	var rt: MapRuntime = _farm()
	eq(rt.w, 64)
	ok(rt.is_solid(Vector2i(27, 9)), "la maison bloque")
	ok(not rt.is_solid(Vector2i(28, 10)), "la porte est franchissable")
	ok(rt.is_solid(Vector2i(-1, 0)), "hors carte = bloqué")
	ok(rt.is_solid(Vector2i(9, 35)), "l'eau bloque")
	ok(not rt.warp_at(Vector2i(28, 10)).is_empty(), "passage de la porte")
	ok(rt.objects().size() > 300, "la ferme est encombrée au départ")
	for x: int in range(30, 40):
		for y: int in range(15, 21):
			ok(not rt.is_solid(Vector2i(x, y)), "parcelle de départ dégagée %d,%d" % [x, y])


func test_till_plant_grow_harvest() -> void:
	var rt: MapRuntime = _farm()
	_tilled_planted(rt)
	var crop: Dictionary = rt.soil_at(CELL)["crop"]
	eq(Farming.stage_of(crop), 0)
	Farming.grow_night(rt, false)
	eq(int(rt.soil_at(CELL)["crop"]["age"]), 0, "sans arrosage, rien ne pousse")
	for i: int in 4:
		ok(Farming.water(rt, CELL), "arrosage")
		Farming.grow_night(rt, false)
	crop = rt.soil_at(CELL)["crop"]
	eq(int(crop["age"]), 4)
	ok(Farming.is_mature(crop), "mûr après 4 jours arrosés")
	var xp_before: int = int(GameState.skills["farming"]["xp"])
	ok(Farming.harvest(rt, CELL), "récolte")
	eq(GameState.item_count("turnip"), 1)
	ok(int(GameState.skills["farming"]["xp"]) > xp_before, "expérience gagnée")
	ok(not rt.soil_at(CELL).has("crop"), "culture à récolte unique retirée")


func test_regrow_crop() -> void:
	var rt: MapRuntime = _farm()
	GameState.add_item("seed_pea", 1)
	ToolUse.use(rt, "hoe_1", CELL, 0, false)
	eq(Farming.plant(rt, CELL, "seed_pea"), "")
	for i: int in 9:
		Farming.water(rt, CELL)
		Farming.grow_night(rt, false)
	ok(Farming.harvest(rt, CELL), "première récolte")
	var crop: Dictionary = rt.soil_at(CELL)["crop"]
	eq(Farming.stage_of(crop), 5, "plant en repousse")
	for i: int in 3:
		Farming.water(rt, CELL)
		Farming.grow_night(rt, false)
	ok(Farming.is_mature(rt.soil_at(CELL)["crop"]), "remûri 3 jours plus tard")
	eq(GameState.item_count("pea"), 1)


func test_rain_waters_and_season_kills() -> void:
	var rt: MapRuntime = _farm()
	_tilled_planted(rt)
	Farming.grow_night(rt, true)
	eq(int(rt.soil_at(CELL)["crop"]["age"]), 1, "la pluie arrose")
	GameState.day = 28
	eq(Farming.season_change(rt), 1, "le navet meurt en été")
	eq(Farming.stage_of(rt.soil_at(CELL)["crop"]), -1)
	ok(ToolUse.use(rt, "hoe_1", CELL, 0, false), "la houe retire la plante morte")
	ok(not rt.soil_at(CELL).has("crop"))


func test_wrong_season_and_occupied() -> void:
	var rt: MapRuntime = _farm()
	GameState.add_item("seed_tomato", 1)
	ToolUse.use(rt, "hoe_1", CELL, 0, false)
	eq(Farming.plant(rt, CELL, "seed_tomato"), "TOAST_WRONG_SEASON")
	eq(Farming.plant(rt, CELL, "seed_turnip"), "")
	eq(Farming.plant(rt, CELL, "seed_turnip"), "TOAST_OCCUPIED")


func test_sprinkler_and_scarecrow() -> void:
	var rt: MapRuntime = _farm()
	_tilled_planted(rt)
	rt.add_object(Vector2i(32, 16), {"t": "placed", "p": "sprinkler_1", "hp": 1})
	Farming.grow_night(rt, false)
	eq(int(rt.soil_at(CELL)["crop"]["age"]), 1, "l'arroseur arrose la case voisine")
	GameState.day = 50
	Database.balance["pest_chance"] = 1.0
	rt.add_object(Vector2i(34, 17), {"t": "placed", "p": "scarecrow", "hp": 1})
	Farming.grow_night(rt, true)
	ok(rt.soil_at(CELL).has("crop"), "l'épouvantail protège")
	rt.remove_object(Vector2i(34, 17))
	var res: Dictionary = Farming.grow_night(rt, true)
	eq(int(res["eaten"]), 1, "sans épouvantail, la culture est mangée")
	Database.balance["pest_chance"] = 0.015


func test_tools_energy_and_area() -> void:
	var rt: MapRuntime = _farm()
	var e: float = GameState.energy
	ToolUse.use(rt, "hoe_1", CELL, 0, false)
	near(e - GameState.energy, 2.0 * (1.0 - 0.03 * 1), 0.001, "coût en énergie avec remise de compétence")
	var cells: Array[Vector2i] = ToolUse.area_cells("hoe", 4, Vector2i(32, 18), 0, true)
	eq(cells.size(), 9, "houe niveau 4 chargée : 3×3")
	eq(ToolUse.area_cells("hoe", 4, Vector2i(32, 18), 0, false).size(), 1, "sans charge : 1 case")
	var line: Array[Vector2i] = ToolUse.area_cells("hoe", 2, Vector2i(32, 18), 2, true)
	eq(line[2], Vector2i(34, 18), "ligne de 3 vers la droite")
	GameState.energy = 0.5
	ok(not ToolUse.use(rt, "hoe_1", Vector2i(33, 17), 0, false), "trop fatigué")
	ok(rt.soil_at(Vector2i(33, 17)).is_empty())


func test_can_refill_and_water() -> void:
	var rt: MapRuntime = _farm()
	_tilled_planted(rt)
	ok(not ToolUse.use(rt, "can_1", CELL, 0, false), "arrosoir vide")
	ToolUse.refill_can(1)
	eq(GameState.can_water, 20)
	ok(ToolUse.use(rt, "can_1", CELL, 0, false))
	eq(GameState.can_water, 19)
	eq(int(rt.soil_at(CELL)["w"]), 1)


func test_object_hits() -> void:
	var rt: MapRuntime = _farm()
	var c: Vector2i = Vector2i(33, 18)
	rt.add_object(c, {"t": "rock", "hp": 2})
	ok(ToolUse.use(rt, "pick_1", c, 0, false))
	ok(rt.object_at(c).size() > 0, "un coup ne suffit pas")
	ToolUse.use(rt, "pick_1", c, 0, false)
	ok(rt.object_at(c).is_empty(), "rocher brisé")
	ok(GameState.item_count("stone") >= 2, "pierre récupérée")
	var big: Vector2i = Vector2i(36, 18)
	rt.add_object(big, {"t": "rock_big", "hp": 8})
	ok(rt.is_solid(big + Vector2i(1, 1)), "gros rocher sur 2×2")
	ToolUse.use(rt, "pick_1", big, 0, false)
	ok(not rt.object_at(big).is_empty(), "niveau 1 : trop faible, rien ne casse")
	rt.add_object(c, {"t": "tree", "k": "oak", "g": 2, "hp": 8})
	for i: int in 8:
		ToolUse.use(rt, "axe_1", c, 0, false)
	eq(str(rt.object_at(c).get("t", "")), "stump", "l'arbre laisse une souche")
	ok(GameState.item_count("wood") >= 8)


func test_placement() -> void:
	var rt: MapRuntime = _farm()
	GameState.add_item("chest", 1)
	GameState.add_item("table", 1)
	eq(Placement.place(rt, "chest", CELL, 0), "")
	ok(not rt.object_at(CELL).is_empty())
	eq(Placement.place(rt, "chest", CELL, 0), "TOAST_CANT_PLACE", "case occupée")
	eq(Placement.place(rt, "table", Vector2i(33, 17), 0), "TOAST_INDOORS_ONLY")
	eq(Placement.pickup(rt, CELL), "")
	eq(GameState.item_count("chest"), 1)
