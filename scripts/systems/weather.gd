class_name Weather
extends RefCounted
## Tirage déterministe de la météo (graine de la partie + jour).

const WATERING: Array[String] = ["rain", "storm"]


static func roll(day: int) -> String:
	if day <= 1:
		return "sun"
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash([GameState.seed, day])
	var season: String = TimeManager.SEASONS[TimeManager.season_of(day)]
	var weights: Dictionary = Database.table("weather").get(season, {"sun": 1})
	var total: int = 0
	for k: String in weights:
		total += int(weights[k])
	var r: int = rng.randi_range(1, total)
	for k: String in weights:
		r -= int(weights[k])
		if r <= 0:
			return k
	return "sun"


static func waters_crops(weather: String) -> bool:
	return WATERING.has(weather)
