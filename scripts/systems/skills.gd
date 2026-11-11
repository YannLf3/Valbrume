class_name Skills
extends RefCounted
## Expérience, niveaux (1 à 10) et bonus de compétence.


static func level_for_xp(xp: int) -> int:
	var table: Array = Database.bal("xp_levels", [0])
	var lvl: int = 1
	for i: int in table.size():
		if xp >= int(table[i]):
			lvl = i + 1
	return mini(lvl, table.size())


static func xp_for_next(skill: String) -> int:
	var table: Array = Database.bal("xp_levels", [0])
	var lvl: int = GameState.skill_level(skill)
	return int(table[lvl]) if lvl < table.size() else -1


static func add_xp(skill: String, amount: int) -> void:
	if amount <= 0 or not GameState.skills.has(skill):
		return
	var entry: Dictionary = GameState.skills[skill]
	var before: int = int(entry["level"])
	entry["xp"] = int(entry["xp"]) + amount
	var after: int = level_for_xp(int(entry["xp"]))
	EventBus.skill_xp_gained.emit(skill, amount)
	if after > before:
		entry["level"] = after
		recompute_stats()
		Recipes.refresh()
		AudioManager.sfx("levelup")
		EventBus.skill_level_up.emit(skill, after)
		EventBus.toast.emit(Loc.f("TOAST_LEVEL_UP", [Loc.t("SKILL_" + skill.to_upper()), after]), "")


## Somme d'un bonus sur tous les niveaux atteints.
static func perk(perk_name: String) -> float:
	var total: float = 0.0
	var skills_t: Dictionary = Database.table("skills")
	for s: String in GameState.SKILLS:
		var lvls: Dictionary = skills_t.get(s, {})
		for l: int in range(1, GameState.skill_level(s) + 1):
			var entry: Dictionary = lvls.get(str(l), {})
			var p: Variant = entry.get("perk")
			if p != null and str(p[0]) == perk_name:
				total += float(p[1])
	return total


## Niveau efficace = niveau réel + bonus de repas.
static func effective_level(skill: String) -> int:
	return GameState.skill_level(skill) + int(GameState.buff_total(skill))


static func recompute_stats() -> void:
	var old_h: int = GameState.max_health
	GameState.max_health = Database.bal_i("start_health", 100) + int(perk("max_health"))
	GameState.health = minf(GameState.health + float(GameState.max_health - old_h), float(GameState.max_health))
	GameState.max_energy = Database.bal_i("start_energy", 100) + int(GameState.buff_total("max_energy"))
	GameState.energy = minf(GameState.energy, float(GameState.max_energy))
	EventBus.energy_changed.emit(GameState.energy, float(GameState.max_energy))
	EventBus.health_changed.emit(GameState.health, float(GameState.max_health))
