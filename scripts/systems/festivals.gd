class_name Festivals
extends RefCounted
## Quatre festivals (un par saison) : calendrier, fenêtre horaire, résultats et récompenses.

const OPEN_MIN: int = 540
const CLOSE_MIN: int = 900
const TIER_SCORES: Array[int] = [30, 60, 85]   # bronze, argent, or
const MONEY: Array[int] = [100, 400, 900, 1600]


static func table() -> Dictionary:
	return Database.table("festivals")


## Festival du jour (identifiant) ou "".
static func today_for(day: int) -> String:
	for id: String in table():
		var f: Dictionary = table()[id]
		if int(f["season"]) == TimeManager.season_of(day) and int(f["day"]) == TimeManager.day_of_season(day):
			return id
	return ""


static func today() -> String:
	return today_for(GameState.day)


static func window_open() -> bool:
	return today() != "" and GameState.minutes >= OPEN_MIN and GameState.minutes < CLOSE_MIN


static func done_key(id: String) -> String:
	return "fest_%s_%d" % [id, TimeManager.year()]


static func is_done(id: String) -> bool:
	return GameState.flag(done_key(id))


static func tier_for(score: int) -> int:
	var t: int = 0
	for i: int in TIER_SCORES.size():
		if score >= TIER_SCORES[i]:
			t = i + 1
	return t


## Récompense d'un palier : {"tier", "money", "item", "n", "points"}.
static func reward_for(id: String, score: int) -> Dictionary:
	var tier: int = tier_for(score)
	var out: Dictionary = {"tier": tier, "money": MONEY[tier], "item": "", "n": 0, "points": Database.bal_i("festival_points", 15) * (tier + 1) / 2}
	if tier >= 2:
		out["item"] = str(table()[id]["prize"])
		out["n"] = 1 if tier == 2 else 2
	return out


static func conclude(id: String, score: int) -> Dictionary:
	var r: Dictionary = reward_for(id, score)
	GameState.flags[done_key(id)] = true
	GameState.add_money(int(r["money"]))
	if str(r["item"]) != "":
		Loot.give(str(r["item"]), int(r["n"]))
	for npc: String in Friendship.ids():
		Friendship.add_points(npc, int(r["points"]))
	GameState.add_stat("festivals_played", 1, id)
	return r


## Dispersion des habitants sur la place pendant un festival.
static func spot_for(npc_id: String) -> String:
	var spots: Array[String] = ["plaza_w", "plaza_e", "plaza_n", "fountain_s", "bench_w", "bench_e", "street_w", "street_e", "forge_front", "store_front"]
	var ids: Array[String] = Friendship.ids()
	return spots[ids.find(npc_id) % spots.size()]
