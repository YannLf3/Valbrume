extends TestCase
## Simulation d'une année complète (112 nuits) : saisons, météo, festivals, croissance et mort hors saison, aucune erreur.


func test_full_year_runs_clean() -> void:
	GameState.new_game("Test", "Ferme", 0)
	WorldObjects.rng.seed = 77
	Farming.rng.seed = 77
	var rt: MapRuntime = MapRuntime.new("farm")
	var weathers: Dictionary = {}
	var festivals: Dictionary = {}
	var seasons: Dictionary = {}
	var harvested: int = 0
	var start_money: int = GameState.money
	var cells: Array[Vector2i] = []
	for y: int in range(15, 21):
		for x: int in range(30, 36):
			cells.append(Vector2i(x, y))
	for c: Vector2i in cells:
		ToolUse.use(rt, "hoe_1", c, 0, false)
	for day: int in 112:
		seasons[TimeManager.season_id()] = true
		weathers[GameState.weather] = true
		var f: String = Festivals.today()
		if f != "":
			festivals[f] = true
		if day % 28 == 0 and day > 0:
			for c: Vector2i in cells:
				var s: Dictionary = rt.soil_at(c)
				if s.has("crop"):
					ok(Farming.season_ok(rt, str(s["crop"]["id"])) or bool(s["crop"].get("dead", false)), "plant hors saison encore vivant au jour %d" % day)
		var seed_id: String = Shops.seeds(false)[0]
		for c: Vector2i in cells:
			var s2: Dictionary = rt.soil_at(c)
			if s2.is_empty():
				ToolUse.use(rt, "hoe_1", c, 0, false)
			elif s2.has("crop") and bool(s2["crop"].get("dead", false)):
				s2.erase("crop")
			elif s2.has("crop") and Farming.is_mature(s2["crop"]):
				if Farming.harvest(rt, c):
					harvested += 1
			if rt.soil_at(c).has("crop"):
				Farming.water(rt, c)
			elif not rt.soil_at(c).is_empty():
				GameState.add_item(seed_id, 1)
				Farming.plant(rt, c, seed_id)
				Farming.water(rt, c)
		for i: int in GameState.inventory.size():
			var st: Variant = GameState.inventory[i]
			if st != null and str(Database.item(str(st["id"])).get("cat", "")) == "crop":
				var slot: int = Inv.free_slots(GameState.shipping)
				if slot > 0:
					Inv.add(GameState.shipping, str(st["id"]), int(st["n"]), int(st["q"]))
					GameState.inventory[i] = null
		GameState.energy = float(GameState.max_energy)
		var summary: Dictionary = DayCycle.run_night(false)
		ok(summary.has("total"), "bilan de la nuit %d" % day)
	eq(GameState.day, 112, "112 nuits")
	eq(seasons.size(), 4, "les quatre saisons sont traversées")
	ok(weathers.size() >= 3, "au moins 3 météos différentes (%s)" % str(weathers.keys()))
	for d: int in 28:
		pass
	eq(festivals.size(), 4, "les quatre festivals tombent dans l'année")
	ok(harvested > 20, "des récoltes régulières (%d)" % harvested)
	ok(GameState.money > start_money, "la ferme rapporte")
	for d2: int in range(84, 112):
		var w: String = Weather.roll(d2)
		ok(w != "rain" and w != "storm", "pas de pluie en hiver")
	TimeManager._ending = false
