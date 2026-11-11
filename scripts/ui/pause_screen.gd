class_name PauseScreen
extends ScreenBase
## Menu pause : reprendre, sauvegarder, options, retour au titre.

signal action_chosen(action: String)


func _ready() -> void:
	var panel: PanelContainer = PanelContainer.new()
	center(panel)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.custom_minimum_size = Vector2(140, 0)
	panel.add_child(v)
	v.add_child(UIKit.label(Loc.t("PAUSE_TITLE"), UIKit.BARK_D, true))
	var first: Button = null
	for entry: Array in [["resume", "PAUSE_RESUME"], ["save", "PAUSE_SAVE"], ["options", "PAUSE_OPTIONS"], ["title", "PAUSE_TO_TITLE"]]:
		var b: Button = UIKit.button(Loc.t(str(entry[1])), 120)
		b.pressed.connect(func() -> void:
			action_chosen.emit(str(entry[0]))
			close(str(entry[0])))
		v.add_child(b)
		if first == null:
			first = b
	first.grab_focus()
