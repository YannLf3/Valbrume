class_name ToolUse
extends RefCounted
## Utilisation des outils (houe, arrosoir, hache, pioche, faux) sur une ou plusieurs cases.

const FACING: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]
const TILE: float = 16.0


static func kinds() -> Dictionary:
	return Database.table("tools").get("kinds", {})


static func is_tool(item_id: String) -> bool:
	return Database.item(item_id).has("tool")


## Cases touchées : motif de zone selon le niveau (charge maintenue), orienté vers l'avant.
static func area_cells(kind: String, level: int, origin: Vector2i, facing: int, charged: bool) -> Array[Vector2i]:
	var areas: Array = kinds().get(kind, {}).get("areas", [1])
	var n: int = int(areas[clampi(level - 1, 0, areas.size() - 1)]) if charged else 1
	var pattern: Array = Database.table("tools")["areas"][str(n)]
	var f: Vector2i = FACING[facing]
	var r: Vector2i = Vector2i(-f.y, f.x)
	var out: Array[Vector2i] = []
	for p: Array in pattern:
		out.append(origin + r * int(p[0]) + f * int(p[1]))
	return out


static func can_charge(item_id: String) -> bool:
	var it: Dictionary = Database.item(item_id)
	var kind: String = str(it.get("tool", ""))
	var areas: Array = kinds().get(kind, {}).get("areas", [1])
	return int(areas[clampi(int(it.get("level", 1)) - 1, 0, areas.size() - 1)]) > 1


static func energy_cost(kind: String, cells: int, charged: bool) -> float:
	var cfg: Dictionary = kinds().get(kind, {})
	var base: float = Database.bal_f(str(cfg.get("energy", "energy_hoe")))
	var cost: float = base * maxf(0.4, 1.0 - Database.bal_f("energy_skill_discount") * Skills.effective_level(str(cfg.get("skill", "farming"))))
	if charged and cells > 1:
		cost *= cells * Database.bal_f("energy_charge_factor", 0.6)
	return cost


## Utilise l'outil. Renvoie vrai si au moins une case a eu un effet.
static func use(rt: MapRuntime, item_id: String, origin: Vector2i, facing: int, charged: bool) -> bool:
	var it: Dictionary = Database.item(item_id)
	var kind: String = str(it.get("tool", ""))
	var level: int = int(it.get("level", 1))
	if not kinds().has(kind) or kind == "rod" or kind == "sword":
		return false
	var cells: Array[Vector2i] = area_cells(kind, level, origin, facing, charged)
	var cost: float = energy_cost(kind, cells.size(), charged)
	if GameState.energy < cost:
		AudioManager.sfx("error")
		EventBus.toast.emit(Loc.t("TOAST_NO_ENERGY"), "")
		return false
	var ctx: Dictionary = {"empty_warned": false}
	var effects: int = 0
	for c: Vector2i in cells:
		if apply(rt, kind, level, c, ctx):
			effects += 1
	if effects > 0:
		GameState.change_energy(-cost)
	return effects > 0


static func apply(rt: MapRuntime, kind: String, level: int, c: Vector2i, ctx: Dictionary) -> bool:
	if not rt.in_bounds(c):
		return false
	match kind:
		"hoe":
			return _hoe(rt, c)
		"can":
			return _can(rt, c, level, ctx)
		"axe":
			return _chop(rt, c, "axe", level)
		"pick":
			return _chop(rt, c, "pick", level)
		"scythe":
			return _scythe(rt, c)
	return false


static func _remove_dead(rt: MapRuntime, c: Vector2i) -> bool:
	var s: Dictionary = rt.soil_at(c)
	if not s.is_empty() and s.has("crop") and bool(s["crop"].get("dead", false)):
		s.erase("crop")
		rt.touch_soil(c)
		AudioManager.sfx("scythe")
		return true
	return false


