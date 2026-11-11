class_name Fishing
extends RefCounted
## Pêche : sélection du poisson (lieu, saison, heure, météo), appâts, casiers à crabes.

static var rng: RandomNumberGenerator = RandomNumberGenerator.new()


static func table() -> Dictionary:
	return Database.table("fish").get("fish", {})


static func place_for(rt: MapRuntime) -> String:
	return str(rt.data.get("fish_place", ""))


static func _weather_ok(req: String, weather: String) -> bool:
	if req == "any":
		return true
	if req == "rain":
		return weather == "rain" or weather == "storm"
	return weather == req or (req == "sun" and weather == "wind")


## Poissons possibles à cet endroit, cette saison, cette heure, par cette météo.
static func candidates(place: String, season: String, hour: int, weather: String) -> Array[String]:
	var out: Array[String] = []
	for id: String in table():
		var f: Dictionary = table()[id]
		if str(f["place"]) != place or not (f["seasons"] as Array).has(season):
			continue
		if hour < int(f["hours"][0]) or hour >= int(f["hours"][1]):
			continue
		if _weather_ok(str(f["weather"]), weather):
			out.append(id)
	out.sort()
	return out


## Tire un poisson (les faciles sont plus fréquents ; une meilleure canne aide pour les difficiles). "" si rien ne mord.
static func pick(place: String, rod_level: int) -> String:
	var ids: Array[String] = candidates(place, TimeManager.season_id(), GameState.minutes / 60, GameState.weather)
	if ids.is_empty():
		return ""
	var weights: Array[int] = []
	var total: int = 0
	for id: String in ids:
		var diff: int = int(table()[id]["difficulty"])
		var w: int = maxi(1, 6 - diff + (rod_level - 1 if diff >= 4 else 0))
		weights.append(w)
		total += w
	var r: int = rng.randi_range(1, total)
	for i: int in ids.size():
		r -= weights[i]
		if r <= 0:
			return ids[i]
	return ids[0]


static func rod_level() -> int:
	var held: Dictionary = Database.item(GameState.held_id())
	return int(held.get("level", 1)) if str(held.get("tool", "")) == "rod" else 1


## Consomme un appât si on en a (une chance de le garder avec la compétence). Renvoie vrai si un appât est utilisé.
static func use_bait() -> bool:
	if GameState.item_count("bait") <= 0:
		return false
	if rng.randf() >= Skills.perk("bait_saver"):
		GameState.remove_item("bait", 1)
	return true


static func catch_xp(fish_id: String) -> int:
	return Database.bal_i("xp_fish_base", 10) + int(table().get(fish_id, {}).get("difficulty", 1)) * Database.bal_i("xp_fish_per_diff", 8)


## Résout une prise réussie : objet, qualité, expérience, statistiques.
static func land(fish_id: String, quality: int) -> void:
	var q: int = quality
	if rng.randf() < Skills.perk("fish_quality") and q < 2:
		q += 1
	Loot.give(fish_id, 1, q)
	Skills.add_xp("fishing", catch_xp(fish_id))
	GameState.add_stat("fish_caught", 1, fish_id)
	EventBus.fish_caught.emit(fish_id, q)
	AudioManager.sfx("catch")


## Petit trésor repêché pendant un combat parfait.
static func treasure() -> void:
	var loot: Array = [["bait", 5], ["ore_copper", 4], ["ingot_copper", 1], ["quartz", 1], ["ore_iron", 3], ["amethyst", 1]]
	var pick_: Array = loot[rng.randi_range(0, loot.size() - 1)]
	Loot.give(str(pick_[0]), int(pick_[1]))
	EventBus.toast.emit(Loc.t("FISH_TREASURE"), str(pick_[0]))


# --- casiers ---------------------------------------------------------------------

static func pot_place(rt: MapRuntime) -> String:
	var p: String = place_for(rt)
	return "sea" if p == "sea" else "river"


static func pots_nightly(rt: MapRuntime) -> void:
	for k: String in rt.objects():
		var o: Dictionary = rt.objects()[k]
		if str(o.get("t", "")) != "placed" or str(o.get("p", "")) != "crab_pot":
			continue
		var m: Dictionary = o["m"]
		if m.has("out"):
			continue
		var pool: Array = Database.table("fish").get("pot", {}).get(pot_place(rt), [])
		if pool.is_empty() or rng.randf() > 0.7:
			continue
		m["out"] = {"id": str(pool[rng.randi_range(0, pool.size() - 1)]), "n": 1, "q": 0}
		m["done_at"] = 0
		rt.touch_object(GameState.cell_of(k))


## Relève un casier. Renvoie vrai si une prise a été récupérée.
static func collect_pot(o: Dictionary) -> bool:
	var m: Dictionary = o["m"]
	if not m.has("out"):
		return false
	var out: Dictionary = m["out"]
	if GameState.add_item(str(out["id"]), int(out["n"]), 0) > 0:
		EventBus.toast.emit(Loc.t("TOAST_INV_FULL"), str(out["id"]))
		return false
	m.erase("out")
	Skills.add_xp("fishing", Database.bal_i("xp_pot", 6))
	GameState.add_stat("pot_catches")
	AudioManager.sfx("pickup")
	return true
