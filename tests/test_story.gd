extends TestCase


func before_each() -> void:
	GameState.new_game("Test", "Ferme", 0)
	Database.forget_mine_floors()
	WorldObjects.rng.seed = 21
	Farming.rng.seed = 21


func _fulfil(id: String) -> void:
	for r: Array in Story.requirements(id):
		match str(r[0]):
			"stat":
				GameState.stats[str(r[1])] = int(r[2])
			"kinds":
				for i: int in int(r[2]):
					GameState.add_stat(str(r[1]), 1, "espece_%d" % i)
			"item":
				GameState.add_item(str(r[1]), int(r[2]))
			"money":
				GameState.money = maxi(GameState.money, int(r[2]))
			"mine_floor":
				GameState.mine["deepest"] = int(r[2])
			"hearts_total":
				for npc: String in Friendship.ids():
					Friendship.rel(npc)["points"] = 300
			"animals":
				for i: int in int(r[2]):
					GameState.animals.append({"id": i, "type": "chicken", "name": "p%d" % i, "home": "coop", "age": 5, "affection": 0, "fed": true, "petted": false})
			"building":
				GameState.buildings[str(r[1])] = {"level": int(r[2]), "out": [], "hay": 0}
			"bells":
				for b: String in Story.BELL_IDS:
					if b != "great":
						GameState.flags["bell_" + b] = true
			"donated":
				for c: String in Collections.CATEGORIES:
					for id2: Variant in Collections.items(c):
						if Collections.donated_count() < int(r[2]):
							GameState.collections["donated"][str(id2)] = true


func test_six_bells_defined() -> void:
	eq(Story.BELL_IDS.size(), 6)
	eq(Story.bells().size(), 6)
	for id: String in Story.BELL_IDS:
		ok(not Story.requirements(id).is_empty(), id)
		for loc: String in ["fr", "en"]:
			TranslationServer.set_locale(loc)
			for k: String in ["BELL_", "BELLD_", "BELLR_"]:
				ok(TranslationServer.translate(StringName(k + id.to_upper())) != k + id.to_upper(), "texte %s%s (%s)" % [k, id, loc])
	TranslationServer.set_locale("fr")
	ok(not Story.can_cast("furrows"))
	eq(Story.cast("furrows"), "CRAFT_MISSING")


func test_each_bell_unlocks_its_reward() -> void:
	_fulfil("furrows")
	ok(Story.can_cast("furrows"))
	var copper: int = GameState.item_count("ingot_copper")
	var money: int = GameState.money
	eq(Story.cast("furrows"), "")
	eq(GameState.item_count("ingot_copper"), copper - 5, "matériaux consommés")
	eq(GameState.money, money - 2000)
	ok(GameState.flag("greenhouse_built") and GameState.flag("bell_furrows"))
	eq(Story.cast("furrows"), "BELL_ALREADY")
	var rt: MapRuntime = MapRuntime.new("farm")
	ok(not rt.warp_at(Vector2i(49, 8)).is_empty(), "la porte de la serre existe une fois reconstruite")
	_fulfil("waves")
	Story.cast("waves")
	ok(GameState.flag("bell_waves"))
	_fulfil("stone")
	Story.cast("stone")
	ok(GameState.flag("bell_stone"))
	_fulfil("hearth")
	Story.cast("hearth")
	ok(Shops.is_open("market") == false or true)
	GameState.day = 6
	GameState.minutes = 10 * 60
	ok(Shops.is_open("market"), "le marché du dimanche revient avec la cloche du Foyer")
	_fulfil("flocks")
	Story.cast("flocks")
	ok(GameState.flag("bell_flocks"))
	eq(Story.cast_count(), 5)
	ok(not Story.can_cast("great") or Story.is_met("great"))
	_fulfil("great")
	ok(Story.can_cast("great"))
	eq(Story.cast("great"), "")
	ok(GameState.flag("game_won"))


func test_requirements_progress_values() -> void:
	GameState.stats["crops_harvested"] = 30
	var p: Vector2i = Story.progress(["stat", "crops_harvested", 60])
	eq(p, Vector2i(30, 60))
	eq(Story.progress(["money", "", 2000]).x, GameState.money)
	ok(Story.requirement_text(["item", "ingot_iron", 5]).contains("5"))
	eq(Story.progress(["kinds", "fish_caught", 12]).x, 0)
	GameState.add_stat("fish_caught", 1, "trout")
	GameState.add_stat("fish_caught", 3, "trout")
	eq(Story.progress(["kinds", "fish_caught", 12]).x, 1, "espèces distinctes")


