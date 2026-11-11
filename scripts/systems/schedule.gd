class_name Schedule
extends RefCounted
## Emplois du temps des PNJ : choix du programme du jour, étape courante, itinéraires entre cartes.

static var _graph: Dictionary = {}


static func key_for_today(npc_id: String) -> String:
	var sched: Dictionary = Friendship.npc(npc_id).get("schedule", {})
	var w: String = GameState.weather
	if (w == "rain" or w == "storm") and sched.has("rain"):
		return "rain"
	if w == "snow" and sched.has("snow"):
		return "snow"
	var d: String = "d%d" % TimeManager.weekday()
	if sched.has(d):
		return d
	for k: String in sched:
		if k.begins_with("bell_") and GameState.flag(k):
			return k
	return "default"


## Étape en cours à `minutes` : {"index", "t", "map", "spot"}.
static func entry_at(npc_id: String, minutes: int) -> Dictionary:
	var steps: Array = Friendship.npc(npc_id).get("schedule", {}).get(key_for_today(npc_id), [])
	var idx: int = 0
	for i: int in steps.size():
		if minutes >= int(steps[i][0]):
			idx = i
	var s: Array = steps[idx]
	return {"index": idx, "t": int(s[0]), "map": str(s[1]), "spot": str(s[2])}


static func previous_map(npc_id: String, index: int) -> String:
	var steps: Array = Friendship.npc(npc_id).get("schedule", {}).get(key_for_today(npc_id), [])
	if index > 0:
		return str(steps[index - 1][1])
	return str(Friendship.npc(npc_id).get("home", ""))


static func _resolve(target: String) -> String:
	return GameState.house_map() if target == "farmhouse" else target


## Graphe des cartes : carte → liste des cartes voisines (via les passages).
static func graph() -> Dictionary:
	if not _graph.is_empty():
		return _graph
	for id: String in Database.maps:
		var nb: Array[String] = []
		for wp: Dictionary in Database.map(id).get("warps", []):
			var t: String = _resolve(str(wp["to"]))
			if Database.maps.has(t) and not nb.has(t):
				nb.append(t)
		_graph[id] = nb
	return _graph


static func route(from_map: String, to_map: String) -> Array[String]:
	if from_map == to_map:
		return [from_map]
	var g: Dictionary = graph()
	var prev: Dictionary = {from_map: ""}
	var queue: Array[String] = [from_map]
	while not queue.is_empty():
		var cur: String = queue.pop_front()
		if cur == to_map:
			break
		for n: String in g.get(cur, []):
			if not prev.has(n):
				prev[n] = cur
				queue.append(n)
	if not prev.has(to_map):
		return []
	var out: Array[String] = []
	var c: String = to_map
	while c != "":
		out.push_front(c)
		c = str(prev[c])
	return out


## Case du passage, sur `map_id`, qui mène vers `next_map`.
static func warp_cell_toward(map_id: String, next_map: String) -> Vector2i:
	for wp: Dictionary in Database.map(map_id).get("warps", []):
		if _resolve(str(wp["to"])) == next_map:
			return Vector2i(int(wp["x"]), int(wp["y"]))
	return Vector2i(-1, -1)


static func spot_cell(map_id: String, spot: String) -> Vector2i:
	var s: Variant = Database.map(map_id).get("spots", {}).get(spot)
	return Vector2i(int(s[0]), int(s[1])) if s != null else Vector2i(-1, -1)