static func _hoe(rt: MapRuntime, c: Vector2i) -> bool:
	var o: Dictionary = rt.object_at(c)
	if not o.is_empty():
		var origin: Vector2i = rt.origin_at(c)
		if str(o.get("t", "")) == "dig":
			dig(rt, origin)
			return true
		return bool(WorldObjects.hit(rt, origin, "hoe", 1)["ok"])
	if _remove_dead(rt, c):
		return true
	if Farming.can_till(rt, c):
		Farming.till(rt, c)
		AudioManager.sfx("hoe")
		EventBus.fx_requested.emit("dust", Vector2(c) * TILE + Vector2(8, 8))
		return true
	return false


static func _can(rt: MapRuntime, c: Vector2i, level: int, ctx: Dictionary) -> bool:
	if rt.terrain_id(c) == "water":
		refill_can(level)
		return true
	if rt.soil_at(c).is_empty() or int(rt.soil_at(c).get("w", 0)) == 1:
		return false
	if GameState.can_water <= 0:
		if not bool(ctx["empty_warned"]):
			ctx["empty_warned"] = true
			AudioManager.sfx("error")
			EventBus.toast.emit(Loc.t("TOAST_CAN_EMPTY"), "")
		return false
	if Farming.water(rt, c):
		GameState.can_water -= 1
		EventBus.inventory_changed.emit()
		AudioManager.sfx("water")
		EventBus.fx_requested.emit("drop", Vector2(c) * TILE + Vector2(8, 8))
		return true
	return false


static func can_capacity(level: int) -> int:
	var caps: Array = Database.bal("can_capacity", [20])
	return int(caps[clampi(level - 1, 0, caps.size() - 1)])


static func refill_can(level: int) -> void:
	GameState.can_water = can_capacity(level)
	EventBus.inventory_changed.emit()
	AudioManager.sfx("splash")
	EventBus.toast.emit(Loc.t("TOAST_CAN_FILLED"), "")


static func _chop(rt: MapRuntime, c: Vector2i, kind: String, level: int) -> bool:
	var o: Dictionary = rt.object_at(c)
	if not o.is_empty():
		var origin: Vector2i = rt.origin_at(c)
		if str(o.get("t", "")) == "placed":
			var err: String = Placement.pickup(rt, origin)
			if err != "":
				EventBus.toast.emit(Loc.t(err), "")
				return false
			return true
		return bool(WorldObjects.hit(rt, origin, kind, level)["ok"])
	if kind == "pick":
		if _remove_dead(rt, c):
			return true
		var s: Dictionary = rt.soil_at(c)
		if not s.is_empty() and not s.has("crop"):
			rt.clear_soil(c)
			AudioManager.sfx("pick")
			return true
	return false


static func _scythe(rt: MapRuntime, c: Vector2i) -> bool:
	var o: Dictionary = rt.object_at(c)
	if not o.is_empty():
		return bool(WorldObjects.hit(rt, rt.origin_at(c), "scythe", 1)["ok"])
	if _remove_dead(rt, c):
		return true
	return Farming.harvest(rt, c)


## Fouille d'une tache : artefact, argile, charbon ou cuivre.
static func dig(rt: MapRuntime, origin: Vector2i) -> void:
	var rng: RandomNumberGenerator = WorldObjects.rng
	var r: float = rng.randf()
	var id: String
	if r < 0.40:
		var arts: Array[String] = []
		for k: String in Database.items:
			if str(Database.items[k].get("cat", "")) == "artifact":
				arts.append(k)
		arts.sort()
		id = arts[rng.randi_range(0, arts.size() - 1)]
		GameState.add_stat("artifacts_dug")
	elif r < 0.65:
		id = "clay"
	elif r < 0.80:
		id = "coal"
	elif r < 0.92:
		id = "ore_copper"
	else:
		id = "fiber"
	Loot.give(id, 1)
	Skills.add_xp("foraging", 4)
	AudioManager.sfx("plant")
	EventBus.fx_requested.emit("dust", Vector2(origin) * TILE + Vector2(8, 8))
	rt.remove_object(origin)
