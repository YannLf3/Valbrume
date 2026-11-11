class_name Farming
extends RefCounted
## Labour, semis, arrosage, croissance nocturne, récolte.

static var rng: RandomNumberGenerator = RandomNumberGenerator.new()


static func crop_def(crop_id: String) -> Dictionary:
	return Database.crops.get(crop_id, {})


## Stade d'affichage : 0 graine … 3 en croissance, 4 mûr, 5 repousse après récolte, -1 mort.
static func stage_of(crop: Dictionary) -> int:
	if bool(crop.get("dead", false)):
		return -1
	var days: int = maxi(1, int(crop_def(str(crop["id"])).get("days", 1)))
	var age: int = int(crop["age"])
	if age >= days:
		return 4
	if bool(crop.get("h", false)):
		return 5
	return mini(3, age * 4 / days)


static func is_mature(crop: Dictionary) -> bool:
	return not crop.is_empty() and stage_of(crop) == 4


static func season_ok(rt: MapRuntime, crop_id: String) -> bool:
	return bool(rt.data.get("greenhouse", false)) or str(crop_def(crop_id).get("season", "")) == TimeManager.season_id()


static func can_till(rt: MapRuntime, c: Vector2i) -> bool:
	if not bool(rt.data.get("farmable", false)) or not rt.in_bounds(c):
		return false
	var tid: String = rt.terrain_id(c)
	if tid != "grass" and tid != "dirt":
		return false
	return not rt.is_solid(c) and rt.origin_at(c) == null and rt.soil_at(c).is_empty()


static func till(rt: MapRuntime, c: Vector2i) -> void:
	rt.set_soil(c, {"w": 0})
	GameState.add_stat("tiles_tilled")


static func water(rt: MapRuntime, c: Vector2i) -> bool:
	var s: Dictionary = rt.soil_at(c)
	if s.is_empty() or int(s.get("w", 0)) == 1:
		return false
	s["w"] = 1
	rt.touch_soil(c)
	return true


## Plante une graine. Renvoie "" en cas de succès, sinon la clé de traduction de l'erreur.
static func plant(rt: MapRuntime, c: Vector2i, seed_id: String) -> String:
	var s: Dictionary = rt.soil_at(c)
	if s.is_empty():
		return "TOAST_NEED_SOIL"
	if s.has("crop"):
		return "TOAST_OCCUPIED"
	var cid: String = str(Database.item(seed_id).get("crop", ""))
	if cid == "" or not crop_def(cid).has("days"):
		return "TOAST_NEED_SOIL"
	if not season_ok(rt, cid):
		return "TOAST_WRONG_SEASON"
	s["crop"] = {"id": cid, "age": 0}
	rt.touch_soil(c)
	GameState.add_stat("seeds_planted")
	return ""


static func fertilize(rt: MapRuntime, c: Vector2i, item_id: String) -> bool:
	var s: Dictionary = rt.soil_at(c)
	if s.is_empty() or s.has("crop") or s.has("fert"):
		return false
	s["fert"] = item_id
	rt.touch_soil(c)
	return true


static func roll_quality(fert: String) -> int:
	var fq: Dictionary = Database.bal("fertilizer_quality", {})
	var level: int = Skills.effective_level("farming")
	var q: float = float(fq.get(fert, 0.0)) + level * Database.bal_f("quality_per_level") + Skills.perk("crop_quality")
	var r: float = rng.randf()
	if r < q * Database.bal_f("quality_gold_ratio", 0.4):
		return 2
	if r < q + Database.bal_f("quality_silver_base"):
		return 1
	return 0


