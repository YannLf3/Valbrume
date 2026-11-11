class_name WorldObjects
extends RefCounted
## Objets du monde (rochers, arbres, herbes…) : définitions, dégâts, butin, apparition quotidienne.

static var rng: RandomNumberGenerator = RandomNumberGenerator.new()


static func defs() -> Dictionary:
	return Database.table("objects").get("world", {})


static func places() -> Dictionary:
	return Database.table("objects").get("place", {})


static func def_of(o: Dictionary) -> Dictionary:
	if str(o.get("t", "")) == "placed":
		return places().get(str(o.get("p", "")), {})
	return defs().get(str(o.get("t", "")), {})


static func size_of(o: Dictionary) -> Vector2i:
	var d: Dictionary = def_of(o)
	return Vector2i(int(d.get("w", 1)), int(d.get("h", 1)))


## Nom du sprite d'un objet dans l'atlas (gabarit de la définition + état).
static func sprite_name(o: Dictionary, season: String, biome: String) -> String:
	var d: Dictionary = def_of(o)
	var t: String = str(o.get("t", ""))
	if t == "ftree" and int(o.get("g", 2)) >= 2 and bool(o.get("fruit", false)):
		return "ftree_%s_fruit" % str(o.get("k", ""))
	var tpl: String = str(d.get("sprite", ""))
	if tpl == "":
		return ""
	tpl = tpl.replace("%v", str(int(o.get("v", 0))))
	tpl = tpl.replace("%k", str(o.get("k", "oak")))
	tpl = tpl.replace("%s", season)
	tpl = tpl.replace("%g", str(int(o.get("g", 2))))
	tpl = tpl.replace("%b", biome)
	tpl = tpl.replace("%c", str(o.get("c", "ice")))
	return tpl


## Un coup d'outil. Renvoie {"ok": bool, "broke": bool}.
static func hit(rt: MapRuntime, origin: Vector2i, tool_id: String, power: int) -> Dictionary:
	var key: String = GameState.key(origin)
	var o: Dictionary = rt.state["objects"].get(key, {})
	if o.is_empty():
		return {"ok": false, "broke": false}
	var d: Dictionary = def_of(o)
	if not (d.get("tools", []) as Array).has(tool_id):
		return {"ok": false, "broke": false}
	var t: String = str(o.get("t", ""))
	if t == "tree" and int(o.get("g", 2)) < 2:
		pass  # les jeunes arbres cèdent au premier coup
	elif power < int(d.get("min_level", 1)):
		AudioManager.sfx("error")
		EventBus.toast.emit(Loc.t("TOAST_TOO_WEAK"), "")
		return {"ok": true, "broke": false}
	var damage: int = power
	if t == "tree" and int(o.get("g", 2)) < 2:
		damage = 99
	o["hp"] = int(o.get("hp", d.get("hp", 1))) - damage
	AudioManager.sfx(str(d.get("sfx", "pick")))
	EventBus.fx_requested.emit(str(d.get("fx", "dust")), Vector2(origin * MapRuntime.T) + Vector2(MapRuntime.T, MapRuntime.T) * 0.5)
	if int(o["hp"]) > 0:
		rt.touch_object(origin)
		EventBus.object_changed.emit(rt.id, origin)
		return {"ok": true, "broke": false}
	_break(rt, origin, o, d)
	return {"ok": true, "broke": true}


static func _biome(rt: MapRuntime) -> String:
	return str(rt.data.get("gem_biome", "1"))


