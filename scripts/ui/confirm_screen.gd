class_name ConfirmScreen
extends ScreenBase
## Petite confirmation oui / non. Résultat : true ou false.

var message: String = ""


func setup(p_message: String) -> ConfirmScreen:
	message = p_message
	return self


func _ready() -> void:
	var panel: PanelContainer = PanelContainer.new()
	center(panel)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	var l: Label = UIKit.label(message)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(190, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var no: Button = UIKit.button(Loc.t("COMMON_NO"), 60)
	var yes: Button = UIKit.button(Loc.t("COMMON_YES"), 60)
	no.pressed.connect(func() -> void: close(false))
	yes.pressed.connect(func() -> void: close(true))
	row.add_child(no)
	row.add_child(yes)
	v.add_child(row)
	no.grab_focus()
