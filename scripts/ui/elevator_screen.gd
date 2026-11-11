class_name ElevatorScreen
extends ScreenBase
## Ascenseur de la mine : étages multiples de 5 déjà atteints, ou la surface. Résultat : numéro d'étage (0 = surface).


func _ready() -> void:
	var panel: PanelContainer = PanelContainer.new()
	center(panel)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.custom_minimum_size = Vector2(150, 0)
	panel.add_child(v)
	v.add_child(UIKit.label(Loc.t("MINE_ELEVATOR_TITLE"), UIKit.BARK_D, true))
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	v.add_child(grid)
	var first: Button = null
	var reached: int = int(GameState.mine.get("elevator", 0))
	var step: int = Database.bal_i("mine_elevator_step", 5)
	var f: int = step
	while f <= reached:
		var b: Button = UIKit.button(str(f), 44)
		b.pressed.connect(close.bind(f))
		grid.add_child(b)
		if first == null:
			first = b
		f += step
	var surf: Button = UIKit.button(Loc.t("MINE_SURFACE"), 140)
	surf.pressed.connect(close.bind(0))
	v.add_child(surf)
	(first if first != null else surf).grab_focus()
	AudioManager.sfx("elevator")
