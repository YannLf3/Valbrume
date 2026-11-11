class_name NamePrompt
extends ScreenBase
## Saisie d'un nom (animaux). Résultat : le texte, ou null si annulé.

var default_name: String = ""


func _ready() -> void:
	var panel: PanelContainer = PanelContainer.new()
	center(panel)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.custom_minimum_size = Vector2(200, 0)
	panel.add_child(v)
	v.add_child(UIKit.label(Loc.t("ANIMAL_NAME_PROMPT")))
	var edit: LineEdit = LineEdit.new()
	edit.text = default_name
	edit.max_length = 14
	v.add_child(edit)
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	var ok_b: Button = UIKit.button(Loc.t("COMMON_OK"), 60)
	ok_b.pressed.connect(func() -> void:
		var t: String = edit.text.strip_edges()
		close(t if t != "" else default_name))
	edit.text_submitted.connect(func(_t: String) -> void: ok_b.pressed.emit())
	var cancel: Button = UIKit.button(Loc.t("COMMON_CANCEL"), 60)
	cancel.pressed.connect(func() -> void: close(null))
	row.add_child(cancel)
	row.add_child(ok_b)
	v.add_child(row)
	edit.grab_focus()
	edit.select_all()
