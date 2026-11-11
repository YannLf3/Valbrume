class_name FishingGame
extends RefCounted
## Mini-jeu de pêche « Ondes » : une bille tourne sur un anneau ; il faut ferrer quand la touche mord,
## puis frapper la touche quand la bille traverse l'arc ambré (au centre : coup parfait).
## Trois ratés et la ligne casse. Logique pure : l'écran ne fait que dessiner et transmettre la touche.

enum State { WAIT, BITE, FIGHT, WON, LOST }

var state: State = State.WAIT
var fish_id: String = ""
var difficulty: int = 1
var rod_level: int = 1
var rng: RandomNumberGenerator

var wait_left: float = 2.0
var bite_left: float = 0.0
var angle: float = 0.0
var speed: float = 3.0
var arc_center: float = 0.0
var arc_half: float = 0.5
var beats_total: int = 4
var progress: int = 0
var misses: int = 0
var perfects: int = 0
var treasure: bool = false
var last_event: String = ""
var _armed: bool = false
var _bite_window: float = 0.9


func _init(p_fish: String, p_rod: int, bait: bool, p_rng: RandomNumberGenerator) -> void:
	fish_id = p_fish
	rod_level = p_rod
	rng = p_rng
	difficulty = int(Fishing.table().get(fish_id, {}).get("difficulty", 1))
	var lo: float = Database.bal_f("fish_wait_min", 1.2)
	var hi: float = Database.bal_f("fish_wait_max", 5.0)
	wait_left = rng.randf_range(lo, hi) * (Database.bal_f("fish_bait_wait_mult", 0.55) if bait else 1.0)
	if fish_id == "":
		wait_left = hi * 2.0
	_bite_window = 1.0 - 0.06 * difficulty + 0.04 * rod_level
	beats_total = maxi(3, Database.bal_i("fish_beats_base", 4) + difficulty - 1)
	speed = 2.4 + 0.38 * difficulty
	arc_half = _half_width() 
	_new_arc()


func _half_width() -> float:
	var frac: float = Database.bal_f("fish_window_base", 0.21) + rod_level * Database.bal_f("fish_window_per_rod", 0.02) \
		+ Skills.perk("fish_window") - difficulty * Database.bal_f("fish_window_per_diff", 0.022) + 0.11
	return clampf(frac, 0.08, 0.4) * TAU / 2.0


func _new_arc() -> void:
	arc_center = wrapf(angle + rng.randf_range(PI * 0.5, PI * 1.5), -PI, PI)


func _off(a: float, b: float) -> float:
	return absf(wrapf(a - b, -PI, PI))


func in_arc() -> bool:
	return _off(angle, arc_center) <= arc_half


func update(delta: float) -> String:
	last_event = ""
	match state:
		State.WAIT:
			wait_left -= delta
			if wait_left <= 0.0:
				if fish_id == "":
					state = State.LOST
					last_event = "nothing"
				else:
					state = State.BITE
					bite_left = _bite_window
					last_event = "bite"
		State.BITE:
			bite_left -= delta
			if bite_left <= 0.0:
				state = State.LOST
				last_event = "escaped"
		State.FIGHT:
			angle = wrapf(angle + speed * delta, -PI, PI)
			var inside: bool = in_arc()
			if inside:
				_armed = true
			elif _armed:
				_armed = false
				_miss()
	return last_event


## Touche pressée : ferrage ou frappe. Renvoie l'événement : hook, hit, perfect, miss, win, lose, none.
func press() -> String:
	last_event = "none"
	match state:
		State.BITE:
			state = State.FIGHT
			angle = rng.randf_range(-PI, PI)
			_new_arc()
			last_event = "hook"
		State.FIGHT:
			if in_arc():
				var perfect: bool = _off(angle, arc_center) <= arc_half * Database.bal_f("fish_perfect_ratio", 0.38)
				progress += 1
				if perfect:
					perfects += 1
				speed *= 1.04
				_armed = false
				last_event = "perfect" if perfect else "hit"
				if progress >= beats_total:
					state = State.WON
					treasure = perfects == beats_total and rng.randf() < Database.bal_f("fish_treasure_chance", 0.08) + Skills.perk("treasure_chance")
					last_event = "win"
				else:
					_new_arc()
			else:
				_miss()
		State.WAIT:
			state = State.LOST
			last_event = "early"
	return last_event


func _miss() -> void:
	misses += 1
	last_event = "miss"
	if misses >= Database.bal_i("fish_misses_allowed", 3):
		state = State.LOST
		last_event = "lose"


## Qualité de la prise (0 normale, 1 argent, 2 or) d'après la précision.
func quality() -> int:
	var score: float = float(perfects) / float(maxi(1, beats_total))
	if score >= 0.75 and misses == 0:
		return 2
	if score >= 0.35:
		return 1
	return 0
