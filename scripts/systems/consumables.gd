class_name Consumables
extends RefCounted
## Repas : énergie, santé et bonus temporaires (buffs).


static func is_edible(id: String) -> bool:
	var it: Dictionary = Database.item(id)
	return it.has("energy") or it.has("health")


## Mange un exemplaire de l'objet tenu. Renvoie vrai si consommé.
static func eat(id: String) -> bool:
	if not is_edible(id) or GameState.item_count(id) <= 0:
		return false
	var it: Dictionary = Database.item(id)
	GameState.remove_item(id, 1)
	var b: Variant = it.get("buff")
	if b != null:  # le bonus d'énergie maximale s'applique avant la restauration
		apply_buff(str(b["stat"]), float(b["amount"]), int(b["minutes"]), id)
	GameState.change_energy(float(it.get("energy", 0)))
	GameState.change_health(float(it.get("health", 0)))
	AudioManager.sfx("eat")
	GameState.add_stat("meals_eaten")
	return true


static func apply_buff(stat: String, amount: float, minutes: int, source: String) -> void:
	for existing: Dictionary in GameState.buffs:
		if str(existing["source"]) == source:
			existing["left"] = minutes
			EventBus.buffs_changed.emit()
			return
	GameState.buffs.append({"stat": stat, "amount": amount, "left": minutes, "source": source})
	Skills.recompute_stats()
	EventBus.buffs_changed.emit()


## Appelé à chaque minute de jeu.
static func tick() -> void:
	if GameState.buffs.is_empty():
		return
	var changed: bool = false
	for i: int in range(GameState.buffs.size() - 1, -1, -1):
		var b: Dictionary = GameState.buffs[i]
		b["left"] = int(b["left"]) - 1
		if int(b["left"]) <= 0:
			GameState.buffs.remove_at(i)
			changed = true
	if changed:
		Skills.recompute_stats()
		EventBus.buffs_changed.emit()
