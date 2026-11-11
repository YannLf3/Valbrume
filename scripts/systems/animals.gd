class_name Animals
extends RefCounted
## Élevage : achat, affection, nourriture (pâturage ou foin du silo), production, soins quotidiens.

const NAMES_FR: Array[String] = ["Mirabelle", "Noisette", "Pâquerette", "Réglisse", "Cannelle", "Brindille", "Clémentine", "Souris"]


static func table() -> Dictionary:
	return Database.table("animals")


static func in_building(home: String) -> Array:
	var out: Array = []
	for a: Dictionary in GameState.animals:
		if str(a["home"]) == home:
			out.append(a)
	return out


## Peut-on acheter ce type ? Renvoie "" ou une clé d'erreur.
static func can_buy(type: String) -> String:
	var d: Dictionary = table().get(type, {})
	var home: String = str(d["home"])
	if Buildings.level(home) < int(d["min_level"]):
		return "ANIMAL_NO_HOME"
	if in_building(home).size() >= Buildings.capacity(home):
		return "ANIMAL_FULL"
	if GameState.money < int(d["price"]):
		return "SHOP_NO_MONEY"
	return ""


static func buy(type: String, animal_name: String) -> String:
	var err: String = can_buy(type)
	if err != "":
		return err
	var d: Dictionary = table()[type]
	GameState.spend(int(d["price"]))
	GameState.animals.append({"id": GameState.animals.size() + 1 + int(GameState.flags.get("animal_serial", 0)), "type": type,
		"name": animal_name, "home": str(d["home"]), "age": 0, "affection": 0, "fed": true, "petted": false})
	GameState.flags["animal_serial"] = int(GameState.flags.get("animal_serial", 0)) + 1
	GameState.add_stat("animals_bought", 1, type)
	AudioManager.sfx(str(d.get("sfx", "buy")))
	return ""


static func is_adult(a: Dictionary) -> bool:
	return int(a["age"]) >= int(table()[str(a["type"])]["grow_days"])


static func quality_of(a: Dictionary) -> int:
	var aff: int = int(a["affection"])
	var q: int = 0
	if aff >= Database.bal_i("affection_gold", 750):
		q = 2
	elif aff >= Database.bal_i("affection_silver", 400):
		q = 1
	if WorldObjects.rng.randf() < Skills.perk("product_quality") and q < 2:
		q += 1
	return q


## Caresse un animal (une fois par jour). Renvoie vrai si l'affection a augmenté.
static func pet(a: Dictionary) -> bool:
	if bool(a["petted"]):
		return false
	a["petted"] = true
	var gain: float = Database.bal_f("affection_pet", 15.0) * (1.0 + Skills.perk("affection_gain"))
	a["affection"] = mini(int(a["affection"]) + int(gain), Database.bal_i("affection_max", 1000))
	Skills.add_xp("husbandry", Database.bal_i("xp_pet", 5))
	GameState.add_stat("animals_petted")
	return true


static func hay_stored() -> int:
	return int(GameState.buildings.get("silo", {}).get("hay", 0))


## Range le foin tenu dans le silo (jusqu'à sa capacité). Renvoie la quantité stockée.
static func store_hay(n: int) -> int:
	if not GameState.buildings.has("silo"):
		return 0
	var room: int = Database.bal_i("silo_capacity", 240) - hay_stored()
	var put: int = mini(n, mini(room, GameState.item_count("hay")))
	if put <= 0:
		return 0
	GameState.remove_item("hay", put)
	GameState.buildings["silo"]["hay"] = hay_stored() + put
	return put


static func grazing_today() -> bool:
	return TimeManager.season_id() != "winter" and ["sun", "wind"].has(GameState.weather)


## Nuit : croissance, nourriture, affection, production. Renvoie le nombre de produits fabriqués.
static func nightly() -> int:
	var made: int = 0
	var graze: bool = grazing_today()
	for a: Dictionary in GameState.animals:
		var d: Dictionary = table()[str(a["type"])]
		a["age"] = int(a["age"]) + 1
		var fed: bool = false
		if graze:
			fed = true
			a["affection"] = mini(int(a["affection"]) + Database.bal_i("affection_graze", 4), Database.bal_i("affection_max", 1000))
		elif hay_stored() > 0:
			GameState.buildings["silo"]["hay"] = hay_stored() - 1
			fed = true
			a["affection"] = mini(int(a["affection"]) + Database.bal_i("affection_fed", 8), Database.bal_i("affection_max", 1000))
		else:
			a["affection"] = maxi(0, int(a["affection"]) + Database.bal_i("affection_unfed", -20))
		a["fed"] = fed
		if not bool(a["petted"]):
			a["affection"] = maxi(0, int(a["affection"]) + Database.bal_i("affection_unpet", -5))
		a["petted"] = false
		if not fed or not is_adult(a) or (int(a["age"]) % int(d["every"])) != 0:
			continue
		var home: Dictionary = GameState.buildings.get(str(a["home"]), {})
		if home.is_empty():
			continue
		var out: Array = home["out"]
		out.append({"id": str(d["product"]), "n": 1, "q": quality_of(a)})
		made += 1
		var bonus: Variant = d.get("bonus")
		if bonus != null and int(a["affection"]) >= int(bonus[2]) and WorldObjects.rng.randf() < float(bonus[1]):
			out.append({"id": str(bonus[0]), "n": 1, "q": 0})
			made += 1
	return made


## Récupère toute la production d'un bâtiment. Renvoie le nombre d'objets pris.
static func collect(home: String) -> int:
	var st: Dictionary = GameState.buildings.get(home, {})
	if st.is_empty():
		return 0
	var taken: int = 0
	var out: Array = st["out"]
	while not out.is_empty():
		var s: Dictionary = out[0]
		if GameState.add_item(str(s["id"]), int(s["n"]), int(s["q"])) > 0:
			EventBus.toast.emit(Loc.t("TOAST_INV_FULL"), str(s["id"]))
			break
		out.remove_at(0)
		taken += int(s["n"])
		Skills.add_xp("husbandry", Database.bal_i("xp_product", 7))
	if taken > 0:
		AudioManager.sfx("pickup")
	return taken
