class_name JournalScreen
extends ScreenBase
## Journal : quêtes, relations, compétences, statistiques, calendrier.

const TABS: Array[String] = ["quests", "relations", "skills", "stats", "calendar"]

var _tab: String = "quests"
var _content: VBoxContainer
var _tab_buttons: Dictionary = {}


func _ready() -> void:
	var panel: PanelContainer = PanelContainer.new()
	center(panel)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.custom_minimum_size = Vector2(400, 0)
	panel.add_child(v)
	var tabs: HBoxContainer = HBoxContainer.new()
	for t: String in TABS:
		var b: Button = UIKit.button(Loc.t("JOURNAL_" + t.to_upper()), 70)
		b.pressed.connect(_show.bind(t))
		tabs.add_child(b)
		_tab_buttons[t] = b
	v.add_child(tabs)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 190)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 2)
	scroll.add_child(_content)
	var close_b: Button = UIKit.button(Loc.t("COMMON_CLOSE"), 90)
	close_b.pressed.connect(func() -> void: close(null))
	var br: HBoxContainer = HBoxContainer.new()
	br.alignment = BoxContainer.ALIGNMENT_END
	br.add_child(close_b)
	v.add_child(br)
	_show("quests")
	(_tab_buttons["quests"] as Button).grab_focus()
	AudioManager.sfx("ui_open")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("journal"):
		get_viewport().set_input_as_handled()
		close(null)
		return
	super(event)


func _line(text: String, col: Color = UIKit.INK, icon: Texture2D = null) -> void:
	var r: HBoxContainer = HBoxContainer.new()
	r.add_theme_constant_override("separation", 4)
	if icon != null:
		r.add_child(UIKit.icon_rect(icon, Vector2(12, 12)))
	var l: Label = UIKit.label(text, col)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.add_child(l)
	_content.add_child(r)


func _show(tab: String) -> void:
	_tab = tab
	for c: Node in _content.get_children():
		c.queue_free()
	for t: String in _tab_buttons:
		(_tab_buttons[t] as Button).disabled = t == tab
	match tab:
		"quests":
			_quests()
		"relations":
			_relations()
		"skills":
			_skills()
		"stats":
			_stats()
		"calendar":
			_calendar()


func _quests() -> void:
	_line(Loc.f("JOURNAL_BELLS", [Story.cast_count(true), Story.BELL_IDS.size()]), UIKit.BARK_D)
	for id: String in Story.BELL_IDS:
		_line(Loc.t("BELL_" + id.to_upper()), UIKit.LEAF if Story.is_cast(id) else UIKit.STONE, Database.sprite("bell_on" if Story.is_cast(id) else "bell_off"))
	_line(Loc.t("JOURNAL_ACTIVE_QUESTS"), UIKit.BARK_D)
	if Quests.active().is_empty():
		_line(Loc.t("QUEST_NONE"), UIKit.STONE)
	for q: Dictionary in Quests.active():
		_line("%s  %d/%d" % [Quests.describe(q), mini(Quests.progress(q), int(q["n"])), int(q["n"])])
	_line(Loc.f("JOURNAL_QUESTS_DONE", [int(GameState.quests["done"])]), UIKit.STONE)
	_line(Loc.f("JOURNAL_PAGES", [Story.lore_read(), Story.lore_total()]), UIKit.BARK_D)
	for i: int in Story.lore_read():
		_line(Loc.t("LORE_%d" % (i + 1)), UIKit.STONE)


func _relations() -> void:
	for id: String in Friendship.ids():
		var d: Dictionary = Friendship.npc(id)
		var hearts: int = Friendship.hearts(id)
		var b: Array = d["birthday"]
		var row: String = "%s — %s   %s %d   %s" % [Loc.t("NPC_" + id.to_upper()), Loc.t("JOB_" + id.to_upper()),
			"♥".repeat(hearts) + "·".repeat(Database.bal_i("max_hearts", 10) - hearts),
			int(b[1]), Loc.t("SEASON_" + str(TimeManager.SEASONS[int(b[0])]).to_upper())]
		if bool(Friendship.rel(id)["dating"]):
			row += "  " + Loc.t("JOURNAL_DATING")
		if GameState.spouse == id:
			row += "  " + Loc.t("JOURNAL_SPOUSE")
		_line(row)


func _skills() -> void:
	for s: String in GameState.SKILLS:
		var lvl: int = GameState.skill_level(s)
		var nxt: int = Skills.xp_for_next(s)
		var xp: int = int(GameState.skills[s]["xp"])
		_line("%s  %s %d   %s" % [Loc.t("SKILL_" + s.to_upper()), Loc.t("BUILD_LEVEL"), lvl, "%d/%d" % [xp, nxt] if nxt >= 0 else "MAX"], UIKit.INK, Database.sprite("skill_" + s))


func _stats() -> void:
	_line("%s : %d" % [Loc.t("JOURNAL_DAYS"), GameState.day + 1])
	_line("%s : %d" % [Loc.t("JOURNAL_HARVESTED"), GameState.stat("crops_harvested")])
	_line("%s : %d" % [Loc.t("JOURNAL_FISH"), GameState.stat("fish_caught")])
	_line("%s : %d" % [Loc.t("JOURNAL_MONSTERS"), GameState.stat("monsters_killed")])
	_line("%s : %d" % [Loc.t("JOURNAL_FLOOR"), int(GameState.mine.get("deepest", 0))])
	_line("%s : %d" % [Loc.t("JOURNAL_SHIPPED"), GameState.stat("items_shipped")])
	_line("%s : %d" % [Loc.t("JOURNAL_EARNED"), GameState.stat("money_earned")])
	_line("%s : %d" % [Loc.t("JOURNAL_DONATED"), Collections.donated_count()])
	_line("%s : %d h" % [Loc.t("JOURNAL_PLAYTIME"), int(GameState.playtime) / 3600])


func _calendar() -> void:
	_line(Loc.f("JOURNAL_TODAY", [TimeManager.date_text(), TimeManager.season_text()]), UIKit.BARK_D)
	for id: String in Festivals.table():
		var f: Dictionary = Festivals.table()[id]
		_line("%s : %s %d" % [Loc.t("FEST_" + id.to_upper()), Loc.t("SEASON_" + str(TimeManager.SEASONS[int(f["season"])]).to_upper()), int(f["day"])])
	for id: String in Friendship.ids():
		var b: Array = Friendship.npc(id)["birthday"]
		_line("%s : %s %d" % [Loc.t("NPC_" + id.to_upper()), Loc.t("SEASON_" + str(TimeManager.SEASONS[int(b[0])]).to_upper()), int(b[1])], UIKit.STONE)