## Récolte une culture mûre. Renvoie vrai si quelque chose a été cueilli.
static func harvest(rt: MapRuntime, c: Vector2i) -> bool:
	var s: Dictionary = rt.soil_at(c)
	if s.is_empty() or not s.has("crop"):
		return false
	var crop: Dictionary = s["crop"]
	if bool(crop.get("dead", false)):
		s.erase("crop")
		rt.touch_soil(c)
		return true
	if not is_mature(crop):
		return false
	var cid: String = str(crop["id"])
	if GameState.add_item(cid, 1, roll_quality(str(s.get("fert", "")))) > 0:
		EventBus.toast.emit(Loc.t("TOAST_INV_FULL"), cid)
		return false
	var cd: Dictionary = crop_def(cid)
	var price: int = int(Database.item(cid).get("price", 0))
	Skills.add_xp("farming", Database.bal_i("xp_harvest_base", 5) + price / maxi(1, Database.bal_i("xp_harvest_div", 20)))
	GameState.add_stat("crops_harvested", 1, cid)
	AudioManager.sfx("harvest")
	EventBus.fx_requested.emit("sparkle", Vector2(c * MapRuntime.T) + Vector2(8, 8))
	var regrow: int = int(cd.get("regrow", 0))
	if regrow > 0:
		crop["age"] = int(cd["days"]) - regrow
		crop["h"] = true
	else:
		s.erase("crop")
	rt.touch_soil(c)
	return true


## Fait pousser la nuit. `rains` : la pluie a arrosé les cultures de plein air.
## Renvoie {"eaten": n} (cultures mangées par les grignotins).
static func grow_night(rt: MapRuntime, rains: bool) -> Dictionary:
	var out: Dictionary = {"eaten": 0}
	var indoor: bool = bool(rt.data.get("greenhouse", false)) or rt.is_interior()
	_sprinkle(rt)
	var scarecrows: Array[Vector2i] = _scarecrows(rt)
	var radius: float = Database.bal_f("scarecrow_radius", 6.0)
	var pest: float = Database.bal_f("pest_chance", 0.0)
	var pest_ok: bool = GameState.day >= Database.bal_i("pest_start_day", 10) and not indoor
	for k: String in rt.soil().keys():
		var c: Vector2i = GameState.cell_of(k)
		var s: Dictionary = rt.soil()[k]
		var wet: bool = int(s.get("w", 0)) == 1 or (rains and not indoor)
		if s.has("crop") and not bool(s["crop"].get("dead", false)):
			if pest_ok and rng.randf() < pest and not _protected(c, scarecrows, radius):
				s.erase("crop")
				out["eaten"] = int(out["eaten"]) + 1
			elif wet:
				var crop: Dictionary = s["crop"]
				crop["age"] = int(crop["age"]) + 1
				if str(s.get("fert", "")) == "quick_soil" and rng.randf() < Database.bal_f("quick_soil_speed"):
					crop["age"] = int(crop["age"]) + 1
		s["w"] = 0
		if not s.has("crop") and not wet and rng.randf() < Database.bal_f("soil_decay_chance"):
			rt.soil().erase(k)
	return out


static func _sprinkle(rt: MapRuntime) -> void:
	var patterns: Dictionary = Database.bal("sprinkler_patterns", {})
	for k: String in rt.objects():
		var o: Dictionary = rt.objects()[k]
		if str(o.get("t", "")) != "placed" or not str(o.get("p", "")).begins_with("sprinkler"):
			continue
		var pat: Variant = patterns.get(str(o["p"]), [])
		var cells: Array = []
		if typeof(pat) == TYPE_STRING:
			for dy: int in range(-2, 3):
				for dx: int in range(-2, 3):
					if dx != 0 or dy != 0:
						cells.append([dx, dy])
		else:
			cells = pat
		var origin: Vector2i = GameState.cell_of(k)
		for d: Array in cells:
			var s: Dictionary = rt.soil_at(origin + Vector2i(int(d[0]), int(d[1])))
			if not s.is_empty():
				s["w"] = 1


