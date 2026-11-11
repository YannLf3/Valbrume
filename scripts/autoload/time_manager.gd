extends Node
## Horloge et calendrier. Le temps est stocké dans GameState (day, minutes).

const DAY_START: int = 360          # 6h00
const DAY_END: int = 1560           # 2h00 du matin (26h)
const NIGHT_START: int = 1200       # 20h00
const DAYS_PER_SEASON: int = 28
const SEASONS: Array[String] = ["spring", "summer", "autumn", "winter"]
const DAYS_PER_YEAR: int = 112
const WEEKDAYS: int = 7

var running: bool = false
var _locks: int = 0
var _accum: float = 0.0
var _ending: bool = false


func _process(delta: float) -> void:
	if not running or _locks > 0 or not GameState.active:
		return
	GameState.playtime += delta
	_accum += delta
	var spm: float = maxf(Settings.seconds_per_minute, 0.05)
	while _accum >= spm and running:
		_accum -= spm
		advance(1)


## Les menus et dialogues posent un verrou : le temps s'arrête tant qu'il en reste.
func lock() -> void:
	_locks += 1


func unlock() -> void:
	_locks = maxi(0, _locks - 1)


func clear_locks() -> void:
	_locks = 0


func is_paused() -> bool:
	return _locks > 0 or not running


func advance(minutes: int) -> void:
	for i: int in minutes:
		if _ending:
			return
		GameState.minutes += 1
		EventBus.minute_passed.emit(GameState.minutes)
		if GameState.minutes % 60 == 0:
			EventBus.hour_passed.emit(GameState.minutes / 60)
		if GameState.minutes == NIGHT_START:
			EventBus.night_started.emit()
		if GameState.minutes >= DAY_END:
			EventBus.player_fainted.emit("late")
			end_day(true)
			return


## Termine la journée : calcule la nuit, puis attend `begin_day()` (après le bilan).
func end_day(passed_out: bool) -> void:
	if _ending:
		return
	_ending = true
	running = false
	var summary: Dictionary = DayCycle.run_night(passed_out)
	EventBus.day_ended.emit(summary)


func begin_day() -> void:
	_ending = false
	_accum = 0.0
	running = true
	EventBus.day_started.emit(GameState.day)


# --- calendrier -----------------------------------------------------------------

static func season_of(day: int) -> int:
	return (day / DAYS_PER_SEASON) % SEASONS.size()


static func day_of_season(day: int) -> int:
	return day % DAYS_PER_SEASON + 1


static func year_of(day: int) -> int:
	return day / DAYS_PER_YEAR + 1


static func weekday_of(day: int) -> int:
	return day % WEEKDAYS


func season() -> int:
	return season_of(GameState.day)


func season_id() -> String:
	return SEASONS[season()]


func day_in_season() -> int:
	return day_of_season(GameState.day)


func year() -> int:
	return year_of(GameState.day)


func weekday() -> int:
	return weekday_of(GameState.day)


func hour() -> int:
	return GameState.minutes / 60


func is_night() -> bool:
	return GameState.minutes >= NIGHT_START


static func format_time(minutes: int) -> String:
	return "%d:%02d" % [(minutes / 60) % 24, minutes % 60]


func date_text() -> String:
	return "%s %d" % [tr("WEEKDAY_%d" % weekday()), day_in_season()]


func season_text() -> String:
	return tr("SEASON_" + season_id().to_upper())
