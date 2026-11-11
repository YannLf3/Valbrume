class_name MineGen
extends RefCounted
## Génération procédurale des étages de la mine (automate cellulaire), reproductible par graine.
## 60 étages, 3 biomes de 20, ascenseur tous les 5 étages, coffre tous les 10.

const FLOOR_CHARS: Array[String] = ["", "a", "b", "c"]
const WALL_CHARS: Array[String] = ["", "A", "B", "C"]
const DIRS4: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]


static func floor_count() -> int:
	return Database.bal_i("mine_floors", 60)


static func biome_of(floor_n: int) -> int:
	return clampi((floor_n - 1) / Database.bal_i("mine_biome_size", 20) + 1, 1, 3)


static func is_elevator_floor(floor_n: int) -> bool:
	return floor_n % Database.bal_i("mine_elevator_step", 5) == 0


static func is_treasure_floor(floor_n: int) -> bool:
	return floor_n % 10 == 0


static func map_id(floor_n: int) -> String:
	return "mine_%d" % floor_n


static func floor_of(id: String) -> int:
	return int(id.substr(5)) if id.begins_with("mine_") and id.substr(5).is_valid_int() else 0


static func seed_for(floor_n: int) -> int:
	return hash([GameState.seed, floor_n, GameState.day])


static func generate(floor_n: int) -> Dictionary:
	return generate_with_seed(floor_n, seed_for(floor_n))


static func generate_with_seed(floor_n: int, seed_value: int) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var W: int = Database.bal_i("mine_w", 34)
	var H: int = Database.bal_i("mine_h", 24)
	var biome: int = biome_of(floor_n)
	var cfg: Dictionary = Database.table("mine")["biomes"][str(biome)]
	# 1. cavernes
	var wall: Array = []
	var region: Array[Vector2i] = []
	for attempt: int in 12:
		wall = _caves(rng, W, H)
		region = _largest_region(wall, W, H)
		if region.size() >= W * H / 5:
			break
	if region.size() < W * H / 5:
		wall = _fallback(W, H)
		region = _largest_region(wall, W, H)
	var in_region: Dictionary = {}
	for c: Vector2i in region:
		in_region[c] = true
	for y: int in H:
		for x: int in W:
			wall[y][x] = not in_region.has(Vector2i(x, y))
	# 2. entrée (à gauche) ; alcôve pour l'ascenseur
	var entrance: Vector2i = region[0]
	for c: Vector2i in region:
		if c.x < entrance.x or (c.x == entrance.x and absi(c.y - H / 2) < absi(entrance.y - H / 2)):
			entrance = c
	var elevator: bool = is_elevator_floor(floor_n)
	if elevator:
		entrance = Vector2i(clampi(entrance.x, 2, W - 8), clampi(entrance.y, 3, H - 4))
		_carve(wall, in_region, Rect2i(entrance.x - 1, entrance.y - 2, 6, 5), W, H)
		region = _largest_region(wall, W, H)
		in_region.clear()
		for c: Vector2i in region:
			in_region[c] = true
	var start: Vector2i = _neighbor_free(entrance, in_region, entrance)
	# 3. sortie : la case la plus éloignée par le chemin
	var exit_cell: Vector2i = _farthest(entrance, in_region)
	var exit_spot: Vector2i = _neighbor_free(exit_cell, in_region, exit_cell)
	# 4. bassin d'eau (pêche en mine)
	var water_cells: Array[Vector2i] = []
	if rng.randf() < float(Database.table("mine")["pool_chance"]) and floor_n > 1:
		var pc: Vector2i = region[rng.randi_range(0, region.size() - 1)]
		if pc.distance_to(Vector2(entrance)) > 8.0 and pc.distance_to(Vector2(exit_cell)) > 5.0:
			var cells: Array[Vector2i] = []
			for dy: int in range(-1, 2):
				for dx: int in range(-1, 2):
					cells.append(pc + Vector2i(dx, dy))
			var all_ok: bool = true
			for c: Vector2i in cells:
				if not in_region.has(c):
					all_ok = false
			if all_ok:
				water_cells = cells
				for c: Vector2i in cells:
					in_region.erase(c)
	return _build(floor_n, biome, cfg, rng, W, H, wall, in_region, entrance, start, exit_cell, exit_spot, elevator, water_cells)


