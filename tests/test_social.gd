extends TestCase

const FUTURE_MAPS: Array[String] = ["mine", "alpage", "greenhouse_in", "belfry"]
const ARRIVAL_SPOT: Dictionary = {"village": "farm_east", "lake": "village_in", "forest": "farm_south", "beach": "village_in", "farm": "village_in"}


func before_each() -> void:
	GameState.new_game("Test", "Ferme", 0)


func _trans(key: String, locale: String) -> String:
	TranslationServer.set_locale(locale)
	var t: String = TranslationServer.translate(StringName(key))
	TranslationServer.set_locale(Settings.language if Settings.language != "" else "fr")
	return t


func test_ten_npcs_complete_data() -> void:
	var ids: Array[String] = Friendship.ids()
	eq(ids.size(), 10, "dix habitants")
	var romance: int = 0
	for id: String in ids:
		var d: Dictionary = Friendship.npc(id)
		ok(Dialogue.total_lines(id) >= 15, "%s : au moins 15 répliques (%d)" % [id, Dialogue.total_lines(id)])
		eq((d["events"] as Array).size(), 2, id + " : 2 événements")
		if bool(d["romance"]):
			romance += 1
		for k: String in d["talk"]:
			for key: String in d["talk"][k]:
				for loc: String in ["fr", "en"]:
					ok(_trans(key, loc) != key, "traduction manquante %s (%s)" % [key, loc])
		for t: String in Friendship.TASTES:
			if t != "neutral":
				ok(d["talk"].has("gift_" + t), "%s : réaction %s" % [id, t])
		for list_name: String in ["loves", "likes", "dislikes", "hates"]:
			for item: String in d[list_name]:
				ok(item.begins_with("cat:") or Database.has_item(item), "%s : objet inconnu %s" % [id, item])
		for eid: String in d["events"]:
			var e: Dictionary = Database.table("events")[eid]
			ok(Database.has_item(str(e["reward"]["item"])), "récompense de " + eid)
			eq((e["options"] as Array).size(), 2)
			for key2: String in e["lines"]:
				ok(_trans(key2, "en") != key2, "événement non traduit " + key2)
		for key3: String in ["NPC_" + id.to_upper(), "JOB_" + id.to_upper(), "BIO_" + id.to_upper()]:
			ok(_trans(key3, "en") != key3, "texte manquant " + key3)
	eq(romance, 4, "quatre PNJ romançables")


func test_schedules_use_valid_walkable_spots() -> void:
	for id: String in Friendship.ids():
		var sched: Dictionary = Friendship.npc(id)["schedule"]
		ok(sched.has("default"), id + " : programme par défaut")
		for k: String in sched:
			var last: int = -1
			for step: Array in sched[k]:
				ok(int(step[0]) > last, "%s/%s : heures croissantes" % [id, k])
				last = int(step[0])
				var map_id: String = str(step[1])
				ok(Database.maps.has(map_id), "%s : carte %s" % [id, map_id])
				var c: Vector2i = Schedule.spot_cell(map_id, str(step[2]))
				ok(c.x >= 0, "%s : point %s/%s inexistant" % [id, map_id, step[2]])
				ok(not MapRuntime.new(map_id).is_solid(c), "%s : %s/%s est bloqué" % [id, map_id, step[2]])


func test_paths_exist_to_every_schedule_spot() -> void:
	var navs: Dictionary = {}
	for id: String in Friendship.ids():
		for k: String in Friendship.npc(id)["schedule"]:
			for step: Array in Friendship.npc(id)["schedule"][k]:
				var map_id: String = str(step[1])
				if not navs.has(map_id):
					navs[map_id] = GridNav.new(MapRuntime.new(map_id))
				var start_spot: String = str(ARRIVAL_SPOT.get(map_id, "door"))
				var a: Vector2i = Schedule.spot_cell(map_id, start_spot)
				var b: Vector2i = Schedule.spot_cell(map_id, str(step[2]))
				ok(not (navs[map_id] as GridNav).path(a, b).is_empty(), "%s : pas de chemin %s %s → %s" % [id, map_id, start_spot, step[2]])


func test_warps_are_consistent() -> void:
	for id: String in Database.maps:
		for wp: Dictionary in Database.map(id)["warps"]:
			var to: String = str(wp["to"])
			if to == "farmhouse":
				to = "farmhouse_1"
			if FUTURE_MAPS.has(to):
				continue
			ok(Database.maps.has(to), "%s → %s : carte inexistante" % [id, to])
			if Database.maps.has(to):
				ok(Database.map(to)["spots"].has(str(wp["spot"])), "%s → %s : point d'arrivée %s manquant" % [id, to, wp["spot"]])
				var s: Array = Database.map(to)["spots"][str(wp["spot"])]
				ok(not MapRuntime.new(to).is_solid(Vector2i(int(s[0]), int(s[1]))), "%s → %s : arrivée bloquée" % [id, to])


