class_name DayCycle
extends RefCounted
## Orchestration de la nuit : tout ce qui se passe entre deux journées.


static func run_night(passed_out: bool) -> Dictionary:
	var summary: Dictionary = {"passed_out": passed_out, "day": GameState.day}
	GameState.day += 1
	GameState.minutes = TimeManager.DAY_START
	GameState.energy = float(GameState.max_energy)
	return summary
