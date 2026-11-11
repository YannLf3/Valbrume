class_name Combat
extends RefCounted
## Règles de combat : dégâts de l'épée, coups critiques, défense, mort et pénalités.

static var rng: RandomNumberGenerator = RandomNumberGenerator.new()


static func sword_level() -> int:
	var best: int = 0
	for s: Variant in GameState.inventory:
		if s != null and str(Database.item(str(s["id"])).get("tool", "")) == "sword":
			best = maxi(best, int(Database.item(str(s["id"])).get("level", 1)))
	return best


static func damage_of(sword_lvl: int) -> int:
	var base: Array = Database.bal("sword_damage", [8])
	var d: float = float(base[clampi(sword_lvl - 1, 0, base.size() - 1)]) + Skills.perk("damage")
	d += GameState.skill_level("combat") * Database.bal_f("combat_damage_per_level", 1.0) + GameState.buff_total("attack") * 3.0
	return int(d)


## Dégâts d'un coup et indicateur de critique : {"damage": int, "crit": bool}.
static func roll_hit(sword_lvl: int) -> Dictionary:
	var d: int = damage_of(sword_lvl)
	var crit: bool = rng.randf() < Skills.perk("crit_chance")
	if crit:
		d = int(d * 1.8)
	return {"damage": d, "crit": crit}


static func defense() -> int:
	return int(Skills.perk("defense") + GameState.buff_total("defense") * 2.0)


## Un monstre blesse le joueur. Renvoie les dégâts réellement subis.
static func hurt_player(raw: int) -> int:
	var d: int = maxi(1, raw - defense())
	GameState.change_health(-float(d))
	AudioManager.sfx("hurt")
	EventBus.screen_shake.emit(1.5)
	return d


static func is_dead() -> bool:
	return GameState.health <= 0.0


## Pénalité de mort : une part de l'argent et quelques piles d'objets. Renvoie {"money": n, "items": [ids]}.
static func death_penalty() -> Dictionary:
	var loss: int = mini(GameState.money * Database.bal_i("death_money_pct", 12) / 100, Database.bal_i("death_money_max", 2500))
	GameState.money -= loss
	EventBus.money_changed.emit(GameState.money)
	var candidates: Array[int] = []
	for i: int in GameState.inventory.size():
		var s: Variant = GameState.inventory[i]
		if s != null and not Database.item(str(s["id"])).has("tool"):
			candidates.append(i)
	var lost: Array[String] = []
	for k: int in Database.bal_i("death_item_losses", 3):
		if candidates.is_empty():
			break
		var pick: int = rng.randi_range(0, candidates.size() - 1)
		var idx: int = candidates[pick]
		candidates.remove_at(pick)
		lost.append(str(GameState.inventory[idx]["id"]))
		GameState.inventory[idx] = null
	EventBus.inventory_changed.emit()
	return {"money": loss, "items": lost}
