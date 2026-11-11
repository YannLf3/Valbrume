class_name Friendship
extends RefCounted
## Amitié (0 à 10 cœurs), cadeaux, anniversaires, fréquentation.

const TASTES: Array[String] = ["love", "like", "neutral", "dislike", "hate"]
const WEEK: int = 7


static func npc(npc_id: String) -> Dictionary:
	return Database.table("npcs").get(npc_id, {})


static func ids() -> Array[String]:
	var out: Array[String] = []
	for k: String in Database.table("npcs"):
		out.append(k)
	out.sort()
	return out


static func rel(npc_id: String) -> Dictionary:
	if not GameState.relations.has(npc_id):
		GameState.relations[npc_id] = {"points": 0, "talked": -1, "gift_day": -1, "gifts_week": 0, "week": -1,
			"dating": false, "married": false, "events": {}}
	return GameState.relations[npc_id]


static func points(npc_id: String) -> int:
	return int(rel(npc_id)["points"])


static func hearts(npc_id: String) -> int:
	return points(npc_id) / maxi(1, Database.bal_i("heart_points", 100))


static func max_points(npc_id: String) -> int:
	var per: int = Database.bal_i("heart_points", 100)
	var d: Dictionary = npc(npc_id)
	if bool(d.get("romance", false)) and not bool(rel(npc_id)["dating"]):
		return Database.bal_i("dating_cap_hearts", 8) * per
	return Database.bal_i("max_hearts", 10) * per


static func add_points(npc_id: String, amount: int) -> void:
	var r: Dictionary = rel(npc_id)
	var before: int = hearts(npc_id)
	r["points"] = clampi(int(r["points"]) + amount, 0, max_points(npc_id))
	EventBus.friendship_changed.emit(npc_id, int(r["points"]))
	if hearts(npc_id) != before:
		Recipes.refresh()


static func is_birthday(npc_id: String) -> bool:
	var b: Array = npc(npc_id).get("birthday", [-1, -1])
	return int(b[0]) == TimeManager.season() and int(b[1]) == TimeManager.day_in_season()


static func talked_today(npc_id: String) -> bool:
	return int(rel(npc_id)["talked"]) == GameState.day


## Première conversation du jour : gagne des points d'amitié. Renvoie vrai si c'est la première.
static func talk(npc_id: String) -> bool:
	if talked_today(npc_id):
		return false
	rel(npc_id)["talked"] = GameState.day
	var gain: int = Database.bal_i("talk_points", 12)
	if bool(rel(npc_id)["dating"]):
		gain += 8
	add_points(npc_id, gain)
	GameState.add_stat("conversations", 1, npc_id)
	return true


## Goût d'un PNJ pour un objet : love / like / neutral / dislike / hate.
static func taste(npc_id: String, item_id: String) -> String:
	var d: Dictionary = npc(npc_id)
	var cat: String = "cat:" + str(Database.item(item_id).get("cat", ""))
	for t: String in ["love", "hate", "dislike", "like"]:
		var key: String = t + "s" if t != "dislike" else "dislikes"
		var lst: Array = d.get(key, [])
		if lst.has(item_id):
			return t
	for t: String in ["love", "hate", "dislike", "like"]:
		var key: String = t + "s" if t != "dislike" else "dislikes"
		if (d.get(key, []) as Array).has(cat):
			return t
	if ["resource", "misc"].has(str(Database.item(item_id).get("cat", ""))):
		return "dislike"
	return "neutral"


static func is_giftable(item_id: String) -> bool:
	var it: Dictionary = Database.item(item_id)
	return not it.is_empty() and not it.has("tool")


static func _week() -> int:
	return GameState.day / WEEK


static func gifts_this_week(npc_id: String) -> int:
	var r: Dictionary = rel(npc_id)
	return int(r["gifts_week"]) if int(r["week"]) == _week() else 0


## Renvoie "" si on peut offrir, sinon une clé de traduction expliquant pourquoi.
static func gift_block(npc_id: String) -> String:
	var r: Dictionary = rel(npc_id)
	if int(r["gift_day"]) == GameState.day:
		return "GIFT_ALREADY"
	if gifts_this_week(npc_id) >= Database.bal_i("gifts_per_week", 2):
		return "GIFT_LIMIT"
	return ""


## Offre un exemplaire de l'objet. Renvoie {"taste", "points", "special"} ("" | "dating" | "refused" | "engaged").
static func give_gift(npc_id: String, item_id: String) -> Dictionary:
	var r: Dictionary = rel(npc_id)
	var out: Dictionary = {"taste": "neutral", "points": 0, "special": ""}
	if gift_block(npc_id) != "" or not GameState.remove_item(item_id, 1):
		return out
	r["gift_day"] = GameState.day
	r["week"] = _week()
	r["gifts_week"] = gifts_this_week(npc_id) + 1
	var d: Dictionary = npc(npc_id)
	if item_id == "bouquet":
		if bool(d.get("romance", false)) and hearts(npc_id) >= Database.bal_i("dating_cap_hearts", 8) and not bool(r["dating"]):
			r["dating"] = true
			out["special"] = "dating"
			out["taste"] = "love"
			add_points(npc_id, int(Database.bal("gift_points", {}).get("love", 45)))
			return out
		if not bool(d.get("romance", false)) or bool(r["dating"]):
			out["special"] = "refused"
			out["taste"] = "neutral"
			return out
	if item_id == "braided_ring":
		if bool(r["dating"]) and hearts(npc_id) >= Database.bal_i("marriage_hearts", 10) and int(GameState.house.get("level", 1)) >= 2 and GameState.spouse == "":
			GameState.flags["engaged_to"] = npc_id
			GameState.flags["wedding_day"] = GameState.day + 3
			out["special"] = "engaged"
			out["taste"] = "love"
			return out
		out["special"] = "refused"
		return out
	var t: String = taste(npc_id, item_id)
	var pts: int = int(Database.bal("gift_points", {}).get(t, 0))
	if is_birthday(npc_id):
		pts *= Database.bal_i("birthday_mult", 4) if pts > 0 else 1
	add_points(npc_id, pts)
	GameState.add_stat("gifts_given", 1, npc_id)
	out["taste"] = t
	out["points"] = pts
	return out
