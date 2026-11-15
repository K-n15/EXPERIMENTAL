extends Control
## pause_menu.gd: attach to the PauseMenu root.
## Set the root's Process > Mode to "Always" so its buttons still work while the game is paused.
## Mark the buttons as unique names: %Resume  %Save  %Quit
## Optional extra buttons (only used if you add them): %Load  %Restart  %MainMenu

const MENU_SCENE := "res://MainMenu.tscn"

@onready var load_btn: Button = get_node_or_null("%Load")
@onready var restart_btn: Button = get_node_or_null("%Restart")
@onready var menu_btn: Button = get_node_or_null("%MainMenu")

func _ready():
	hide()
	%Resume.pressed.connect(close)
	%Save.pressed.connect(_save)
	%Quit.pressed.connect(func(): get_tree().quit())
	%Quit.visible = not OS.has_feature("web")      # browsers can't close the game
	if load_btn:
		load_btn.pressed.connect(_load)
	if restart_btn:
		restart_btn.pressed.connect(_restart)
	if menu_btn:
		menu_btn.pressed.connect(_to_main_menu)

func open():
	%Save.text = "Save"
	if load_btn:
		load_btn.disabled = not GameState.has_save()
	show()
	get_tree().paused = true

func close():
	hide()
	get_tree().paused = false

func _unhandled_input(event):
	if visible and event.is_action_pressed("ui_cancel"):   # Esc closes the menu
		close()
		get_viewport().set_input_as_handled()

func _save():
	GameState.save_game()
	%Save.text = "Saved!"
	if load_btn:
		load_btn.disabled = false

func _load():
	get_tree().paused = false
	if GameState.load_game():
		get_tree().reload_current_scene()      # rebuild every panel from the loaded state

func _restart():
	get_tree().paused = false
	GameState.reset()                          # autoloads survive a reload, so reset first
	get_tree().reload_current_scene()

func _to_main_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)