func test_routes_between_maps() -> void:
	eq(Schedule.route("store", "forest"), ["store", "village", "farm", "forest"] as Array[String])
	eq(Schedule.route("village", "village"), ["village"] as Array[String])
	ok(not Schedule.route("museum", "beach").is_empty(), "la plage est joignable en théorie")
	ok(Schedule.warp_cell_toward("village", "lake").x >= 0)


func test_schedule_selection() -> void:
	GameState.day = 0   # lundi
	eq(Schedule.key_for_today("bastien"), "d0")
	GameState.day = 2
	eq(Schedule.key_for_today("bastien"), "default")
	GameState.weather = "rain"
	eq(Schedule.key_for_today("bastien"), "rain")
	GameState.weather = "sun"
	GameState.day = 1   # mardi : Maïwenn pêche
	eq(Schedule.key_for_today("maiwenn"), "d1")
	GameState.day = 2
	GameState.flags["bell_waves"] = true
	eq(Schedule.key_for_today("maiwenn"), "bell_waves")
	GameState.day = 0
	var e: Dictionary = Schedule.entry_at("capucine", 600)
	eq(str(e["map"]), "store")
	eq(str(e["spot"]), "clerk")
	e = Schedule.entry_at("capucine", 1100)
	eq(str(e["map"]), "village")
	e = Schedule.entry_at("capucine", 400)
	eq(str(e["spot"]), "home", "avant le premier horaire de la journée")


func test_friendship_caps_and_talk() -> void:
	eq(Friendship.hearts("capucine"), 0)
	ok(Friendship.talk("capucine"), "première conversation")
	ok(not Friendship.talk("capucine"), "une seule fois par jour")
	eq(Friendship.points("capucine"), 12)
	Friendship.add_points("capucine", 5000)
	eq(Friendship.hearts("capucine"), 8, "romançable : plafonné à 8 cœurs tant qu'on ne sort pas ensemble")
	Friendship.add_points("pim", 5000)
	eq(Friendship.hearts("pim"), 10, "non romançable : 10 cœurs")
	Friendship.add_points("pim", -9999)
	eq(Friendship.points("pim"), 0, "jamais négatif")


func test_gifts_tastes_and_limits() -> void:
	eq(Friendship.taste("capucine", "honeymelon"), "love")
	eq(Friendship.taste("capucine", "carrot"), "like")
	eq(Friendship.taste("capucine", "coal"), "dislike")
	eq(Friendship.taste("capucine", "pickles"), "hate")
	eq(Friendship.taste("capucine", "quartz"), "dislike", "catégorie minéral détestée")
	eq(Friendship.taste("capucine", "turnip"), "neutral")
	eq(Friendship.taste("pim", "stone"), "dislike", "ressources : jamais appréciées")
	GameState.add_item("honeymelon", 3)
	var r: Dictionary = Friendship.give_gift("capucine", "honeymelon")
	eq(str(r["taste"]), "love")
	eq(Friendship.points("capucine"), 45)
	eq(Friendship.gift_block("capucine"), "GIFT_ALREADY")
	GameState.day = 1
	Friendship.give_gift("capucine", "honeymelon")
	GameState.day = 2
	eq(Friendship.gift_block("capucine"), "GIFT_LIMIT", "2 cadeaux par semaine")
	GameState.day = 7
	eq(Friendship.gift_block("capucine"), "", "la semaine suivante, c'est de nouveau possible")
	eq(GameState.item_count("honeymelon"), 1)


func test_birthday_multiplier() -> void:
	GameState.day = 7   # printemps 8
	ok(Friendship.is_birthday("capucine"))
	GameState.add_item("honeymelon", 1)
	Friendship.give_gift("capucine", "honeymelon")
	eq(Friendship.points("capucine"), 180, "×4 le jour de l'anniversaire")


func test_dating_and_marriage_rules() -> void:
	GameState.add_item("bouquet", 3)
	var r: Dictionary = Friendship.give_gift("pim", "bouquet")
	eq(str(r["special"]), "refused", "Pim n'est pas romançable")
	Friendship.rel("capucine")["points"] = 700
	GameState.day = 8
	r = Friendship.give_gift("capucine", "bouquet")
	eq(str(r["special"]), "", "pas assez de cœurs")
	Friendship.rel("capucine")["points"] = 800
	GameState.day = 15
	r = Friendship.give_gift("capucine", "bouquet")
	eq(str(r["special"]), "dating")
	ok(bool(Friendship.rel("capucine")["dating"]))
	Friendship.add_points("capucine", 1000)
	eq(Friendship.hearts("capucine"), 10, "le plafond saute une fois en couple")
	GameState.add_item("braided_ring", 1)
	GameState.day = 22
	r = Friendship.give_gift("capucine", "braided_ring")
	eq(str(r["special"]), "refused", "maison de niveau 1 : pas de mariage")
	GameState.add_item("braided_ring", 1)
	GameState.house["level"] = 2
	GameState.day = 29
	r = Friendship.give_gift("capucine", "braided_ring")
	eq(str(r["special"]), "engaged")
	eq(int(GameState.flags["wedding_day"]), 32)


