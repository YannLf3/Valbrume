class_name Recipes
extends RefCounted
## Recettes d'artisanat et de cuisine : conditions de déblocage et connaissances du joueur.


static func table(kind: String) -> Dictionary:
	return Database.table("recipes").get(kind, {})


static func key(kind: String, id: String) -> String:
	return kind + ":" + id


static func known(kind: String, id: String) -> bool:
	return GameState.recipes.has(key(kind, id))


static func hearts(npc: String) -> int:
	var pts: int = int(GameState.relations.get(npc, {}).get("points", 0))
	return pts / maxi(1, Database.bal_i("heart_points", 100))


static func condition_met(unlock: String) -> bool:
	var p: PackedStringArray = unlock.split(":")
	match p[0]:
		"start":
			return true
		"skill":
			return GameState.skill_level(p[1]) >= int(p[2])
		"friend":
			return hearts(p[1]) >= int(p[2])
		"bell":
			return GameState.story.get("bells", {}).has(p[1])
	return false  # « shop » : appris à l'achat


static func learn(kind: String, id: String, announce: bool = true) -> void:
	if known(kind, id):
		return
	GameState.recipes[key(kind, id)] = true
	if announce and GameState.active:
		EventBus.recipe_learned.emit(id)
		EventBus.toast.emit(Loc.f("TOAST_RECIPE", [Database.item_name(id)]), id)


## Débloque toutes les recettes dont la condition est remplie.
static func refresh(announce: bool = true) -> void:
	for kind: String in ["craft", "cook"]:
		var t: Dictionary = table(kind)
		for id: String in t:
			if not known(kind, id) and condition_met(str(t[id]["unlock"])):
				learn(kind, id, announce)
