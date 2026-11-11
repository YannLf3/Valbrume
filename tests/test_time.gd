extends TestCase


func before_each() -> void:
	GameState.reset()
	GameState.active = true


func test_calendar() -> void:
	eq(TimeManager.season_of(0), 0, "printemps au jour 0")
	eq(TimeManager.season_of(27), 0)
	eq(TimeManager.season_of(28), 1, "été au jour 28")
	eq(TimeManager.season_of(111), 3, "hiver")
	eq(TimeManager.season_of(112), 0, "retour au printemps")
	eq(TimeManager.day_of_season(0), 1)
	eq(TimeManager.day_of_season(55), 28)
	eq(TimeManager.year_of(111), 1)
	eq(TimeManager.year_of(112), 2)
	eq(TimeManager.weekday_of(7), 0)


func test_format() -> void:
	eq(TimeManager.format_time(360), "6:00")
	eq(TimeManager.format_time(1505), "1:05", "après minuit")


func test_advance_and_faint() -> void:
	TimeManager._ending = false
	GameState.minutes = TimeManager.DAY_END - 5
	var day: int = GameState.day
	TimeManager.advance(3)
	eq(GameState.minutes, TimeManager.DAY_END - 2)
	eq(GameState.day, day)
	TimeManager.advance(10)
	eq(GameState.day, day + 1, "évanouissement à 2h → jour suivant")
	eq(GameState.minutes, TimeManager.DAY_START)
	TimeManager._ending = false
