extends Control

const MENU_SCENE := "res://MainMenu.tscn"
@onready var log_panel = $LogPanel
@onready var log_text = $LogPanel/MarginContainer/Log

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$PowerScreen.open_requested.connect($DetailView.open)
	$UtilityPanel.open_requested.connect($DetailView.open)
	$TopNav.find_child("Menu", true, false).pressed.connect($PauseMenu.open)
	$TopNav.find_child("HandBook", true, false).pressed.connect($Handbook.open)
	$MissionManual/VBoxContainer/HBoxContainer/EndDay.pressed.connect(GameState.simulate_day)
	$EndDialog.add_button("Main Menu", false, "menu")
	$EndDialog.confirmed.connect(_restart)
	$EndDialog.canceled.connect(func(): get_tree().change_scene_to_file(MENU_SCENE))
	$EndDialog.custom_action.connect(_on_end_action)
	GameState.mission_ended.connect(_on_mission_ended)
	GameState.log_added.connect(func(line): log_text.append_text(line + "\n"))
	for line in GameState.log_lines:
		log_text.append_text(line + "\n")

func toggle_log():
	log_panel.visible = not log_panel.visible

func _on_mission_ended(won, reason):
	$EndDialog.title = "MISSION COMPLETE" if won else "MISSION FAILED"
	$EndDialog.dialog_text = reason
	$EndDialog.ok_button_text = "New Mission" if won else "Try Again"
	$EndDialog.dialog_autowrap = true
	$EndDialog.size = Vector2i(400, 160)
	$EndDialog.canceled.connect(func(): get_tree().change_scene_to_file(MENU_SCENE))
	$EndDialog.popup_centered()

func _restart():
	GameState.reset()
	get_tree().reload_current_scene()
 
func _on_end_action(action):
	if action == "menu":
		get_tree().change_scene_to_file(MENU_SCENE)
