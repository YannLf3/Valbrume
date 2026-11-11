class_name FestivalGames
extends RefCounted
## Logique pure des quatre jeux de fête (l'écran ne fait que dessiner) : mémoire, cadence, jury, cible.


class Memory:
	extends RefCounted
	const ROUNDS: int = 5
	const SYMBOLS: int = 4
	var rng: RandomNumberGenerator
	var round_n: int = 0
	var seq: Array[int] = []
	var input_idx: int = 0
	var finished: bool = false

	func _init(p_rng: RandomNumberGenerator) -> void:
		rng = p_rng
		_next()

	func _next() -> void:
		seq.clear()
		for i: int in 3 + round_n:
			seq.append(rng.randi_range(0, SYMBOLS - 1))
		input_idx = 0

	## Renvoie "ok", "round" (manche réussie), "done" (tout réussi) ou "wrong".
	func press(i: int) -> String:
		if finished:
			return "none"
		if seq[input_idx] != i:
			finished = true
			return "wrong"
		input_idx += 1
		if input_idx < seq.size():
			return "ok"
		round_n += 1
		if round_n >= ROUNDS:
			finished = true
			return "done"
		_next()
		return "round"

	func score() -> int:
		return round_n * 100 / ROUNDS


class Timing:
	extends RefCounted
	const BEATS: int = 6
	var t: float = 0.0
	var speed: float = 1.1
	var beats: int = 0
	var total: float = 0.0
	var finished: bool = false

	func position() -> float:
		return pingpong(t, 1.0)

	func update(delta: float) -> void:
		if not finished:
			t += delta * speed

	## Frappe : renvoie la précision de ce coup (0..1).
	func press() -> float:
		if finished:
			return 0.0
		var acc: float = 1.0 - absf(position() - 0.5) * 2.0
		total += acc
		beats += 1
		speed *= 1.12
		if beats >= BEATS:
			finished = true
		return acc

	func score() -> int:
		return int(round(total / float(BEATS) * 100.0))


class Target:
	extends RefCounted
	const THROWS: int = 5
	var t: float = 0.0
	var throws: int = 0
	var total: float = 0.0
	var finished: bool = false

	func crosshair() -> Vector2:
		return Vector2(cos(t * 1.9) * 0.95, sin(t * 2.6 + 0.8) * 0.8)

	func update(delta: float) -> void:
		if not finished:
			t += delta

	func press() -> float:
		if finished:
			return 0.0
		var acc: float = clampf(1.0 - crosshair().length() / 1.0, 0.0, 1.0)
		total += acc
		throws += 1
		if throws >= THROWS:
			finished = true
		return acc

	func score() -> int:
		return int(round(total / float(THROWS) * 100.0))


## Note du jury pour une récolte présentée (prix, qualité, un peu de hasard).
static func judge(item_id: String, quality: int, rng: RandomNumberGenerator) -> int:
	var price: int = int(Database.item(item_id).get("price", 0))
	var base: float = minf(70.0, price / 4.0) + quality * 12.0 + rng.randf_range(0.0, 14.0)
	return clampi(int(base), 0, 100)