static func _break(rt: MapRuntime, origin: Vector2i, o: Dictionary, d: Dictionary) -> void:
	var t: String = str(o.get("t", ""))
	var sfx: String = str(d.get("break_sfx", ""))
	if sfx != "":
		AudioManager.sfx(sfx)
	for drop: Array in d.get("drops", []):
		if rng.randf() > float(drop[3]):
			continue
		var id: String = str(drop[0])
		var n: int = rng.randi_range(int(drop[1]), int(drop[2]))
		if id == "@gem":
			id = pick_gem(_biome(rt))
		if t.begins_with("node_") and rng.randf() < Skills.perk("ore_bonus"):
			n *= 2
		if t == "tree" and rng.randf() < Skills.perk("wood_bonus") and id == "wood":
			n += n / 3
		Loot.give(id, n)
	if d.has("hay"):
		Loot.give("hay", int(d["hay"]))
	var xp: Array = d.get("xp", [])
	if xp.size() == 2:
		Skills.add_xp(str(xp[0]), int(xp[1]))
	if t == "tree":
		GameState.add_stat("trees_felled")
	elif t.begins_with("node_") or t.begins_with("rock") or t == "mine_rock":
		GameState.add_stat("rocks_broken")
	rt.remove_object(origin)
	if t == "tree":
		rt.add_object(origin, {"t": "stump", "k": str(o.get("k", "oak")), "hp": int(defs()["stump"]["hp"])})


static func pick_gem(biome: String) -> String:
	var weights: Dictionary = Database.table("objects").get("gems", {}).get(biome, {"quartz": 1})
	var total: int = 0
	for k: String in weights:
		total += int(weights[k])
	var r: int = rng.randi_range(1, total)
	for k: String in weights:
		r -= int(weights[k])
		if r <= 0:
			return k
	return "quartz"


## Identifiants des objets de cueillette de la saison (ou d'un ensemble sans saison : plage).
static func forage_ids(season: String, set_name: String) -> Array[String]:
	var out: Array[String] = []
	for id: String in Database.items:
		var it: Dictionary = Database.items[id]
		if str(it.get("cat", "")) != "forage":
			continue
		var s: String = str(it.get("season", ""))
		if set_name == "beach":
			if s == "":
				out.append(id)
		elif s == season:
			out.append(id)
	return out


## Apparitions quotidiennes : mauvaises herbes, cueillette, taches de fouille.
static func daily_update(rt: MapRuntime) -> void:
	if not bool(rt.data.get("outdoor", false)):
		return
	var farm: bool = bool(rt.data.get("farmable", false)) and not bool(rt.data.get("greenhouse", false))
	if farm:
		var chance: float = Database.bal_f("weed_spread_chance", 0.02)
		for i: int in int(rt.w * rt.h * chance):
			var c: Vector2i = _random_free(rt)
			if c.x >= 0:
				rt.add_object(c, {"t": "weed", "v": rng.randi_range(0, 2), "hp": 1})
	var forage_n: int = 0
	var dig_n: int = 0
	for k: String in rt.objects():
		var t: String = str(rt.objects()[k].get("t", ""))
		if t == "forage":
			forage_n += 1
		elif t == "dig":
			dig_n += 1
	var set_name: String = str(rt.data.get("forage", "seasonal"))
	var ids: Array[String] = forage_ids(TimeManager.season_id(), set_name)
	var want: int = mini(Database.bal_i("forage_per_map", 5) - forage_n, 3)
	for i: int in maxi(0, want):
		var c2: Vector2i = _random_free(rt, set_name == "beach")
		if c2.x >= 0 and not ids.is_empty():
			rt.add_object(c2, {"t": "forage", "id": ids[rng.randi_range(0, ids.size() - 1)], "hp": 1})
	for i: int in maxi(0, mini(Database.bal_i("dig_spots_per_map", 2) - dig_n, 2)):
		var c3: Vector2i = _random_free(rt)
		if c3.x >= 0:
			rt.add_object(c3, {"t": "dig", "hp": 1})


static func _random_free(rt: MapRuntime, sand: bool = false) -> Vector2i:
	for i: int in 40:
		var c: Vector2i = Vector2i(rng.randi_range(2, rt.w - 3), rng.randi_range(2, rt.h - 3))
		var tid: String = rt.terrain_id(c)
		if tid != ("sand" if sand else "grass"):
			continue
		if rt.is_solid(c) or rt.origin_at(c) != null or not rt.soil_at(c).is_empty():
			continue
		if not rt.warp_at(c).is_empty():
			continue
		return c
	return Vector2i(-1, -1)
