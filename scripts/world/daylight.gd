class_name DayLight
extends CanvasModulate
## Éclairage selon l'heure et la météo ; neutre à l'intérieur.

const KEYS: Array = [
	[360, Color(0.92, 0.88, 0.98)], [480, Color(1, 1, 1)], [1020, Color(1, 1, 1)],
	[1140, Color(1.0, 0.82, 0.68)], [1260, Color(0.55, 0.55, 0.8)], [1440, Color(0.42, 0.46, 0.72)],
	[1560, Color(0.36, 0.4, 0.66)],
]
const WEATHER_DIM: Dictionary = {"rain": 0.86, "storm": 0.72, "snow": 0.94, "wind": 0.97, "sun": 1.0}

var indoors: bool = false


func _ready() -> void:
	EventBus.minute_passed.connect(func(_m: int) -> void: update_color())
	EventBus.weather_changed.connect(func(_w: String) -> void: update_color())
	update_color()


func update_color() -> void:
	if indoors:
		color = Color.WHITE
		return
	var m: int = clampi(GameState.minutes, int(KEYS[0][0]), int(KEYS[KEYS.size() - 1][0]))
	var col: Color = KEYS[KEYS.size() - 1][1]
	for i: int in KEYS.size() - 1:
		var a: Array = KEYS[i]
		var b: Array = KEYS[i + 1]
		if m >= int(a[0]) and m <= int(b[0]):
			col = (a[1] as Color).lerp(b[1], float(m - int(a[0])) / float(int(b[0]) - int(a[0])))
			break
	var dim: float = float(WEATHER_DIM.get(GameState.weather, 1.0))
	color = Color(col.r * dim, col.g * dim, col.b * dim)
