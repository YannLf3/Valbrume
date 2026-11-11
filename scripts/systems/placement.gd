class_name Placement
extends RefCounted
## Pose et ramassage d'objets (coffres, arroseurs, clôtures, meubles…).


static func def_for_item(item_id: String) -> Dictionary:
	var pid: String = str(Database.item(item_id).get("place", ""))
	return WorldObjects.places().get(pid, {})


## Pose l'objet sur la case. Renvoie "" en cas de succès, sinon la clé de l'erreur.
static func place(rt: MapRuntime, item_id: String, c: Vector2i, facing: int) -> String:
	var pid: String = str(Database.item(item_id).get("place", ""))
	var d: Dictionary = WorldObjects.places().get(pid, {})
	if d.is_empty() or not rt.in_bounds(c):
		return "TOAST_CANT_PLACE"
	var kind: String = str(d.get("kind", ""))
	var tid: String = rt.terrain_id(c)
	if kind == "furniture" and not rt.is_interior():
		return "TOAST_INDOORS_ONLY"
	if bool(d.get("wall", false)):
		if tid != "wall_low":
			return "TOAST_NEEDS_WALL"
	elif bool(d.get("on_water", false)):
		if tid != "water":
			return "TOAST_NEEDS_WATER"
	elif tid == "water" or tid == "cliff" or tid == "void" or tid == "wall" or tid == "wall_low":
		return "TOAST_CANT_PLACE"
	if not bool(d.get("on_water", false)) and rt.is_solid(c) and not bool(d.get("wall", false)):
		return "TOAST_CANT_PLACE"
	if rt.origin_at(c) != null or not rt.soil_at(c).is_empty():
		return "TOAST_CANT_PLACE"
	if bool(d.get("outdoor", false)) and rt.is_interior():
		return "TOAST_OUTDOORS_ONLY"
	var obj: Dictionary = {"t": "placed", "p": pid, "hp": 1, "rot": facing}
	if kind == "chest":
		var slots: Array = []
		slots.resize(int(d.get("slots", 36)))
		obj["slots"] = slots
	elif kind == "machine" or kind == "crab_pot":
		obj["m"] = {}
	if not GameState.remove_item(item_id, 1):
		return "TOAST_CANT_PLACE"
	rt.add_object(c, obj)
	AudioManager.sfx("plant")
	return ""


## Ramasse un objet posé. Renvoie "" en cas de succès, sinon la clé de l'erreur.
static func pickup(rt: MapRuntime, origin: Vector2i) -> String:
	var o: Dictionary = rt.state["objects"].get(GameState.key(origin), {})
	if str(o.get("t", "")) != "placed":
		return "TOAST_CANT_PLACE"
	if o.has("slots") and Inv.free_slots(o["slots"]) < (o["slots"] as Array).size():
		return "TOAST_CHEST_NOT_EMPTY"
	var m: Dictionary = o.get("m", {})
	if not m.is_empty() and (m.has("out") or m.has("busy")):
		return "TOAST_MACHINE_BUSY"
	var item_id: String = ""
	for id: String in Database.items:
		if str(Database.items[id].get("place", "")) == str(o["p"]):
			item_id = id
			break
	if item_id == "" or not Inv.can_add(GameState.inventory, item_id, 1):
		return "TOAST_INV_FULL"
	rt.remove_object(origin)
	GameState.add_item(item_id, 1)
	return ""