static func _scarecrows(rt: MapRuntime) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for k: String in rt.objects():
		var o: Dictionary = rt.objects()[k]
		if str(o.get("t", "")) == "placed" and str(o.get("p", "")) == "scarecrow":
			out.append(GameState.cell_of(k))
	return out


static func _protected(c: Vector2i, scarecrows: Array[Vector2i], radius: float) -> bool:
	for s: Vector2i in scarecrows:
		if Vector2(c).distance_to(Vector2(s)) <= radius:
			return true
	return false


## Au changement de saison, les cultures de plein air hors saison meurent.
static func season_change(rt: MapRuntime) -> int:
	if bool(rt.data.get("greenhouse", false)):
		return 0
	var killed: int = 0
	for k: String in rt.soil():
		var s: Dictionary = rt.soil()[k]
		if s.has("crop") and not season_ok(rt, str(s["crop"]["id"])) and not bool(s["crop"].get("dead", false)):
			s["crop"]["dead"] = true
			killed += 1
	return killed


# --- arbres fruitiers ----------------------------------------------------------

## Plante une jeune pousse d'arbre fruitier. Renvoie "" ou une clé d'erreur.
static func plant_tree(rt: MapRuntime, c: Vector2i, sapling_id: String) -> String:
	var fruit: String = str(Database.item(sapling_id).get("tree", ""))
	if fruit == "" or not bool(rt.data.get("outdoor", false)):
		return "TOAST_CANT_PLACE"
	if rt.terrain_id(c) != "grass" or rt.is_solid(c) or rt.origin_at(c) != null or not rt.soil_at(c).is_empty():
		return "TOAST_CANT_PLACE"
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			if str(rt.object_at(c + Vector2i(dx, dy)).get("t", "")) == "ftree":
				return "TOAST_CANT_PLACE"
	rt.add_object(c, {"t": "ftree", "k": fruit, "g": 0, "age": 0, "fruit": 0, "hp": 1})
	return ""


static func tree_stage(age: int) -> int:
	var total: int = Database.bal_i("fruit_tree_days", 28)
	if age >= total:
		return 2
	return 1 if age >= total / 4 else 0


## Croissance nocturne des arbres fruitiers : maturité en 28 jours, fruits en saison.
static func grow_trees(rt: MapRuntime) -> void:
	for k: String in rt.objects().keys():
		var o: Dictionary = rt.objects()[k]
		if str(o.get("t", "")) != "ftree":
			continue
		o["age"] = int(o.get("age", 0)) + 1
		o["g"] = tree_stage(int(o["age"]))
		var season: String = str(Database.table("fruit_trees").get(str(o.get("k", "")), {}).get("season", ""))
		if int(o["g"]) >= 2 and season == TimeManager.season_id():
			o["fruit"] = mini(int(o.get("fruit", 0)) + 1, Database.bal_i("fruit_tree_max", 3))
		elif season != TimeManager.season_id():
			o["fruit"] = 0
		rt.touch_object(GameState.cell_of(k))


static func harvest_tree(rt: MapRuntime, origin: Vector2i) -> bool:
	var o: Dictionary = rt.state["objects"].get(GameState.key(origin), {})
	if str(o.get("t", "")) != "ftree" or int(o.get("fruit", 0)) <= 0:
		return false
	var fruit_id: String = str(o["k"])
	var n: int = int(o["fruit"])
	var given: int = 0
	for i: int in n:
		if GameState.add_item(fruit_id, 1, roll_quality("")) > 0:
			EventBus.toast.emit(Loc.t("TOAST_INV_FULL"), fruit_id)
			break
		given += 1
	if given == 0:
		return false
	o["fruit"] = n - given
	Skills.add_xp("foraging", Database.bal_i("xp_forage", 8) * given)
	GameState.add_stat("fruit_picked", given)
	AudioManager.sfx("harvest")
	EventBus.fx_requested.emit("sparkle", Vector2(origin * MapRuntime.T) + Vector2(8, -8))
	rt.touch_object(origin)
	return true
