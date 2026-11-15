extends Control
## main_menu.gd: attach to the MainMenu root.
## Buttons (mark as unique names): %FullMission  %Training  %Continue  %HowToPlay  %Quit
## Optional: an instance of your Handbook scene as a child named "Handbook" (for How to Play).
## Change GAME_SCENE if your game scene is saved somewhere else.

const GAME_SCENE := "res://MainTerminal.tscn"

@onready var handbook = get_node_or_null("Handbook")

func _ready():
	get_tree().paused = false
	%FullMission.pressed.connect(func(): _start(30))
	%Training.pressed.connect(func(): _start(7))
	%Continue.pressed.connect(_continue)
	%Quit.pressed.connect(func(): get_tree().quit())
	%Continue.disabled = not GameState.has_save()
	%Quit.visible = not OS.has_feature("web")      # browsers can't close the game
	if handbook:
		%HowToPlay.pressed.connect(handbook.open)
	else:
		%HowToPlay.visible = false

func _start(days: int):
	GameState.reset(days)
	get_tree().change_scene_to_file(GAME_SCENE)

func _continue():
	if GameState.load_game():
		get_tree().change_scene_to_file(GAME_SCENE)
