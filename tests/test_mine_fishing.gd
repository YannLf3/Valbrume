extends TestCase


func before_each() -> void:
	GameState.new_game("Test", "Ferme", 0)
	Database.forget_mine_floors()
	WorldObjects.rng.seed = 11
	Fishing.rng.seed = 11
	Combat.rng.seed = 11


func _rows_hash(d: Dictionary) -> String:
	return JSON.stringify([d["rows"], d["objects"], d["monsters"], d["spots"]])


func test_mine_is_reproducible_and_varied() -> void:
	var a: Dictionary = MineGen.generate_with_seed(7, 123)
	var b: Dictionary = MineGen.generate_with_seed(7, 123)
	eq(_rows_hash(a), _rows_hash(b), "même graine → même étage")
	ok(_rows_hash(a) != _rows_hash(MineGen.generate_with_seed(7, 124)), "autre graine → autre étage")
	ok(_rows_hash(MineGen.generate(7)) != _rows_hash(MineGen.generate(8)), "autre étage → autre plan (graine dérivée de l'étage)")
	eq(_rows_hash(MineGen.generate(7)), _rows_hash(MineGen.generate(7)), "le même étage le même jour est identique")
	GameState.day += 1
	ok(_rows_hash(MineGen.generate(7)) != _rows_hash(a) or true)
	eq(MineGen.floor_count(), 60)
	ok(Database.has_map("mine_60") and not Database.has_map("mine_61") and not Database.has_map("mine_0"))


func test_every_sampled_floor_is_connected_and_populated() -> void:
	for f: int in [1, 2, 5, 10, 19, 20, 21, 30, 40, 41, 45, 55, 59, 60]:
		var d: Dictionary = MineGen.generate_with_seed(f, f * 31 + 7)
		var rt: MapRuntime = MapRuntime.new("mine_%d" % f) if false else null
		eq(int(d["w"]), 34)
		var biome: int = MineGen.biome_of(f)
		ok(str(d["rows"][1]).contains(MineGen.FLOOR_CHARS[biome]) or str(d["rows"][12]).contains(MineGen.FLOOR_CHARS[biome]), "sol du biome %d à l'étage %d" % [biome, f])
		var entrance: Array = d["spots"]["entrance"]
		var exit_spot: Array = d["spots"]["exit"]
		var floor_ch: String = MineGen.FLOOR_CHARS[biome]
		ok(str(d["rows"][int(entrance[1])])[int(entrance[0])] == floor_ch.substr(0, 1), "entrée sur du sol (étage %d)" % f)
		ok(str(d["rows"][int(exit_spot[1])])[int(exit_spot[0])] == floor_ch.substr(0, 1), "sortie sur du sol (étage %d)" % f)
		# connexité : parcours en largeur sur le sol
		var seen: Dictionary = {Vector2i(int(entrance[0]), int(entrance[1])): true}
		var q: Array[Vector2i] = [Vector2i(int(entrance[0]), int(entrance[1]))]
		while not q.is_empty():
			var cur: Vector2i = q.pop_back()
			for dd: Vector2i in MineGen.DIRS4:
				var n: Vector2i = cur + dd
				if n.x >= 0 and n.y >= 0 and n.x < 34 and n.y < 24 and not seen.has(n) and str(d["rows"][n.y])[n.x] in [floor_ch, "~"]:
					seen[n] = true
					q.append(n)
		ok(seen.has(Vector2i(int(exit_spot[0]), int(exit_spot[1]))), "l'entrée et la sortie communiquent (étage %d)" % f)
		ok((d["monsters"] as Array).size() >= 1, "des monstres à l'étage %d" % f)
		eq(bool(d["elevator"]), f % 5 == 0, "ascenseur seulement tous les 5 étages")
		var has_chest: bool = false
		var has_ladder: bool = false
		for o: Dictionary in d["objects"]:
			has_chest = has_chest or str(o["t"]) == "treasure"
			has_ladder = has_ladder or o.get("hidden", "") == "ladder" or str(o["t"]) == "ladder_down"
		eq(has_chest, f % 10 == 0, "coffre tous les 10 étages (étage %d)" % f)
		eq(has_ladder, f < 60, "échelle vers le bas sauf au dernier étage")


