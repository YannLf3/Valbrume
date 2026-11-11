class_name Collections
extends RefCounted
## Musée : minéraux, artefacts, poissons. On donne un exemplaire de chaque ; des paliers offrent des récompenses.

const CATEGORIES: Array[String] = ["minerals", "artifacts", "fish"]


static func table() -> Dictionary:
	return Database.table("collections")


static func items(cat: String) -> Array:
	return table().get(cat, {}).get("items", [])


static func category_of(item_id: String) -> String:
	for c: String in CATEGORIES:
		if items(c).has(item_id):
			return c
	return ""


static func is_donated(item_id: String) -> bool:
	return GameState.collections["donated"].has(item_id)


static func count(cat: String) -> int:
	var n: int = 0
	for id: Variant in items(cat):
		if is_donated(str(id)):
			n += 1
	return n


static func donated_count() -> int:
	var n: int = 0
	for c: String in CATEGORIES:
		n += count(c)
	return n


static func can_donate(item_id: String) -> bool:
	return category_of(item_id) != "" and not is_donated(item_id) and GameState.item_count(item_id) > 0


## Donne un exemplaire. Renvoie la liste des récompenses de palier obtenues.
static func donate(item_id: String) -> Array:
	var rewards: Array = []
	if not can_donate(item_id):
		return rewards
	var cat: String = category_of(item_id)
	GameState.remove_item(item_id, 1)
	GameState.collections["donated"][item_id] = true
	GameState.add_stat("museum_donations")
	AudioManager.sfx("gift")
	var n: int = count(cat)
	for r: Array in table()[cat]["rewards"]:
		var key: String = "%s_%d" % [cat, int(r[0])]
		if n >= int(r[0]) and not GameState.collections["rewards"].has(key):
			GameState.collections["rewards"][key] = true
			var rw: Dictionary = r[1]
			if rw.has("money"):
				GameState.add_money(int(rw["money"]))
			else:
				Loot.give(str(rw["item"]), int(rw["n"]))
			rewards.append(rw)
	EventBus.collection_updated.emit()
	return rewards
