extends PanelContainer

signal open_requested(screen_name)
@export var screen_name := "Life Support"

func _ready():
	$VBoxContainer/Header/Expand.pressed.connect(func(): open_requested.emit(screen_name))
	GameState.changed.connect(refresh)
	refresh()

func refresh():
	$VBoxContainer/GridContainer/o2Level.value  = GameState.oxygen / GameState.oxygen_max * 100
	$VBoxContainer/GridContainer/co2Level.value = GameState.co2
	$VBoxContainer/GridContainer/h2oLevel.value = GameState.water / GameState.water_max * 100