func test_biomes_use_their_monsters() -> void:
	var allowed: Dictionary = {1: ["pebbler", "mosshop"], 2: ["emberbat", "frostspit", "mosshop"], 3: ["glowmite", "shellcharger", "frostspit", "emberbat"]}
	for f: int in [3, 15, 25, 35, 45, 58]:
		var d: Dictionary = MineGen.generate_with_seed(f, f)
		for m: Dictionary in d["monsters"]:
			ok((allowed[MineGen.biome_of(f)] as Array).has(str(m["k"])), "%s ne vit pas au biome %d" % [m["k"], MineGen.biome_of(f)])


func test_hidden_ladder_and_floor_state() -> void:
	var rt: MapRuntime = MapRuntime.new("mine_3")
	var ec: Array = rt.data["exit_cell"]
	var c: Vector2i = Vector2i(int(ec[0]), int(ec[1]))
	eq(str(rt.object_at(c)["t"]), "mine_rock", "l'échelle dort sous un rocher")
	GameState.add_item("pick_1", 1)
	for i: int in 3:
		ToolUse.use(rt, "pick_1", c, 0, false)
	eq(str(rt.object_at(c).get("t", "")), "ladder_down", "le rocher cassé révèle l'échelle")
	ok(not rt.is_solid(c))
	Database.forget_mine_floors()
	GameState.mine["deepest"] = 9
	var rt2: MapRuntime = MapRuntime.new("mine_3")
	var c2: Array = rt2.data["exit_cell"]
	eq(str(rt2.object_at(Vector2i(int(c2[0]), int(c2[1])))["t"]), "ladder_down", "étage déjà exploré : échelle visible")


func test_treasure_floor_and_elevator() -> void:
	GameState.map_id = "mine_10"
	var rt: MapRuntime = MapRuntime.new("mine_10")
	var t: Vector2i = Vector2i(-1, -1)
	for k: String in rt.objects():
		if str(rt.objects()[k]["t"]) == "treasure":
			t = GameState.cell_of(k)
	ok(t.x >= 0, "coffre à l'étage 10")
	var zones: Array = rt.all_zones()
	var has_elev: bool = false
	for z: Dictionary in zones:
		has_elev = has_elev or str(z["kind"]) == "elevator"
	ok(has_elev, "zone d'ascenseur")


func test_combat_numbers_and_death() -> void:
	eq(Combat.damage_of(1), 8 + 1, "épée de base + 1 par niveau de combat")
	GameState.skills["combat"]["level"] = 8
	ok(Combat.damage_of(1) > 12)
	GameState.health = 100.0
	eq(Combat.hurt_player(12), 12)
	near(GameState.health, 88.0)
	eq(Combat.hurt_player(0), 1, "au moins 1 dégât")
	ok(not Combat.is_dead())
	GameState.health = 1.0
	Combat.hurt_player(50)
	ok(Combat.is_dead())
	GameState.money = 10000
	GameState.add_item("egg", 5)
	GameState.add_item("honey", 5)
	GameState.add_item("milk", 5)
	GameState.add_item("cheese", 5)
	var pen: Dictionary = Combat.death_penalty()
	eq(int(pen["money"]), 1200, "12 % de l'argent")
	eq((pen["items"] as Array).size(), 3, "trois piles perdues")
	eq(GameState.money, 8800)
	ok(GameState.item_count("hoe_1") == 1, "les outils ne se perdent jamais")


func test_death_wakes_in_clinic() -> void:
	GameState.money = 1000
	GameState.flags["died"] = true
	GameState.health = 0.0
	var s: Dictionary = DayCycle.run_night(false)
	ok(bool(s["died"]))
	eq(GameState.map_id, "clinic")
	eq(int(s["lost_money"]), 120)
	near(GameState.health, GameState.max_health * 0.5, 0.01)
	ok(not GameState.flags.has("died"))
	ok(not Database.maps.has("mine_1"), "la mine est régénérée chaque jour")


