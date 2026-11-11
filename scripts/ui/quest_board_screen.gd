class_name QuestBoardScreen
extends ScreenBase
## Tableau des quêtes d'Ormelune : accepter les annonces du jour, remettre les commandes remplies.

var _list: VBoxContainer


func _ready() -> void:
	var panel: PanelContainer = PanelContainer.new()
	center(panel)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.custom_minimum_size = Vector2(380, 0)
	panel.add_child(v)
	v.add_child(UIKit.label(Loc.t("QUEST_BOARD_TITLE"), UIKit.BARK_D, true))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 180)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 2)
	scroll.add_child(_list)
	var close_b: Button = UIKit.button(Loc.t("COMMON_CLOSE"), 90)
	close_b.pressed.connect(func() -> void: close(null))
	var br: HBoxContainer = HBoxContainer.new()
	br.alignment = BoxContainer.ALIGNMENT_END
	br.add_child(close_b)
	v.add_child(br)
	_refresh()
	close_b.grab_focus()
	AudioManager.sfx("ui_open")


func _refresh() -> void:
	for c: Node in _list.get_children():
		c.queue_free()
	_list.add_child(UIKit.label(Loc.f("QUEST_ACTIVE", [Quests.active().size(), int(Quests.cfg()["max_active"])]), UIKit.BARK_D))
	for i: int in Quests.active().size():
		_list.add_child(_row(Quests.active()[i], i, true))
	_list.add_child(UIKit.label(Loc.t("QUEST_AVAILABLE"), UIKit.BARK_D))
	var board: Array = GameState.quests["board"]
	if board.is_empty():
		_list.add_child(UIKit.label(Loc.t("QUEST_NONE"), UIKit.STONE))
	for i: int in board.size():
		_list.add_child(_row(board[i], i, false))


func _row(q: Dictionary, index: int, is_active: bool) -> PanelContainer:
	var pc: PanelContainer = PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UIKit.box("panel_inset", 3, 3, 2, 2))
	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	pc.add_child(h)
	var col: VBoxContainer = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	col.add_child(UIKit.label(Quests.describe(q)))
	var sub: HBoxContainer = HBoxContainer.new()
	sub.add_theme_constant_override("separation", 4)
	sub.add_child(UIKit.label(Loc.f("QUEST_FROM", [Loc.t("NPC_" + str(q["npc"]).to_upper())]), UIKit.STONE))
	sub.add_child(UIKit.icon_rect(Database.sprite("coin"), Vector2(10, 10)))
	sub.add_child(UIKit.label(str(int(q["reward"])), UIKit.STONE))
	if is_active:
		sub.add_child(UIKit.label("%d/%d" % [mini(Quests.progress(q), int(q["n"])), int(q["n"])], UIKit.LEAF if Quests.can_complete(q) else UIKit.RED))
	col.add_child(sub)
	h.add_child(col)
	var b: Button = UIKit.button(Loc.t("QUEST_TURN_IN" if is_active else "QUEST_ACCEPT"), 70)
	if is_active:
		b.disabled = not Quests.can_complete(q)
		b.pressed.connect(func() -> void:
			var done: Dictionary = Quests.complete(index)
			if not done.is_empty():
				EventBus.toast.emit(Loc.f("QUEST_DONE", [int(done["reward"])]), "")
			_refresh())
	else:
		b.disabled = Quests.active().size() >= int(Quests.cfg()["max_active"])
		b.pressed.connect(func() -> void:
			var err: String = Quests.accept(index)
			if err != "":
				EventBus.toast.emit(Loc.t(err), "")
			_refresh())
	h.add_child(b)
	return pc
