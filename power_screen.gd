extends PanelContainer

signal open_requested(screen_name)
@export var screen_name := "Power"
@export var online := true

func _ready():
	%Expand.pressed.connect(func(): open_requested.emit(screen_name))
	GameState.changed.connect(refresh)
	set_online(online)
	refresh()

func set_online(value):
	online = value
	$OfflineOverlay.visible = not online

func refresh():
	%Generated.value = GameState.power_generated
	%Consumed.value = GameState.power_used
	%GeneratedAmt.text = "%d kW" % GameState.power_generated
	%ConsumedAmt.text = "%d kW" % GameState.power_used
