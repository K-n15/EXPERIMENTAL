extends HBoxContainer

const ModuleRow = preload("res://ModuleRow.tscn")

func _ready():
	for m in GameState.modules:
		var row = ModuleRow.instantiate()
		$Modules/Lists.add_child(row)
		row.get_node("Top/Name").text = m.name
		row.get_node("Effects").text = m.text
		var sw = row.get_node("Top/Switch")
		sw.button_pressed = m.on
		sw.toggled.connect(func(on): m.on = on; sw.toggled.connect(func(on): m.on = on; GameState.preview_power()))
	GameState.changed.connect(refresh)
	refresh()
	
func refresh():
	%O2Amt.value   = GameState.oxygen / GameState.oxygen_max * 100
	%CO2Amt.value  = GameState.co2
	%H2OAmt.value  = GameState.water / GameState.water_max * 100
	%FoodAmt.value = GameState.food / GameState.food_max * 100
	%MedicalAmt.value = GameState.medical
