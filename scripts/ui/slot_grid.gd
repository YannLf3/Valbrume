class_name SlotGrid
extends Control
## Grille d'emplacements d'objets (sac, barre rapide, coffres). Dessinée d'un seul bloc.

signal slot_pressed(index: int, button: int)
signal slot_hovered(index: int)

const CELL: int = 20
const ICON_OFFSET: int = 2

var slots: Array = []
var first: int = 0
var count: int = 12
var cols: int = 12
var selected: int = -1
var cursor: int = -1
var hover: int = -1


func configure(p_slots: Array, p_first: int, p_count: int, p_cols: int) -> void:
	slots = p_slots
	first = p_first
	count = p_count
	cols = p_cols
	custom_minimum_size = Vector2(cols * CELL, ((count + cols - 1) / cols) * CELL)
	size = custom_minimum_size
	queue_redraw()


func _ready() -> void:
	if not EventBus.inventory_changed.is_connected(queue_redraw):
		EventBus.inventory_changed.connect(queue_redraw)


func index_at(p: Vector2) -> int:
	if p.x < 0 or p.y < 0:
		return -1
	var i: int = int(p.y) / CELL * cols + int(p.x) / CELL
	if int(p.x) / CELL >= cols or i >= count:
		return -1
	return first + i


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var i: int = index_at(event.position)
		if i >= 0:
			slot_pressed.emit(i, event.button_index)
			accept_event()
	elif event is InputEventMouseMotion:
		var h: int = index_at(event.position)
		if h != hover:
			hover = h
			slot_hovered.emit(h)
			queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and hover != -1:
		hover = -1
		slot_hovered.emit(-1)
		queue_redraw()


func _draw() -> void:
	var f: Font = UIKit.font()
	for i: int in count:
		var idx: int = first + i
		var pos: Vector2 = Vector2((i % cols) * CELL, (i / cols) * CELL)
		var hot: bool = idx == selected or idx == cursor
		draw_texture(Database.sprite("slot_selected" if hot else "slot"), pos)
		if idx >= slots.size() or slots[idx] == null:
			continue
		var s: Dictionary = slots[idx]
		var icon: Texture2D = Database.icon(str(s["id"]))
		if icon != null:
			draw_texture(icon, pos + Vector2(ICON_OFFSET, ICON_OFFSET))
		var q: int = int(s["q"])
		if q > 0:
			draw_texture(Database.sprite("star_gold" if q == 2 else "star_silver"), pos + Vector2(1, 1))
		var n: int = int(s["n"])
		if n > 1:
			var txt: String = str(n)
			var w: float = f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, UIKit.FONT_SIZE).x
			var p: Vector2 = pos + Vector2(CELL - 2 - w, CELL - 4)
			draw_string(f, p + Vector2(1, 1), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, UIKit.FONT_SIZE, UIKit.INK)
			draw_string(f, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, UIKit.FONT_SIZE, Color.WHITE)