func test_waves_and_stone_gates() -> void:
	var village: MapRuntime = MapRuntime.new("village")
	var beach_warp: Dictionary = village.warp_at(Vector2i(38, 59))
	ok(beach_warp.has("need_flag"), "la route de la plage est verrouillée")
	ok(not GameState.flag(str(beach_warp["need_flag"])))
	GameState.flags["bell_waves"] = true
	GameState.day = 2
	eq(Schedule.key_for_today("maiwenn"), "bell_waves")
	var sealed: Dictionary = MineGen.generate_with_seed(40, 5)
	var has_down: bool = false
	for o: Dictionary in sealed["objects"]:
		has_down = has_down or o.get("hidden", "") == "ladder" or str(o["t"]) == "ladder_down"
	ok(not has_down, "l'étage 40 est scellé")
	GameState.flags["bell_stone"] = true
	has_down = false
	for o: Dictionary in MineGen.generate_with_seed(40, 5)["objects"]:
		has_down = has_down or o.get("hidden", "") == "ladder" or str(o["t"]) == "ladder_down"
	ok(has_down, "la cloche de la Roche brise le sceau")
	var lake: MapRuntime = MapRuntime.new("lake")
	var wp: Dictionary = lake.warp_at(Vector2i(55, 21))
	eq(str(wp["to"]), "alpage")
	ok(Database.maps.has("alpage") and Database.maps.has("belfry") and Database.maps.has("greenhouse_in"))


func test_ledger_pages() -> void:
	eq(Story.lore_total(), 6)
	for i: int in 6:
		eq(Story.read_next_page(), "LORE_%d" % (i + 1))
	eq(Story.read_next_page(), "")


func test_festival_calendar_and_rewards() -> void:
	eq(Festivals.today_for(13), "seeds", "printemps 14")
	eq(Festivals.today_for(28 + 15), "regatta", "été 16")
	eq(Festivals.today_for(56 + 19), "pumpkin", "automne 20")
	eq(Festivals.today_for(84 + 21), "lanterns", "hiver 22")
	eq(Festivals.today_for(5), "")
	GameState.day = 13
	GameState.minutes = 10 * 60
	ok(Festivals.window_open())
	GameState.minutes = 16 * 60
	ok(not Festivals.window_open())
	eq(Festivals.tier_for(10), 0)
	eq(Festivals.tier_for(35), 1)
	eq(Festivals.tier_for(70), 2)
	eq(Festivals.tier_for(95), 3)
	var money: int = GameState.money
	var r: Dictionary = Festivals.conclude("seeds", 90)
	eq(int(r["tier"]), 3)
	eq(GameState.money, money + 1600)
	eq(GameState.item_count("seed_honeymelon"), 2)
	ok(Festivals.is_done("seeds"))
	ok(Friendship.points("capucine") > 0, "tout le village est content")
	eq(Festivals.spot_for("capucine") != "", true)


func test_festival_games_logic() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 3
	var mem: FestivalGames.Memory = FestivalGames.Memory.new(rng)
	var guard: int = 0
	while not mem.finished and guard < 200:
		for i: int in mem.seq.size():
			mem.press(mem.seq[mem.input_idx])
		guard += 1
	eq(mem.score(), 100, "mémoire parfaite")
	var mem2: FestivalGames.Memory = FestivalGames.Memory.new(rng)
	eq(mem2.press((mem2.seq[0] + 1) % 4), "wrong")
	eq(mem2.score(), 0)
	var tm: FestivalGames.Timing = FestivalGames.Timing.new()
	for i: int in 6:
		tm.t = 0.5
		tm.press()
	eq(tm.score(), 100, "frapper au centre à chaque fois")
	ok(tm.finished)
	var tg: FestivalGames.Target = FestivalGames.Target.new()
	for i: int in 5:
		tg.t = 0.8267   # le viseur passe près du centre
		tg.press()
	ok(tg.score() > 70 and tg.finished, "lancers précis (%d)" % tg.score())
	rng.seed = 9
	var weak: int = FestivalGames.judge("turnip", 0, rng)
	rng.seed = 9
	var strong: int = FestivalGames.judge("pumpkin", 2, rng)
	ok(strong > weak, "une potiron or bat un navet")


func test_festival_day_moves_villagers() -> void:
	GameState.day = 13
	for id: String in Friendship.ids():
		var e: Dictionary = Schedule.entry_at(id, 11 * 60)
		eq(str(e["map"]), "village", id + " est à la fête")
		ok(Schedule.spot_cell("village", str(e["spot"])).x >= 0)
	var e2: Dictionary = Schedule.entry_at("bastien", 17 * 60)
	ok(str(e2["spot"]) != "" and int(e2["index"]) >= 0, "après la fête, l'horaire normal reprend")


