class_name Story
extends RefCounted
## Fil rouge : refondre les six cloches du Carillon. Chaque cloche a des exigences et débloque un lieu ou une fonction.

const BELL_IDS: Array[String] = ["furrows", "waves", "stone", "hearth", "flocks", "great"]


static func bells() -> Array:
	return Database.table("story").get("bells", [])


static func is_cast(id: String) -> bool:
	return GameState.flag("bell_" + id)


static func cast_count(include_great: bool = false) -> int:
	var n: int = 0
	for id: String in BELL_IDS:
		if is_cast(id) and (include_great or id != "great"):
			n += 1
	return n


static func hearts_total() -> int:
	var n: int = 0
	for id: String in Friendship.ids():
		n += Friendship.hearts(id)
	return n


## [possédé, requis] pour une exigence.
static func progress(req: Array) -> Vector2i:
	var kind: String = str(req[0])
	var target: String = str(req[1])
	var need: int = int(req[2])
	match kind:
		"stat":
			return Vector2i(GameState.stat(target), need)
		"kinds":
			return Vector2i(GameState.stat_kinds(target), need)
		"item":
			return Vector2i(GameState.item_count(target), need)
		"money":
			return Vector2i(GameState.money, need)
		"mine_floor":
			return Vector2i(int(GameState.mine.get("deepest", 0)), need)
		"hearts_total":
			return Vector2i(hearts_total(), need)
		"animals":
			return Vector2i(GameState.animals.size(), need)
		"building":
			return Vector2i(Buildings.level(target), need)
		"bells":
			return Vector2i(cast_count(), need)
		"donated":
			return Vector2i(Collections.donated_count(), need)
	return Vector2i(0, need)


static func requirement_text(req: Array) -> String:
	var kind: String = str(req[0])
	var target: String = str(req[1])
	var need: int = int(req[2])
	match kind:
		"stat":
			return Loc.f("REQ_HARVEST", [need])
		"kinds":
			return Loc.f("REQ_FISH_KINDS", [need])
		"item":
			return Loc.f("REQ_ITEM", [need, Database.item_name(target)])
		"money":
			return Loc.f("REQ_MONEY", [need])
		"mine_floor":
			return Loc.f("REQ_FLOOR", [need])
		"hearts_total":
			return Loc.f("REQ_HEARTS", [need])
		"animals":
			return Loc.f("REQ_ANIMALS", [need])
		"building":
			return Loc.f("REQ_BUILDING", [Loc.t("BUILDING_" + target.to_upper()), need])
		"bells":
			return Loc.f("REQ_BELLS", [need])
		"donated":
			return Loc.f("REQ_DONATED", [need])
	return ""


static func requirements(id: String) -> Array:
	for b: Dictionary in bells():
		if str(b["id"]) == id:
			return b["req"]
	return []


static func is_met(id: String) -> bool:
	for r: Array in requirements(id):
		var p: Vector2i = progress(r)
		if p.x < p.y:
			return false
	return true


static func can_cast(id: String) -> bool:
	return not is_cast(id) and is_met(id)


## Fond la cloche : retire matériaux et argent, applique l'effet. Renvoie "" ou une clé d'erreur.
static func cast(id: String) -> String:
	if is_cast(id):
		return "BELL_ALREADY"
	if not is_met(id):
		return "CRAFT_MISSING"
	for r: Array in requirements(id):
		if str(r[0]) == "item":
			GameState.remove_item(str(r[1]), int(r[2]))
		elif str(r[0]) == "money":
			GameState.spend(int(r[2]))
	GameState.flags["bell_" + id] = true
	GameState.story["bells"][id] = true
	match id:
		"furrows":
			GameState.flags["greenhouse_built"] = true
		"great":
			GameState.flags["game_won"] = true
	AudioManager.sfx("bell_big")
	EventBus.story_progress.emit(id)
	Recipes.refresh()
	return ""


# --- carnet d'Odile ---------------------------------------------------------------

static func lore_total() -> int:
	return int(Database.table("story").get("lore", 0))


static func lore_read() -> int:
	return int(GameState.story["notes"].size())


## Lit la page suivante du registre. Renvoie la clé du texte, ou "" s'il n'y en a plus.
static func read_next_page() -> String:
	var n: int = lore_read()
	if n >= lore_total():
		return ""
	GameState.story["notes"][str(n + 1)] = true
	return "LORE_%d" % (n + 1)
