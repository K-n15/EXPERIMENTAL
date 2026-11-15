extends Control

var pages := {
	"Power": preload("res://PowerDetail.tscn"),
	"Life Support": preload("res://UtilityDetail.tscn"),
}
var current: Node

func _ready():
	hide()
	$Window/MarginContainer/VBoxContainer/Header/Close.pressed.connect(close)

func open(page_name: String):
	if current:
		current.queue_free()
	current = pages[page_name].instantiate()
	$Window/MarginContainer/VBoxContainer/Content.add_child(current)
	$Window/MarginContainer/VBoxContainer/Header/Title.text = page_name
	show()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.15)

func close():
	hide()

func _unhandled_input(event):
	if visible and event.is_action_pressed("ui_cancel"):  # Esc key
		close()
		get_viewport().set_input_as_handled()
