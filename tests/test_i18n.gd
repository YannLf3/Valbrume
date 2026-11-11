extends TestCase
## Couverture FR/EN des textes qui dépendent des données (clés construites à l'exécution).


func _both(key: String, what: String) -> void:
	for loc: String in ["fr", "en"]:
		TranslationServer.set_locale(loc)
		var t: String = TranslationServer.translate(StringName(key))
		ok(t != key and t.strip_edges() != "", "%s : clé %s manquante en %s" % [what, key, loc])
	TranslationServer.set_locale("fr")


func test_every_item_and_category_is_translated() -> void:
	var cats: Dictionary = {}
	for id: String in Database.items:
		_both("ITEM_" + id.to_upper(), "objet")
		if bool(Database.items[id].get("desc", false)):
			_both("ITEMD_" + id.to_upper(), "description")
		cats[str(Database.items[id]["cat"])] = true
	for c: String in cats:
		_both("CAT_" + c.to_upper(), "catégorie")


func test_world_vocabulary_is_translated() -> void:
	for id: String in Database.maps:
		var key: String = str(Database.map(id).get("name", ""))
		if key != "":
			_both(key, "carte " + id)
	_both("MAP_MINE_FLOOR", "mine")
	for w: String in Database.table("weather")["kinds"]:
		_both("WEATHER_" + w.to_upper(), "météo")
	for s: String in TimeManager.SEASONS:
		_both("SEASON_" + s.to_upper(), "saison")
	for d: int in 7:
		_both("WEEKDAY_%d" % d, "jour")
	for s: String in GameState.SKILLS:
		_both("SKILL_" + s.to_upper(), "talent")
	for s: String in Database.table("skills"):
		for lvl: String in Database.table("skills")[s]:
			var p: Variant = Database.table("skills")[s][lvl].get("perk")
			if p != null:
				_both("PERK_" + str(p[0]).to_upper(), "bonus")
	for b: String in Buildings.TYPES:
		_both("BUILDING_" + b.to_upper(), "bâtiment")
	for a: String in Animals.table():
		_both("ANIMAL_" + a.to_upper(), "animal")
	_both("ANIMAL_DOG", "chien")
	for m: String in Database.table("monsters"):
		_both("MON_" + m.to_upper(), "monstre")
	for sh: String in Database.table("shops"):
		_both("SHOP_" + sh.to_upper(), "magasin")
	for a: String in InputManager.REMAPPABLE:
		_both("ACT_" + a.to_upper(), "action")
	for l: String in Settings.LANGUAGES:
		_both("LANG_" + l.to_upper(), "langue")
	for l: String in Settings.LAYOUTS:
		_both("OPT_KEYS_" + l.to_upper(), "disposition")
	for l: String in Settings.TOUCH_MODES:
		_both("OPT_TOUCH_" + l.to_upper(), "tactile")
	for f: String in Festivals.table():
		_both("FEST_" + f.to_upper(), "festival")
		_both("FESTI_" + f.to_upper(), "festival")
		_both("FEST_GAME_" + str(Festivals.table()[f]["game"]).to_upper(), "jeu de fête")
	for c: String in Collections.CATEGORIES:
		_both("COLL_" + c.to_upper(), "collection")
	for i: int in range(1, 6):
		_both("LORE_%d" % i, "registre")
	for t: String in Quests.TYPES:
		_both("QUEST_" + t.to_upper(), "quête")


func test_placeholders_match_in_both_languages() -> void:
	var f: FileAccess = FileAccess.open("res://i18n/strings.csv", FileAccess.READ)
	f.get_csv_line()
	var rx: RegEx = RegEx.new()
	rx.compile("%[-+0-9.]*[sdf]|\\{player\\}|\\{farm\\}")
	var n: int = 0
	while not f.eof_reached():
		var row: PackedStringArray = f.get_csv_line()
		if row.size() < 3 or row[0] == "":
			continue
		n += 1
		eq(rx.search_all(row[1]).size(), rx.search_all(row[2]).size(), "marqueurs de %s" % row[0])
		ok(row[1].strip_edges() != "" and row[2].strip_edges() != "", "valeurs de %s" % row[0])
	ok(n > 1000, "plus de 1000 clés (%d)" % n)


func test_language_switch_changes_text() -> void:
	TranslationServer.set_locale("fr")
	var fr: String = TranslationServer.translate(&"SEASON_SPRING")
	TranslationServer.set_locale("en")
	var en: String = TranslationServer.translate(&"SEASON_SPRING")
	TranslationServer.set_locale("fr")
	eq(fr, "Printemps")
	eq(en, "Spring")
