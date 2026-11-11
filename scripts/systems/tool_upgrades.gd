class_name ToolUpgrades
extends RefCounted
## Amélioration des outils chez le forgeron : niveaux 1 à 4, minerais + argent, quelques jours de délai.

static func info(item_id: String) -> Dictionary:
	return Database.item(item_id)


static func next_id(item_id: String) -> String:
	var it: Dictionary = info(item_id)
	return "%s_%d" % [str(it.get("tool", "")), int(it.get("level", 1)) + 1]


static func cost(item_id: String) -> Dictionary:
	var lv: int = int(info(item_id).get("level", 1))
	return Database.table("tools")["upgrades"].get(str(lv + 1), {})


static func can_start(item_id: String) -> String:
	if not info(item_id).has("tool"):
		return "UPGRADE_MAX"
	var c: Dictionary = cost(item_id)
	if c.is_empty() or not Database.has_item(next_id(item_id)):
		return "UPGRADE_MAX"
	if not GameState.tool_upgrade.is_empty():
		return "UPGRADE_BUSY"
	if GameState.money < int(c["price"]):
		return "SHOP_NO_MONEY"
	for id: String in c["items"]:
		if GameState.item_count(id) < int(c["items"][id]):
			return "CRAFT_MISSING"
	return ""


static func start(item_id: String) -> String:
	var err: String = can_start(item_id)
	if err != "":
		return err
	var c: Dictionary = cost(item_id)
	GameState.spend(int(c["price"]))
	for id: String in c["items"]:
		GameState.remove_item(id, int(c["items"][id]))
	GameState.remove_item(item_id, 1)
	GameState.tool_upgrade = {"item": next_id(item_id), "days": Database.bal_i("tool_upgrade_days", 2)}
	AudioManager.sfx("buy")
	return ""


## Nuit : l'outil avance ; livré dans le sac quand il est prêt. Renvoie l'identifiant livré ou "".
static func nightly() -> String:
	if GameState.tool_upgrade.is_empty():
		return ""
	GameState.tool_upgrade["days"] = int(GameState.tool_upgrade["days"]) - 1
	if int(GameState.tool_upgrade["days"]) > 0:
		return ""
	var id: String = str(GameState.tool_upgrade["item"])
	if GameState.add_item(id, 1) > 0:
		GameState.tool_upgrade["days"] = 0
		return ""
	GameState.tool_upgrade = {}
	return id