static func _build(floor_n: int, biome: int, cfg: Dictionary, rng: RandomNumberGenerator, W: int, H: int, wall: Array, in_region: Dictionary,
		entrance: Vector2i, start: Vector2i, exit_cell: Vector2i, exit_spot: Vector2i, elevator: bool, water_cells: Array) -> Dictionary:
	var water: Dictionary = {}
	for c: Vector2i in water_cells:
		water[c] = true
	var rows: Array = []
	for y: int in H:
		var row: String = ""
		for x: int in W:
			var c: Vector2i = Vector2i(x, y)
			if water.has(c):
				row += "~"
			elif in_region.has(c):
				row += FLOOR_CHARS[biome]
			else:
				row += WALL_CHARS[biome]
		rows.append(row)
	var objects: Array = []
	var taken: Dictionary = {entrance: true, start: true, exit_cell: true, exit_spot: true}
	for dy: int in range(-2, 3):
		for dx: int in range(-2, 3):
			taken[start + Vector2i(dx, dy)] = true
	var statics: Array = []
	var zones: Array = []
	if elevator:
		var ex: int = entrance.x + 1
		var ey: int = entrance.y - 1
		statics.append({"s": "elevator", "x": ex, "y": ey, "w": 2, "h": 1, "solid": true})
		zones.append({"x": ex, "y": ey, "w": 2, "h": 1, "kind": "elevator"})
		for i: int in 2:
			taken[Vector2i(ex + i, ey)] = true
			taken[Vector2i(ex + i, ey + 1)] = true
	objects.append({"t": "ladder_up", "x": entrance.x, "y": entrance.y, "hp": 1})
	var revealed: bool = int(GameState.mine.get("deepest", 0)) > floor_n
	var sealed: bool = floor_n == 40 and not GameState.flag("bell_stone")
	if floor_n < floor_count() and not sealed:
		if revealed:
			objects.append({"t": "ladder_down", "x": exit_cell.x, "y": exit_cell.y, "hp": 1})
		else:
			objects.append({"t": "mine_rock", "x": exit_cell.x, "y": exit_cell.y, "hp": 2, "hidden": "ladder"})
	var cells: Array[Vector2i] = []
	for c: Vector2i in in_region:
		cells.append(c)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y * 1000 + a.x < b.y * 1000 + b.x)
	var nodes_cfg: Dictionary = cfg["nodes"]
	for c: Vector2i in cells:
		if taken.has(c) or water.has(c):
			continue
		var r: float = rng.randf()
		if r < float(cfg["node_density"]):
			var nt: String = _weighted(nodes_cfg, rng)
			objects.append({"t": nt, "x": c.x, "y": c.y, "hp": int(WorldObjects.defs()[nt]["hp"])})
			taken[c] = true
		elif r < float(cfg["node_density"]) + float(cfg["rocks"]) * 0.5:
			objects.append({"t": "mine_rock", "x": c.x, "y": c.y, "hp": 2})
			taken[c] = true
		elif r < float(cfg["node_density"]) + float(cfg["rocks"]) * 0.5 + 0.006:
			objects.append({"t": "crystal", "x": c.x, "y": c.y, "hp": 1, "c": ["ice", "violet", "amber"][biome - 1]})
			taken[c] = true
	if is_treasure_floor(floor_n) and not GameState.mine.get("chests", {}).has(str(floor_n)):
		var far: Vector2i = exit_cell
		for i: int in 30:
			var cand: Vector2i = cells[rng.randi_range(0, cells.size() - 1)]
			if not taken.has(cand) and cand.distance_to(Vector2(entrance)) > 10.0:
				far = cand
				break
		objects.append({"t": "treasure", "x": far.x, "y": far.y, "hp": 1, "floor": floor_n})
		taken[far] = true
	# monstres
	var monsters: Array = []
	var count_rng: Array = cfg["monster_count"]
	var n_monsters: int = rng.randi_range(int(count_rng[0]), int(count_rng[1])) + floor_n / 12
	for i: int in n_monsters:
		for tries: int in 25:
			var c2: Vector2i = cells[rng.randi_range(0, cells.size() - 1)]
			if taken.has(c2) or c2.distance_to(Vector2(entrance)) < 8.0:
				continue
			var kind: String = _weighted(cfg["monsters"], rng)
			var mdef: Dictionary = Database.table("monsters")[kind]
			var pack: Array = mdef.get("pack", [1, 1])
			for k: int in rng.randi_range(int(pack[0]), int(pack[1])):
				monsters.append({"k": kind, "x": c2.x + (k % 2), "y": c2.y + (k / 2)})
			break
	var d: Dictionary = {
		"id": map_id(floor_n), "w": W, "h": H, "rows": rows, "statics": statics, "objects": objects, "warps": [],
		"spots": {"entrance": [start.x, start.y], "exit": [exit_spot.x, exit_spot.y]}, "interact": zones,
		"outdoor": false, "interior": "mine", "dark": true, "gem_biome": str(biome), "music": "mine", "floor": floor_n,
		"name": "MAP_MINE", "monsters": monsters, "fish_place": "mine%d" % biome if not water_cells.is_empty() else "",
		"farmable": false, "elevator": elevator, "exit_cell": [exit_cell.x, exit_cell.y],
	}
	return d