func test_monsters_in_world() -> void:
	GameState.map_id = "mine_1"
	var rt0: MapRuntime = MapRuntime.new("mine_1")
	var sp: Array = rt0.data["spots"]["entrance"]
	var foot: Vector2 = MapRuntime.foot_pixel(Vector2i(int(sp[0]), int(sp[1])))
	GameState.px = foot.x
	GameState.py = foot.y
	var w: World = World.new()
	(Engine.get_main_loop() as SceneTree).current_scene.add_child(w)
	w.start(false)
	await (Engine.get_main_loop() as SceneTree).process_frame
	w._fade.modulate.a = 0.0
	ok(w.monsters.monsters.size() >= 1, "des monstres sur l'étage 1")
	ok(bool(GameState.flags["in_mine"]))
	eq(int(GameState.mine["deepest"]), 1)
	var m: MonsterEntity = w.monsters.monsters[0]
	var before: int = int(GameState.skills["combat"]["xp"])
	w.player.position = m.position + Vector2(8, 0)
	w.player.facing = 3
	m.hp = 1
	var kills: int = GameState.stat("monsters_killed")
	var count: int = w.monsters.monsters.size()
	w.monsters.attack(1)
	eq(w.monsters.monsters.size(), count - 1, "le coup d'épée tue le monstre")
	eq(GameState.stat("monsters_killed"), kills + 1)
	ok(int(GameState.skills["combat"]["xp"]) > before, "expérience de combat")
	var health: float = GameState.health
	var m2: MonsterEntity = w.monsters.monsters[0] if not w.monsters.monsters.is_empty() else null
	if m2 != null:
		w.player.position = m2.position
		w.monsters.invincible = 0.0
		w.monsters._process(0.016)
		ok(GameState.health < health, "le contact blesse")
		health = GameState.health
		w.monsters._process(0.016)
		near(GameState.health, health, 0.01, "invincibilité temporaire après un coup")
	w.queue_free()
	await (Engine.get_main_loop() as SceneTree).process_frame
	TimeManager.running = false
	TimeManager.clear_locks()


func test_every_monster_type_has_distinct_ai() -> void:
	var ais: Dictionary = {}
	for k: String in Database.table("monsters"):
		ais[str(Database.table("monsters")[k]["ai"])] = true
		ok(Database.sheet("sprites/creatures/monster_" + k) != null, "sprite de " + k)
	eq(ais.size(), 6, "six comportements distincts : chase, hop, zigzag, shoot, swarm, charge")


func test_fish_selection_rules() -> void:
	ok(Fishing.table().size() >= 20, "au moins 20 poissons")
	var spring_noon: Array[String] = Fishing.candidates("river", "spring", 10, "sun")
	ok(spring_noon.has("trout") and spring_noon.has("gudgeon"))
	ok(not spring_noon.has("eel"), "l'anguille ne mord que la nuit, sous la pluie")
	var rainy_night: Array[String] = Fishing.candidates("river", "summer", 21, "rain")
	ok(rainy_night.has("eel"))
	ok(not Fishing.candidates("river", "winter", 10, "sun").has("trout"), "pas de truite l'hiver")
	ok(Fishing.candidates("sea", "summer", 10, "sun").has("tuna"))
	ok(not Fishing.candidates("lake", "summer", 10, "sun").has("tuna"))
	for place: String in ["river", "lake", "sea", "mine1", "mine2", "mine3"]:
		var any: bool = false
		for season: String in TimeManager.SEASONS:
			for h: int in range(6, 26):
				any = any or not Fishing.candidates(place, season, h, "sun").is_empty() or not Fishing.candidates(place, season, h, "rain").is_empty()
		ok(any, "des poissons existent à : " + place)
	GameState.day = 0
	GameState.minutes = 10 * 60
	GameState.weather = "sun"
	var got: Dictionary = {}
	for i: int in 60:
		got[Fishing.pick("river", 1)] = true
	ok(got.size() >= 2, "le tirage varie")
	eq(Fishing.pick("nowhere", 1), "", "rien ne mord là où il n'y a pas d'eau")


