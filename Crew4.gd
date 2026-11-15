extends Control
## crew_row.gd: attach to the root of EACH crew row (the node holding portrait, name, task, health).
## Set "Index" in the Inspector: 0, 1, 2, 3 (top to bottom).
## It finds nodes by the end of their name, so C1Name / C1AssignedTask / C1HealthStat all work:
##   *Name         - Label with the crew member's name
##   *AssignedTask - OptionButton (the dropdown)
##   *HealthStat   - Label showing Healthy / Tired / ...

@export var index := 0

@onready var name_label: Label = find_child("*Name", true, false)
@onready var task_box: OptionButton = find_child("*AssignedTask", true, false)
@onready var health_label: Label = find_child("*HealthStat", true, false)

func _ready():
	index = ["CrewOne", "CrewTwo", "CrewThree", "CrewFour"].find(name)
	task_box.clear()
	for i in GameState.TASKS.size():
		var t: String = GameState.TASKS[i]
		task_box.add_item(t)
		task_box.set_item_tooltip(i, GameState.TASK_INFO[t])
	task_box.item_selected.connect(_on_task_selected)
	GameState.changed.connect(refresh)
	refresh()

func _on_task_selected(i: int):
	GameState.crew[index].task = GameState.TASKS[i]

func refresh():
	var c: Dictionary = GameState.crew[index]
	name_label.text = c.name
	task_box.select(GameState.TASKS.find(c.task))
	var busy: bool = c.days_left > 0
	task_box.disabled = GameState.mission_over or busy      # locked into a multi-day job
	var h := GameState.health_text(c)
	health_label.text = h + (" (%dd)" % c.days_left if busy else "")
	health_label.modulate = Color.GREEN if h == "Healthy" else (Color.YELLOW if h == "Tired" else Color.RED)
	health_label.tooltip_text = "Fatigue %d  ·  Radiation %.1f mSv" % [c.fatigue, c.dose]
