class_name Shops
extends RefCounted
## Commerces : horaires, stocks de saison, achats et ventes.


static func shop(shop_id: String) -> Dictionary:
	return Database.table("shops").get(shop_id, {})


static func is_open(shop_id: String) -> bool:
	var s: Dictionary = shop(shop_id)
	if s.is_empty():
		return false
	if s.has("requires") and not GameState.flag(str(s["requires"]).replace(":", "_")):
		return false
	var wd: int = TimeManager.weekday()
	if s.has("only_day"):
		if wd != int(s["only_day"]):
			return false
	elif int(s.get("closed_day", -1)) == wd:
		return false
	var h: int = GameState.minutes / 60
	return h >= int(s.get("open", 0)) and h < int(s.get("close", 24))


static func seeds(all_seasons: bool) -> Array[String]:
	var out: Array[String] = []
	for id: String in Database.items:
		var it: Dictionary = Database.items[id]
		if str(it.get("cat", "")) == "seed" and (all_seasons or str(it.get("season", "")) == TimeManager.season_id()):
			out.append(id)
	out.sort()
	return out


static func saplings() -> Array[String]:
	var out: Array[String] = []
	for id: String in Database.items:
		if str(Database.items[id].get("cat", "")) == "sapling":
			out.append(id)
	out.sort()
	return out


static func price_of(id: String) -> int:
	var it: Dictionary = Database.item(id)
	return int(it.get("buy", maxi(1, int(it.get("price", 1))) * 2))


## Lignes de stock : {"id", "price", "kind": item|recipe|service}.
static func stock(shop_id: String) -> Array[Dictionary]:
	var s: Dictionary = shop(shop_id)
	var out: Array[Dictionary] = []
	var seen: Dictionary = {}
	for entry: Variant in s.get("stock", []):
		var ids: Array[String] = []
		var price: int = -1
		if typeof(entry) == TYPE_ARRAY:
			ids = [str(entry[0])]
			price = int(entry[1])
		else:
			match str(entry):
				"@seeds":
					ids = seeds(false)
				"@seeds_all":
					ids = seeds(true)
				"@saplings":
					ids = saplings()
				_:
					ids = [str(entry)]
		for id: String in ids:
			if seen.has(id) or not Database.has_item(id):
				continue
			seen[id] = true
			out.append({"id": id, "price": price if price >= 0 else price_of(id), "kind": "item"})
	var recipes: Dictionary = s.get("recipes", {})
	for rid: String in recipes:
		if not Recipes.known("cook", rid):
			out.append({"id": rid, "price": int(recipes[rid]), "kind": "recipe"})
	if (s.get("services", []) as Array).has("backpack") and GameState.inventory_size < Database.bal_i("inventory_big_size", 48):
		out.append({"id": "backpack", "price": Database.bal_i("backpack_price", 5000), "kind": "service"})
	return out


## Achète `n` exemplaires. Renvoie "" ou une clé de traduction d'erreur.
static func buy(line: Dictionary, n: int) -> String:
	var kind: String = str(line["kind"])
	var total: int = int(line["price"]) * n
	if GameState.money < total:
		return "SHOP_NO_MONEY"
	match kind:
		"item":
			if not Inv.can_add(GameState.inventory, str(line["id"]), n):
				return "TOAST_INV_FULL"
			GameState.spend(total)
			GameState.add_item(str(line["id"]), n)
		"recipe":
			GameState.spend(total)
			Recipes.learn("cook", str(line["id"]))
		"service":
			GameState.spend(total)
			GameState.inventory_size = Database.bal_i("inventory_big_size", 48)
			GameState.inventory.resize(GameState.inventory_size)
			EventBus.inventory_changed.emit()
	AudioManager.sfx("buy")
	return ""


static func sell_price(id: String, q: int) -> int:
	return int(Economy.sell_value(id, q) * Database.bal_f("shop_sell_ratio", 0.75))


## Vend `n` exemplaires de la pile à l'emplacement `index`. Renvoie le gain.
static func sell(index: int, n: int) -> int:
	var s: Variant = GameState.inventory[index]
	if s == null or int(Database.item(str(s["id"])).get("price", 0)) <= 0 or Database.item(str(s["id"])).has("tool"):
		return 0
	var cnt: int = mini(n, int(s["n"]))
	var gain: int = sell_price(str(s["id"]), int(s["q"])) * cnt
	Inv.take(GameState.inventory, index, cnt)
	GameState.add_money(gain)
	EventBus.inventory_changed.emit()
	AudioManager.sfx("coins")
	return gain