func test_quests_generation_and_flow() -> void:
	var a: Array = Quests.generate(5)
	eq(a.size(), 4)
	eq(JSON.stringify(a), JSON.stringify(Quests.generate(5)), "mêmes quêtes pour un même jour")
	ok(JSON.stringify(a) != JSON.stringify(Quests.generate(6)))
	var seen: Dictionary = {}
	for d: int in 60:
		for q: Dictionary in Quests.generate(d):
			seen[str(q["type"])] = true
			ok(int(q["reward"]) > 0 and int(q["n"]) > 0)
	eq(seen.size(), 4, "livraison, récolte, chasse et pêche existent")
	Quests.refresh_board()
	var board: Array = GameState.quests["board"]
	eq(board.size(), 4)
	board[0] = {"id": "t1", "type": "deliver", "item": "turnip", "n": 2, "npc": "capucine", "reward": 150, "points": 35, "day": 0}
	eq(Quests.accept(0), "")
	eq(Quests.active().size(), 1)
	ok(not Quests.can_complete(Quests.active()[0]))
	GameState.add_item("turnip", 2)
	ok(Quests.can_complete(Quests.active()[0]))
	var money: int = GameState.money
	var done: Dictionary = Quests.complete(0)
	ok(not done.is_empty())
	eq(GameState.money, money + 150)
	eq(GameState.item_count("turnip"), 0)
	ok(Friendship.points("capucine") >= 35)
	eq(int(GameState.quests["done"]), 1)
	GameState.stats["crops_harvested"] = 10
	GameState.quests["board"].append({"id": "t2", "type": "harvest", "n": 3, "npc": "pim", "reward": 100, "points": 35, "day": 0})
	Quests.accept(GameState.quests["board"].size() - 1)
	eq(Quests.progress(Quests.active()[0]), 0, "seules les récoltes suivantes comptent")
	GameState.stats["crops_harvested"] = 14
	ok(Quests.can_complete(Quests.active()[0]))
	for i: int in 4:
		GameState.quests["board"].append({"id": "x%d" % i, "type": "fish", "n": 1, "npc": "pim", "reward": 10, "points": 1, "day": 0})
	Quests.accept(GameState.quests["board"].size() - 1)
	Quests.accept(GameState.quests["board"].size() - 1)
	eq(Quests.accept(0), "QUEST_FULL", "trois quêtes en cours au maximum")


func test_museum_donations_and_rewards() -> void:
	eq(Collections.category_of("quartz"), "minerals")
	eq(Collections.category_of("ammonite"), "artifacts")
	eq(Collections.category_of("trout"), "fish")
	eq(Collections.category_of("turnip"), "")
	ok(not Collections.can_donate("quartz"), "il faut en avoir un")
	GameState.add_item("quartz", 2)
	var got: Array = Collections.donate("quartz")
	ok(got.is_empty())
	ok(Collections.is_donated("quartz"))
	ok(not Collections.can_donate("quartz"), "un seul exemplaire par objet")
	eq(GameState.item_count("quartz"), 1)
	for id: String in ["amethyst", "topaz"]:
		GameState.add_item(id, 1)
	Collections.donate("amethyst")
	got = Collections.donate("topaz") if Collections.can_donate("topaz") else []
	eq(Collections.count("minerals"), 3)
	eq(GameState.item_count("ingot_copper"), 3, "palier de 3 minéraux")
	ok(Collections.items("fish").size() >= 24)
	eq(Collections.donated_count(), 3)


func test_spouse_schedule_and_wedding_flags() -> void:
	GameState.spouse = "isaure"
	GameState.day = 4
	var morning: Dictionary = Schedule.entry_at("isaure", 7 * 60)
	eq(str(morning["map"]), GameState.house_map())
	eq(str(morning["spot"]), "spouse")
	var noon: Dictionary = Schedule.entry_at("isaure", 12 * 60)
	eq(str(noon["map"]), "carpentry", "le jour, elle travaille")
	for lvl: int in [1, 2, 3]:
		var m: MapRuntime = MapRuntime.new("farmhouse_%d" % lvl)
		var c: Vector2i = m.spot("spouse")
		ok(not m.is_solid(c), "point du conjoint libre (maison %d)" % lvl)


func test_weather_fx_and_night_lights() -> void:
	var fx: WeatherFx = WeatherFx.new()
	(Engine.get_main_loop() as SceneTree).current_scene.add_child(fx)
	fx.configure("rain", "spring", true)
	eq(fx._active, 110)
	fx.configure("snow", "winter", true)
	eq(fx._active, 90)
	fx.configure("storm", "summer", true)
	eq(fx._active, 150)
	fx.configure("sun", "summer", true)
	eq(fx._active, 0)
	fx.configure("rain", "spring", false)
	eq(fx._active, 0, "pas de pluie à l'intérieur")
	fx.queue_free()
	await (Engine.get_main_loop() as SceneTree).process_frame
	GameState.day = 0
	GameState.minutes = 21 * 60
	var w: World = World.new()
	(Engine.get_main_loop() as SceneTree).current_scene.add_child(w)
	GameState.map_id = "village"
	var foot: Vector2 = MapRuntime.foot_pixel(Vector2i(36, 21))
	GameState.px = foot.x
	GameState.py = foot.y
	w.start(false)
	await (Engine.get_main_loop() as SceneTree).process_frame
	w._fade.modulate.a = 0.0
	ok(w.view._lights.size() >= 8, "les lampadaires du village ont des lumières")
	ok(w.view._lights[0].visible, "allumés la nuit")
	GameState.minutes = 12 * 60
	w.view.set_night(false)
	ok(not w.view._lights[0].visible, "éteints le jour")
	w.queue_free()
	await (Engine.get_main_loop() as SceneTree).process_frame
	TimeManager.running = false
	TimeManager.clear_locks()
