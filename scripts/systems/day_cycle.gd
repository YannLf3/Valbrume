class_name DayCycle
extends RefCounted
## Orchestration de la nuit : tout ce qui se passe entre deux journées.


static func run_night(passed_out: bool) -> Dictionary:
	var summary: Dictionary = {"passed_out": passed_out, "day": GameState.day, "shipped": [], "total": 0,
		"loss": 0, "eaten": 0, "weather": GameState.weather}
	# 1. Vente du coffre d'expédition
	var total: int = 0
	var lines: Array = []
	for s: Variant in GameState.shipping:
		if s == null:
			continue
		var value: int = Economy.slot_value(s)
		total += value
		lines.append({"id": s["id"], "n": s["n"], "q": s["q"], "value": value})
		GameState.add_stat("items_shipped", int(s["n"]), str(s["id"]))
	GameState.shipping.fill(null)
	GameState.add_money(total)
	summary["shipped"] = lines
	summary["total"] = total
	# 2. Pénalité d'évanouissement
	if passed_out:
		var loss: int = mini(GameState.money * Database.bal_i("faint_money_pct", 10) / 100, Database.bal_i("faint_money_max", 1000))
		GameState.money -= loss
		EventBus.money_changed.emit(GameState.money)
		summary["loss"] = loss
	# 3. Croissance, pluie, grignotins ; changement de saison
	var rains: bool = Weather.waters_crops(GameState.weather)
	var old_season: int = TimeManager.season_of(GameState.day)
	GameState.day += 1
	var season_changed: bool = TimeManager.season_of(GameState.day) != old_season
	var eaten: int = 0
	for map_id: String in Database.maps:
		var rt: MapRuntime = MapRuntime.new(map_id)
		if bool(rt.data.get("farmable", false)):
			var res: Dictionary = Farming.grow_night(rt, rains)
			eaten += int(res["eaten"])
			if season_changed:
				Farming.season_change(rt)
		Farming.grow_trees(rt)
		WorldObjects.daily_update(rt)
	summary["eaten"] = eaten
	# 4. Nouveau jour
	GameState.minutes = TimeManager.DAY_START
	GameState.weather = GameState.weather_tomorrow
	GameState.weather_tomorrow = Weather.roll(GameState.day + 1)
	GameState.buffs.clear()
	Skills.recompute_stats()
	var ratio: float = Database.bal_f("faint_energy_ratio", 0.5) if passed_out else 1.0
	GameState.energy = float(GameState.max_energy) * ratio
	GameState.health = float(GameState.max_health)
	GameState.can_water = GameState.can_water   # l'arrosoir garde son eau
	GameState.map_id = GameState.house_map()
	var bed: Vector2i = MapRuntime.new(GameState.map_id).spot("bed")
	var foot: Vector2 = MapRuntime.foot_pixel(bed)
	GameState.px = foot.x
	GameState.py = foot.y
	GameState.facing = 0
	summary["new_day"] = GameState.day
	summary["season_changed"] = season_changed
	GameState.add_stat("days_played")
	# 5. Sauvegarde automatique
	if SaveManager.current_slot >= 0:
		SaveManager.save_game(SaveManager.current_slot)
	return summary