static func _weighted(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total: int = 0
	var keys: Array = weights.keys()
	keys.sort()
	for k: String in keys:
		total += int(weights[k])
	var r: int = rng.randi_range(1, total)
	for k: String in keys:
		r -= int(weights[k])
		if r <= 0:
			return k
	return str(keys[0])


static func _caves(rng: RandomNumberGenerator, W: int, H: int) -> Array:
	var wall: Array = []
	for y: int in H:
		var row: Array = []
		for x: int in W:
			row.append(x == 0 or y == 0 or x == W - 1 or y == H - 1 or rng.randf() < 0.43)
		wall.append(row)
	for it: int in 4:
		var nxt: Array = []
		for y: int in H:
			var row2: Array = []
			for x: int in W:
				var n: int = 0
				for dy: int in range(-1, 2):
					for dx: int in range(-1, 2):
						var xx: int = x + dx
						var yy: int = y + dy
						if xx < 0 or yy < 0 or xx >= W or yy >= H or wall[yy][xx]:
							n += 1
				row2.append(x == 0 or y == 0 or x == W - 1 or y == H - 1 or n >= 5)
			nxt.append(row2)
		wall = nxt
	return wall


static func _fallback(W: int, H: int) -> Array:
	var wall: Array = []
	for y: int in H:
		var row: Array = []
		for x: int in W:
			row.append(not (x > 1 and x < W - 2 and y > 2 and y < H - 3))
		wall.append(row)
	return wall


static func _largest_region(wall: Array, W: int, H: int) -> Array[Vector2i]:
	var seen: Dictionary = {}
	var best: Array[Vector2i] = []
	for y: int in H:
		for x: int in W:
			var c: Vector2i = Vector2i(x, y)
			if wall[y][x] or seen.has(c):
				continue
			var comp: Array[Vector2i] = []
			var stack: Array[Vector2i] = [c]
			seen[c] = true
			while not stack.is_empty():
				var cur: Vector2i = stack.pop_back()
				comp.append(cur)
				for d: Vector2i in DIRS4:
					var n: Vector2i = cur + d
					if n.x >= 0 and n.y >= 0 and n.x < W and n.y < H and not wall[n.y][n.x] and not seen.has(n):
						seen[n] = true
						stack.append(n)
			if comp.size() > best.size():
				best = comp
	return best


static func _carve(wall: Array, in_region: Dictionary, rect: Rect2i, W: int, H: int) -> void:
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			if x > 0 and y > 0 and x < W - 1 and y < H - 1:
				wall[y][x] = false
	# relie l'alcôve au reste de la caverne : couloir vers le centre
	var cx: int = W / 2
	var cy: int = H / 2
	var x: int = rect.end.x
	var y: int = rect.position.y + rect.size.y / 2
	while x < cx:
		if x > 0 and x < W - 1:
			wall[y][x] = false
		x += 1
	while y != cy:
		wall[y][cx] = false
		y += 1 if cy > y else -1


static func _neighbor_free(c: Vector2i, in_region: Dictionary, fallback: Vector2i) -> Vector2i:
	for d: Vector2i in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
		if in_region.has(c + d):
			return c + d
	return fallback


static func _farthest(from: Vector2i, in_region: Dictionary) -> Vector2i:
	var dist: Dictionary = {from: 0}
	var queue: Array[Vector2i] = [from]
	var last: Vector2i = from
	var i: int = 0
	while i < queue.size():
		var cur: Vector2i = queue[i]
		i += 1
		last = cur
		for d: Vector2i in DIRS4:
			var n: Vector2i = cur + d
			if in_region.has(n) and not dist.has(n):
				dist[n] = int(dist[cur]) + 1
				queue.append(n)
	return last


## Fait apparaître l'échelle vers l'étage suivant (si elle ne l'est pas déjà). Renvoie vrai si elle vient d'apparaître.
static func reveal_ladder(rt: MapRuntime) -> bool:
	var f: int = int(rt.data.get("floor", 0))
	if f <= 0 or f >= floor_count():
		return false
	var ec: Array = rt.data.get("exit_cell", [0, 0])
	var c: Vector2i = Vector2i(int(ec[0]), int(ec[1]))
	for k: String in rt.objects():
		if str(rt.objects()[k].get("t", "")) == "ladder_down":
			return false
	if rt.origin_at(c) != null:
		rt.remove_object(rt.origin_at(c))
	rt.add_object(c, {"t": "ladder_down", "hp": 1})
	AudioManager.sfx("ladder")
	EventBus.toast.emit(Loc.t("MINE_LADDER_FOUND"), "")
	return true
