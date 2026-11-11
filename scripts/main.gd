extends Node
## Racine de l'application.


func _ready() -> void:
	var label: Label = Label.new()
	label.text = ProjectSettings.get_setting("application/config/name")
	label.add_theme_font_override("font", load("res://assets/fonts/valbrume_big.fnt"))
	add_child(label)
