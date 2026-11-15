extends PanelContainer

@onready var cargo = $MarginContainer/VBoxContainer/Order/Cargo
@onready var request = $MarginContainer/VBoxContainer/Order/Request

func _ready():
	for kind in GameState.CARGO:
		cargo.add_item(kind)
	request.pressed.connect(func():
		GameState.request_supply(cargo.get_item_text(cargo.selected)))
	GameState.changed.connect(refresh)
	refresh()

func refresh():
	var offline := not GameState.comms_online
	$OfflineOverlay.visible = offline
	$MarginContainer.modulate.a = 0.25 if offline else 1.0
	cargo.disabled = offline
	request.disabled = offline or not GameState.can_order()
	$OfflineOverlay.visible = not GameState.comms_online
	$MarginContainer/VBoxContainer/Status.text = "LINK: OK"
	var supply := "READY"
	if GameState.supply_eta > 0:
		supply = "IN %d DAY%s" % [GameState.supply_eta, "" if GameState.supply_eta == 1 else "S"]
	elif GameState.supply_cooldown > 0:
		supply = "WAIT %d DAY%s" % [GameState.supply_cooldown, "" if GameState.supply_cooldown == 1 else "S"]
	$MarginContainer/VBoxContainer/Supply.text = "SUPPLY: " + supply
	request.disabled = not GameState.can_order()
