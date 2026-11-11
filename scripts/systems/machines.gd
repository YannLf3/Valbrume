class_name Machines
extends RefCounted
## Machines de transformation posées sur la carte : fourneau, fromagerie, baratte, métier, presse, bocaux, fumoir, trieuse, ruches.
## L'état d'une machine : o["m"] = {"out": {id,n,q}, "done_at": minute absolue}. Pas de tic par minute :
## la machine est prête quand l'heure absolue dépasse done_at.


static func now() -> int:
	return GameState.day * 1440 + GameState.minutes


static func def(machine_id: String) -> Dictionary:
	return Database.table("machines").get(machine_id, {})


static func is_ready(m: Dictionary) -> bool:
	return m.has("out") and now() >= int(m.get("done_at", 0))


static func minutes_left(m: Dictionary) -> int:
	return maxi(0, int(m.get("done_at", 0)) - now())


static func matches(rec_in: String, item_id: String) -> bool:
	if rec_in.begins_with("@"):
		return str(Database.item(item_id).get("cat", "")) == rec_in.substr(1)
	return rec_in == item_id


static func find_recipe(machine_id: String, item_id: String) -> Dictionary:
	for r: Dictionary in def(machine_id).get("recipes", []):
		if matches(str(r["in"]), item_id):
			return r
	return {}


## Utilise la machine : récupère la production prête, ou lance une transformation avec l'objet tenu.
## Renvoie "" en cas de succès sans message, "MACHINE_COLLECTED" ou une clé d'erreur à afficher.
static func interact(o: Dictionary, held_id: String, held_index: int) -> String:
	var machine_id: String = str(o["p"])
	var m: Dictionary = o["m"]
	if m.has("out"):
		if not is_ready(m):
			return "MACHINE_BUSY"
		var out: Dictionary = m["out"]
		if GameState.add_item(str(out["id"]), int(out["n"]), int(out["q"])) > 0:
			return "TOAST_INV_FULL"
		m.erase("out")
		m.erase("done_at")
		Skills.add_xp("farming", Database.bal_i("xp_product", 7))
		AudioManager.sfx("pickup")
		return ""
	var d: Dictionary = def(machine_id)
	if d.has("passive") or held_id == "":
		return "MACHINE_NEEDS" if not d.has("passive") else "MACHINE_EMPTY"
	var rec: Dictionary = find_recipe(machine_id, held_id)
	if rec.is_empty():
		return "MACHINE_BAD_INPUT"
	var need: int = int(rec["n"])
	if GameState.item_count(held_id) < need:
		return "MACHINE_NEED_MORE"
	var fuel: Dictionary = d.get("fuel", {})
	for f: String in fuel:
		if GameState.item_count(f) < int(fuel[f]):
			return "MACHINE_NEEDS_FUEL"
	var q: int = 0
	if bool(d.get("keep_quality", false)) and held_index >= 0 and GameState.inventory[held_index] != null:
		q = int(GameState.inventory[held_index]["q"])
	for f: String in fuel:
		GameState.remove_item(f, int(fuel[f]))
	GameState.remove_item(held_id, need)
	var out_id: String = str(rec["out"])
	var out_n: int = 1
	if out_id == "@seed":
		out_id = str(Database.crops.get(held_id, {}).get("seed", ""))
		var rng: Array = rec.get("out_n", [1, 1])
		out_n = WorldObjects.rng.randi_range(int(rng[0]), int(rng[1]))
	m["out"] = {"id": out_id, "n": out_n, "q": q}
	m["done_at"] = now() + int(rec["minutes"])
	AudioManager.sfx("craft")
	GameState.add_stat("machine_runs")
	return ""


## Production nocturne : les ruches fabriquent du miel (3 jours en saison chaude).
static func nightly(rt: MapRuntime) -> void:
	for k: String in rt.objects():
		var o: Dictionary = rt.objects()[k]
		if str(o.get("t", "")) != "placed":
			continue
		var d: Dictionary = def(str(o["p"]))
		if not d.has("passive"):
			continue
		var m: Dictionary = o["m"]
		var seasons: Array = d["passive"]["seasons"]
		if m.has("out") or not seasons.has(TimeManager.season_id()):
			continue
		m["days"] = int(m.get("days", 0)) + 1
		if int(m["days"]) >= int(d["passive"]["days"]):
			m["days"] = 0
			m["out"] = {"id": str(d["passive"]["out"]), "n": 1, "q": 0}
			m["done_at"] = 0
		rt.touch_object(GameState.cell_of(k))
