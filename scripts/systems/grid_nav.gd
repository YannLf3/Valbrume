class_name GridNav
extends RefCounted
## Pathfinding A* sur la grille de collisions d'une carte (AStarGrid2D, 4 directions).

var rt: MapRuntime
var _astar: AStarGrid2D = AStarGrid2D.new()
var _dirty: bool = true


func _init(p_rt: MapRuntime) -> void:
	rt = p_rt
	_astar.region = Rect2i(0, 0, rt.w, rt.h)
	_astar.cell_size = Vector2(1, 1)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN


func mark_dirty() -> void:
	_dirty = true


func rebuild() -> void:
	_astar.update()
	for y: int in rt.h:
		for x: int in rt.w:
			_astar.set_point_solid(Vector2i(x, y), rt.is_solid(Vector2i(x, y)))
	_dirty = false


## Cases à parcourir de `a` à `b` (incluses). Vide si aucun chemin.
func path(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	if _dirty:
		rebuild()
	if not rt.in_bounds(a) or not rt.in_bounds(b):
		return []
	var from: Vector2i = a
	if _astar.is_point_solid(from):
		from = nearest_free(a)
	if _astar.is_point_solid(b):
		return []
	var p: Array[Vector2i] = _astar.get_id_path(from, b)
	return p


func nearest_free(c: Vector2i) -> Vector2i:
	for r: int in range(1, 4):
		for dy: int in range(-r, r + 1):
			for dx: int in range(-r, r + 1):
				var n: Vector2i = c + Vector2i(dx, dy)
				if rt.in_bounds(n) and not _astar.is_point_solid(n):
					return n
	return c
