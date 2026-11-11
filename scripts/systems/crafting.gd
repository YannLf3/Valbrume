class_name Crafting
extends RefCounted
## Artisanat et cuisine : vérification des ingrédients (objets ou catégories « @poisson ») et fabrication.

static func table(kind: String) -> Dictionary:
	return Recipes.table(kind)


static func count(key: String) -> int:
	if not key.begins_with("@"):
		return GameState.item_count(key)
	var cat: String = key.substr(1)
	var n: int = 0
	for s: Variant in GameState.inventory:
		if s != null and str(Database.item(str(s["id"])).get("cat", "")) == cat:
			n += int(s["n"])
	return n


static func ingredient_name(key: String) -> String:
	return Loc.t("CAT_" + key.substr(1).to_upper()) if key.begins_with("@") else Database.item_name(key)


static func known_ids(kind: String) -> Array[String]:
	var out: Array[String] = []
	for id: String in table(kind):
		if Recipes.known(kind, id):
			out.append(id)
	out.sort()
	return out


static func has_ingredients(kind: String, id: String) -> bool:
	var ing: Dictionary = table(kind)[id]["in"]
	for key: String in ing:
		if count(key) < int(ing[key]):
			return false
	return true


static func can_make(kind: String, id: String) -> bool:
	var r: Dictionary = table(kind).get(id, {})
	return not r.is_empty() and Recipes.known(kind, id) and has_ingredients(kind, id) \
		and Inv.can_add(GameState.inventory, id, int(r["n"]))


## Retire n objets d'une catégorie, les moins chers d'abord.
static func _consume_category(cat: String, n: int) -> void:
	var left: int = n
	while left > 0:
		var best: int = -1
		var best_price: int = 1 << 30
		for i: int in GameState.inventory.size():
			var s: Variant = GameState.inventory[i]
			if s != null and str(Database.item(str(s["id"])).get("cat", "")) == cat:
				var p: int = int(Database.item(str(s["id"])).get("price", 0))
				if p < best_price:
					best_price = p
					best = i
		if best < 0:
			return
		var take: Dictionary = Inv.take(GameState.inventory, best, left)
		left -= int(take["n"])


## Fabrique la recette. Renvoie "" ou une clé de traduction d'erreur.
static func make(kind: String, id: String) -> String:
	var r: Dictionary = table(kind).get(id, {})
	if r.is_empty() or not Recipes.known(kind, id):
		return "CRAFT_UNKNOWN"
	if not has_ingredients(kind, id):
		return "CRAFT_MISSING"
	if not Inv.can_add(GameState.inventory, id, int(r["n"])):
		return "TOAST_INV_FULL"
	var ing: Dictionary = r["in"]
	for key: String in ing:
		if key.begins_with("@"):
			_consume_category(key.substr(1), int(ing[key]))
		else:
			GameState.remove_item(key, int(ing[key]))
	GameState.add_item(id, int(r["n"]))
	GameState.add_stat("items_cooked" if kind == "cook" else "items_crafted", int(r["n"]), id)
	AudioManager.sfx("craft")
	return ""
