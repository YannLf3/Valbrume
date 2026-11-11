class_name Dialogue
extends RefCounted
## Choix des répliques (palier d'amitié, saison, météo, anniversaire) et des événements de cœur.

const BRACKETS: Array[int] = [2, 5, 8]


static func bracket(hearts: int) -> String:
	if hearts < BRACKETS[0]:
		return "h0"
	if hearts < BRACKETS[1]:
		return "h1"
	if hearts < BRACKETS[2]:
		return "h2"
	return "h3"


static func _rng(npc_id: String) -> RandomNumberGenerator:
	var r: RandomNumberGenerator = RandomNumberGenerator.new()
	r.seed = hash([GameState.seed, GameState.day, npc_id])
	return r


## Clé de traduction de la réplique du jour (stable pour une journée donnée).
static func pick_talk(npc_id: String) -> String:
	var talk: Dictionary = Friendship.npc(npc_id).get("talk", {})
	if Friendship.is_birthday(npc_id):
		return str(talk["birthday"][0])
	var r: RandomNumberGenerator = _rng(npc_id)
	var w: String = GameState.weather
	var roll: float = r.randf()
	if w == "snow" and roll < 0.4:
		return str(talk["snow"][0])
	if (w == "rain" or w == "storm") and roll < 0.4:
		return str(talk["rain"][0])
	if roll > 0.78:
		return str(talk[TimeManager.season_id()][0])
	var lines: Array = talk[bracket(Friendship.hearts(npc_id))]
	return str(lines[r.randi_range(0, lines.size() - 1)])


static func gift_reaction(npc_id: String, taste: String) -> String:
	return str(Friendship.npc(npc_id)["talk"]["gift_" + taste][0])


## Événement de cœur prêt pour ce PNJ (identifiant) ou "".
static func pending_event(npc_id: String) -> String:
	var events: Dictionary = Database.table("events")
	var seen: Dictionary = Friendship.rel(npc_id)["events"]
	for eid: String in Friendship.npc(npc_id).get("events", []):
		var e: Dictionary = events.get(eid, {})
		if not seen.has(eid) and Friendship.hearts(npc_id) >= int(e.get("hearts", 99)):
			return eid
	return ""


static func total_lines(npc_id: String) -> int:
	var n: int = 0
	for k: String in Friendship.npc(npc_id).get("talk", {}):
		n += (Friendship.npc(npc_id)["talk"][k] as Array).size()
	return n
