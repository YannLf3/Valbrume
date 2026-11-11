class_name ScreenBase
extends Control
## Base des écrans plein cadre : fond assombri, fermeture par « annuler ».

signal closed(result: Variant)

var cancelable: bool = true
var dim: bool = true


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UIKit.theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS


func _enter_tree() -> void:
	if dim and get_node_or_null("Dim") == null:
		var d: ColorRect = ColorRect.new()
		d.name = "Dim"
		d.color = Color(0.1, 0.07, 0.13, 0.55)
		d.set_anchors_preset(Control.PRESET_FULL_RECT)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(d)
		move_child(d, 0)


func close(result: Variant = null) -> void:
	closed.emit(result)
	queue_free()


func _input(event: InputEvent) -> void:
	if cancelable and event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		AudioManager.sfx("ui_close")
		close(null)


## Place un contrôle au centre de l'écran.
func center(c: Control) -> void:
	c.set_anchors_preset(Control.PRESET_CENTER)
	c.grow_horizontal = Control.GROW_DIRECTION_BOTH
	c.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(c)
