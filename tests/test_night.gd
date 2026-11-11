extends TestCase


func before_each() -> void:
	GameState.new_game("Test", "Ferme", 0)
	WorldObjects.rng.seed = 3
	Farming.rng.seed = 3


func test_shipping_sale_and_new_day() -> void:
	GameState.shipping[0] = {"id": "turnip", "n": 3, "q": 0}
	GameState.shipping[1] = {"id": "turnip", "n": 1, "q": 2}
	var money: int = GameState.money
	var day: int = GameState.day
	var s: Dictionary = DayCycle.run_night(false)
	eq(int(s["total"]), 3 * 38 + 57, "3 navets normaux + 1 en or (×1,5)")
	eq(GameState.money, money + 171)
	eq(GameState.day, day + 1)
	eq(GameState.minutes, TimeManager.DAY_START)
	eq(GameState.map_id, "farmhouse_1", "réveil à la maison")
	near(GameState.energy, float(GameState.max_energy), 0.01)
	eq(Inv.free_slots(GameState.shipping), GameState.shipping.size(), "coffre vidé")


func test_faint_penalty() -> void:
	GameState.money = 4000
	GameState.energy = 10.0
	var s: Dictionary = DayCycle.run_night(true)
	eq(int(s["loss"]), 400, "10 % de l'argent")
	eq(GameState.money, 3600)
	near(GameState.energy, GameState.max_energy * 0.5, 0.01, "énergie réduite")
	GameState.money = 50000
	eq(int(DayCycle.run_night(true)["loss"]), 1000, "perte plafonnée")


func test_crops_grow_through_the_night_and_weather() -> void:
	var rt: MapRuntime = MapRuntime.new("farm")
	ToolUse.use(rt, "hoe_1", Vector2i(32, 17), 0, false)
	Farming.plant(rt, Vector2i(32, 17), "seed_turnip")
	Farming.water(rt, Vector2i(32, 17))
	DayCycle.run_night(false)
	eq(int(MapRuntime.new("farm").soil_at(Vector2i(32, 17))["crop"]["age"]), 1)
	var w: String = Weather.roll(40)
	eq(Weather.roll(40), w, "météo déterministe pour une même partie")
	eq(Weather.roll(0), "sun")
	for d: int in range(84, 112):
		ok(Weather.roll(d) != "rain" and Weather.roll(d) != "storm", "pas de pluie en hiver")


func test_skills_levels_and_recipes() -> void:
	eq(Skills.level_for_xp(0), 1)
	eq(Skills.level_for_xp(150), 2)
	eq(Skills.level_for_xp(11000), 10)
	ok(Recipes.known("craft", "chest"), "recette de départ")
	ok(not Recipes.known("craft", "sprinkler_1"), "arroseur pas encore connu")
	Skills.add_xp("farming", 460)
	eq(GameState.skill_level("farming"), 3)
	ok(Recipes.known("craft", "sprinkler_1"), "niveau 2 → arroseur de cuivre")
	Skills.add_xp("combat", 1000)
	eq(GameState.max_health, 115, "niveau 3+ de combat : +15 santé")


func test_consumables_and_buffs() -> void:
	GameState.add_item("ratatouille", 1)
	GameState.energy = 10.0
	ok(Consumables.eat("ratatouille"))
	near(GameState.energy, 110.0 if GameState.max_energy >= 130 else float(GameState.max_energy), 0.01)
	eq(GameState.max_energy, 130, "bonus d'énergie maximale du repas")
	TimeManager.advance(1)
	TimeManager._ending = false
	for i: int in 600:
		Consumables.tick()
	eq(GameState.max_energy, 100, "le bonus expire")


func test_economy_perks() -> void:
	eq(Economy.sell_value("turnip", 0), 38)
	eq(Economy.sell_value("turnip", 1), 48)
	GameState.skills["farming"]["level"] = 10
	eq(Economy.sell_value("turnip", 0), 42, "+10 % au niveau 10 d'agriculture")


func test_daily_update_spawns_forage() -> void:
	var rt: MapRuntime = MapRuntime.new("farm")
	var before: int = 0
	for k: String in rt.objects():
		if str(rt.objects()[k].get("t", "")) == "forage":
			before += 1
	WorldObjects.daily_update(rt)
	var after: int = 0
	for k: String in rt.objects():
		if str(rt.objects()[k].get("t", "")) == "forage":
			after += 1
	ok(after > before, "de la cueillette apparaît")