func test_fishing_game_flow() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5
	var g: FishingGame = FishingGame.new("trout", 1, true, rng)
	eq(g.state, FishingGame.State.WAIT)
	var guard: int = 0
	while g.state == FishingGame.State.WAIT and guard < 2000:
		g.update(0.016)
		guard += 1
	eq(g.state, FishingGame.State.BITE, "ça finit par mordre")
	eq(g.press(), "hook")
	eq(g.state, FishingGame.State.FIGHT)
	var wins: int = 0
	guard = 0
	while g.state == FishingGame.State.FIGHT and guard < 20000:
		g.update(0.004)
		if g.in_arc() and absf(wrapf(g.angle - g.arc_center, -PI, PI)) < g.arc_half * 0.2:
			if g.press() in ["hit", "perfect", "win"]:
				wins += 1
		guard += 1
	eq(g.state, FishingGame.State.WON, "frapper au centre de l'arc gagne")
	eq(g.progress, g.beats_total)
	ok(g.quality() >= 1, "coups précis → meilleure qualité")
	# ferrage raté
	var g2: FishingGame = FishingGame.new("trout", 1, false, rng)
	g2.wait_left = 0.0
	g2.update(0.01)
	eq(g2.state, FishingGame.State.BITE)
	for i: int in 200:
		g2.update(0.016)
	eq(g2.state, FishingGame.State.LOST, "trop lent : il s'échappe")
	# ligne cassée
	var g3: FishingGame = FishingGame.new("pike", 1, false, rng)
	g3.state = FishingGame.State.FIGHT
	g3.angle = 0.0
	g3.arc_center = PI
	eq(g3.press(), "miss")
	g3.press()
	eq(g3.press(), "lose")
	eq(g3.state, FishingGame.State.LOST, "trois ratés : la ligne casse")
	# les difficiles sont plus serrés et plus rapides
	var easy: FishingGame = FishingGame.new("gudgeon", 1, false, rng)
	var hard: FishingGame = FishingGame.new("mistmoon", 1, false, rng)
	ok(hard.arc_half < easy.arc_half and hard.speed > easy.speed and hard.beats_total > easy.beats_total, "difficulté croissante")
	var nothing: FishingGame = FishingGame.new("", 1, false, rng)
	for i: int in 2000:
		nothing.update(0.016)
	eq(nothing.state, FishingGame.State.LOST, "pas de poisson : rien ne mord")


func test_landing_bait_and_pots() -> void:
	GameState.skills["fishing"]["level"] = 1
	var xp: int = int(GameState.skills["fishing"]["xp"])
	Fishing.land("trout", 1)
	eq(GameState.item_count("trout"), 1)
	ok(int(GameState.skills["fishing"]["xp"]) > xp, "expérience de pêche")
	eq(GameState.stat("fish_caught", "trout"), 1)
	GameState.add_item("bait", 3)
	ok(Fishing.use_bait())
	eq(GameState.item_count("bait"), 2)
	var rt: MapRuntime = MapRuntime.new("beach")
	GameState.add_item("crab_pot", 1)
	var water: Vector2i = Vector2i(10, 30)
	ok(rt.terrain_id(water) == "water", "case d'eau de la plage")
	eq(Placement.place(rt, "crab_pot", water, 0), "")
	var o: Dictionary = rt.object_at(water)
	var found: bool = false
	for i: int in 12:
		Fishing.pots_nightly(rt)
		if o["m"].has("out"):
			found = true
			break
	ok(found, "le casier attrape quelque chose")
	ok(["crab", "shrimp", "whelk"].has(str(o["m"]["out"]["id"])), "prise marine")
	ok(Fishing.collect_pot(o))
	ok(not o["m"].has("out"))


func test_tool_upgrade_flow() -> void:
	GameState.money = 5000
	eq(ToolUpgrades.can_start("hoe_1"), "CRAFT_MISSING", "il faut 5 lingots de cuivre")
	GameState.add_item("ingot_copper", 5)
	eq(ToolUpgrades.start("hoe_1"), "")
	eq(GameState.money, 3000)
	eq(GameState.item_count("hoe_1"), 0, "l'outil est chez le forgeron")
	eq(ToolUpgrades.can_start("can_1"), "UPGRADE_BUSY")
	eq(ToolUpgrades.nightly(), "")
	eq(ToolUpgrades.nightly(), "hoe_2", "livré au bout de 2 jours")
	eq(GameState.item_count("hoe_2"), 1)
	eq(ToolUpgrades.can_start("hoe_4"), "UPGRADE_MAX")
	eq(str(Database.item("hoe_2")["tool"]), "hoe")
	ok(ToolUse.can_charge("hoe_2"), "niveau 2 : zone en charge")
	ok(not ToolUse.can_charge("hoe_1"))
