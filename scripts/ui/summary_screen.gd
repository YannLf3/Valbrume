class_name SummaryScreen
extends ScreenBase
## Bilan de la nuit : ventes du coffre d'expédition, incidents, météo du lendemain.

var summary: Dictionary = {}


func _init() -> void:
	super()
	cancelable = false


func setup(p_summary: Dictionary) -> SummaryScreen:
	summary = p_summary
	return self


func _ready() -> void:
	var panel: PanelContainer = PanelContainer.new()
	center(panel)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.custom_minimum_size = Vector2(250, 0)
	panel.add_child(v)
	v.add_child(UIKit.label(Loc.f("SUMMARY_TITLE", [int(summary["day"]) + 1]), UIKit.BARK_D, true))
	v.add_child(UIKit.label(Loc.t("SUMMARY_SHIPPED")))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 92)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var lines: Array = summary.get("shipped", [])
	if lines.is_empty():
		list.add_child(UIKit.label(Loc.t("SUMMARY_NOTHING"), UIKit.STONE))
	for l: Dictionary in lines:
		var r: HBoxContainer = HBoxContainer.new()
		r.add_child(UIKit.icon_rect(Database.icon(str(l["id"])), Vector2(14, 14)))
		var name_l: Label = UIKit.label("%s x%d" % [UIKit.stack_name(str(l["id"]), int(l["q"])), int(l["n"])])
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(name_l)
		r.add_child(UIKit.label(str(int(l["value"]))))
		list.add_child(r)
	var tot: HBoxContainer = HBoxContainer.new()
	tot.add_child(UIKit.icon_rect(Database.sprite("coin"), Vector2(12, 12)))
	var tl: Label = UIKit.label(Loc.t("SUMMARY_TOTAL"))
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tot.add_child(tl)
	tot.add_child(UIKit.label(str(int(summary["total"]))))
	v.add_child(tot)
	if bool(summary.get("passed_out", false)):
		v.add_child(_note(Loc.f("SUMMARY_FAINTED", [int(summary["loss"])]), UIKit.RED))
	if int(summary.get("eaten", 0)) > 0:
		v.add_child(_note(Loc.f("SUMMARY_PESTS", [int(summary["eaten"])]), UIKit.RED))
	if str(summary.get("built", "")) != "":
		v.add_child(_note(Loc.f("SUMMARY_BUILT", [Loc.t("BUILDING_" + str(summary["built"]).to_upper())]), UIKit.LEAF))
	if bool(summary.get("season_changed", false)):
		v.add_child(_note(Loc.f("SUMMARY_SEASON", [TimeManager.season_text()]), UIKit.LEAF))
	var w: HBoxContainer = HBoxContainer.new()
	w.add_child(UIKit.icon_rect(Database.sprite("weather_" + GameState.weather), Vector2(12, 12)))
	w.add_child(UIKit.label(Loc.f("SUMMARY_TOMORROW", [Loc.t("WEATHER_" + GameState.weather.to_upper())])))
	v.add_child(w)
	var b: Button = UIKit.button(Loc.t("COMMON_CONTINUE"), 80)
	b.pressed.connect(func() -> void: close(null))
	var br: HBoxContainer = HBoxContainer.new()
	br.alignment = BoxContainer.ALIGNMENT_CENTER
	br.add_child(b)
	v.add_child(br)
	b.grab_focus()
	if int(summary["total"]) > 0:
		AudioManager.sfx("coins")


func _note(text: String, col: Color) -> Label:
	var l: Label = UIKit.label(text, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(240, 0)
	return l
