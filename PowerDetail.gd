extends HBoxContainer

func _ready():
	GameState.changed.connect(refresh)
	refresh()

func refresh():
	%Generated.value = GameState.power_generated
	%Consumed.value = GameState.power_used
	%GeneratedAmt.text = "%d kW" % GameState.power_generated
	%ConsumedAmt.text = "%d kW" % GameState.power_used

	$Sources/SolarRow.set_state("Solar Panels", GameState.solar_output > 0,
		"Online · %d kW" % GameState.solar_output, GameState.solar_condition)
	$Sources/ReactorRow.set_state("Reactor", GameState.reactor_built,
		"Online · 40 kW" if GameState.reactor_built else "Offline", "Need setup")
	$Sources/StorageRow.set_state("Storage", GameState.battery > 0,
		"%d / %d kWh" % [GameState.battery, GameState.battery_max],
		"Charging" if GameState.power_generated >= GameState.power_used else "Supplying")