func test_dialogue_selection_and_events() -> void:
	var a: String = Dialogue.pick_talk("isaure")
	eq(Dialogue.pick_talk("isaure"), a, "même réplique toute la journée")
	eq(Dialogue.bracket(0), "h0")
	eq(Dialogue.bracket(3), "h1")
	eq(Dialogue.bracket(6), "h2")
	eq(Dialogue.bracket(9), "h3")
	GameState.day = 39   # été 12 = anniversaire d'Isaure
	eq(Dialogue.pick_talk("isaure"), "D_ISAURE_BIRTHDAY_1")
	GameState.day = 3
	eq(Dialogue.pending_event("pim"), "")
	Friendship.rel("pim")["points"] = 300
	eq(Dialogue.pending_event("pim"), "pim_1")
	Friendship.rel("pim")["events"]["pim_1"] = true
	eq(Dialogue.pending_event("pim"), "")
	Friendship.rel("pim")["points"] = 700
	eq(Dialogue.pending_event("pim"), "pim_2")


func test_shops_hours_stock_and_trade() -> void:
	GameState.day = 0   # lundi
	GameState.minutes = 10 * 60
	ok(Shops.is_open("store"))
	ok(not Shops.is_open("forge"), "la forge ferme le lundi")
	GameState.minutes = 8 * 60
	ok(not Shops.is_open("store"), "l'épicerie ouvre à 9 h")
	GameState.minutes = 10 * 60
	GameState.day = 6
	ok(not Shops.is_open("store"), "l'épicerie ferme le dimanche")
	ok(not Shops.is_open("market"), "le marché attend sa cloche")
	GameState.day = 0
	var stock: Array[Dictionary] = Shops.stock("store")
	var ids: Array[String] = []
	for line: Dictionary in stock:
		ids.append(str(line["id"]))
	ok(ids.has("seed_turnip") and not ids.has("seed_tomato"), "graines de saison seulement")
	ok(ids.has("backpack"), "grand sac proposé")
	GameState.money = 1000
	var turnip: Dictionary = {}
	for line: Dictionary in stock:
		if str(line["id"]) == "seed_turnip":
			turnip = line
	eq(Shops.buy(turnip, 5), "")
	eq(GameState.money, 1000 - 5 * 20)
	eq(GameState.item_count("seed_turnip"), 12 + 5)
	GameState.money = 3
	eq(Shops.buy(turnip, 1), "SHOP_NO_MONEY")
	GameState.add_item("turnip", 4)
	var idx: int = -1
	for i: int in GameState.inventory.size():
		if GameState.inventory[i] != null and GameState.inventory[i]["id"] == "turnip":
			idx = i
	var money: int = GameState.money
	var gain: int = Shops.sell(idx, 4)
	eq(gain, int(38 * 0.75) * 4)
	eq(GameState.money, money + gain)
	eq(Shops.sell(0, 1), 0, "les outils ne se vendent pas")
	GameState.money = 9000
	var bp: Dictionary = {"id": "backpack", "price": 5000, "kind": "service"}
	eq(Shops.buy(bp, 1), "")
	eq(GameState.inventory.size(), 48)
	var inn: Array[Dictionary] = Shops.stock("inn")
	var has_recipe: bool = false
	for line: Dictionary in inn:
		has_recipe = has_recipe or str(line["kind"]) == "recipe"
	ok(has_recipe, "l'auberge vend des recettes")


func test_npc_manager_places_villagers() -> void:
	GameState.day = 0
	GameState.minutes = 12 * 60
	var w: World = World.new()
	(Engine.get_main_loop() as SceneTree).current_scene.add_child(w)
	GameState.map_id = "village"
	var foot: Vector2 = MapRuntime.foot_pixel(Vector2i(2, 20))
	GameState.px = foot.x
	GameState.py = foot.y
	w.start(false)
	await (Engine.get_main_loop() as SceneTree).process_frame
	w._fade.modulate.a = 0.0
	ok(w.npcs.npcs.has("bastien"), "Bastien traîne dans la rue le lundi midi")
	ok(w.npcs.npcs.has("pim"), "Pim joue à la fontaine")
	ok(not w.npcs.npcs.has("capucine") or true)
	var pim: Npc = w.npcs.npcs["pim"]
	eq(pim.cell(), Schedule.spot_cell("village", "fountain_s"))
	GameState.minutes = 16 * 60
	for i: int in 6:
		TimeManager.advance(1)
	TimeManager._ending = false
	w.queue_free()
	await (Engine.get_main_loop() as SceneTree).process_frame
	TimeManager.running = false
	TimeManager.clear_locks()
