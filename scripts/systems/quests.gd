class_name Quests
extends RefCounted
## Quêtes quotidiennes (livraison, récolte, chasse, pêche) générées par jour, tableau d'Ormelune.

const TYPES: Array[String] = ["deliver", "harvest", "hunt", "fish"]


static func cfg() -> Dictionary:
	return Database.table("quests")


static func _rng(day: int, salt: int) -> RandomNumberGenerator:
	var r: RandomNumberGenerator = RandomNumberGenerator.new()
	r.seed = hash([GameState.seed, day, salt, "quest"])
	return r


## Les quêtes du jour (déterministes pour une partie et un jour donnés).
static func generate(day: int) -> Array:
	var out: Array = []
	var season: String = TimeManager.SEASONS[TimeManager.season_of(day)]
	var items: Array = cfg()["items"][season]
	var npcs: Array[String] = Friendship.ids()
	var mine_ok: bool = int(GameState.mine.get("deepest", 0)) >= 1 or day >= 6
	for i: int in int(cfg()["board_size"]):
		var r: RandomNumberGenerator = _rng(day, i)
		var type: String = TYPES[r.randi_range(0, TYPES.size() - 1)]
		if type == "hunt" and not mine_ok:
			type = "deliver"
		var q: Dictionary = {"id": "d%d_%d" % [day, i], "type": type, "npc": npcs[r.randi_range(0, npcs.size() - 1)], "day": day}
		match type:
			"deliver":
				q["item"] = str(items[r.randi_range(0, items.size() - 1)])
				q["n"] = r.randi_range(2, 6)
				q["reward"] = Database.bal_i("daily_quest_base_reward", 120) + int(Database.item(str(q["item"])).get("price", 10)) * int(q["n"])
			"harvest":
				q["n"] = r.randi_range(4, 12)
				q["reward"] = Database.bal_i("daily_quest_base_reward", 120) + int(q["n"]) * 20
			"hunt":
				var mons: Array = cfg()["monsters"]
				q["monster"] = str(mons[r.randi_range(0, mons.size() - 1)])
				q["n"] = r.randi_range(3, 7)
				q["reward"] = Database.bal_i("daily_quest_base_reward", 120) + int(q["n"]) * 45
			"fish":
				q["n"] = r.randi_range(1, 3)
				q["reward"] = Database.bal_i("daily_quest_base_reward", 120) + int(q["n"]) * 70
		q["points"] = Database.bal_i("quest_friend_points", 35)
		out.append(q)
	return out


static func refresh_board() -> void:
	GameState.quests["board"] = generate(GameState.day)


static func active() -> Array:
	return GameState.quests["active"]


static func accept(index: int) -> String:
	var board: Array = GameState.quests["board"]
	if index < 0 or index >= board.size():
		return "QUEST_GONE"
	if active().size() >= int(cfg()["max_active"]):
		return "QUEST_FULL"
	var q: Dictionary = (board[index] as Dictionary).duplicate()
	q["start"] = _counter(q)
	active().append(q)
	board.remove_at(index)
	AudioManager.sfx("ui_click")
	return ""


static func _counter(q: Dictionary) -> int:
	match str(q["type"]):
		"harvest":
			return GameState.stat("crops_harvested")
		"hunt":
			return GameState.stat("monsters_killed", str(q["monster"]))
		"fish":
			return GameState.stat("fish_caught")
	return 0


static func progress(q: Dictionary) -> int:
	if str(q["type"]) == "deliver":
		return GameState.item_count(str(q["item"]))
	return _counter(q) - int(q["start"])


static func can_complete(q: Dictionary) -> bool:
	return progress(q) >= int(q["n"])


static func complete(index: int) -> Dictionary:
	var list: Array = active()
	if index < 0 or index >= list.size() or not can_complete(list[index]):
		return {}
	var q: Dictionary = list[index]
	if str(q["type"]) == "deliver":
		GameState.remove_item(str(q["item"]), int(q["n"]))
	GameState.add_money(int(q["reward"]))
	Friendship.add_points(str(q["npc"]), int(q["points"]))
	GameState.quests["done"] = int(GameState.quests["done"]) + 1
	list.remove_at(index)
	GameState.add_stat("quests_done")
	AudioManager.sfx("quest_done")
	EventBus.quest_updated.emit()
	return q


## Description lisible d'une quête.
static func describe(q: Dictionary) -> String:
	match str(q["type"]):
		"deliver":
			return Loc.f("QUEST_DELIVER", [int(q["n"]), Database.item_name(str(q["item"]))])
		"harvest":
			return Loc.f("QUEST_HARVEST", [int(q["n"])])
		"hunt":
			return Loc.f("QUEST_HUNT", [int(q["n"]), Loc.t("MON_" + str(q["monster"]).to_upper())])
		"fish":
			return Loc.f("QUEST_FISH", [int(q["n"])])
	return ""


## Retire les quêtes expirées (livraisons non remplies d'un jour passé restent actives : pas de pénalité).
static func nightly() -> void:
	refresh_board()
