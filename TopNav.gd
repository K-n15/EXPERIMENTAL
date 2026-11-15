extends Control
## top_nav.gd: attach to the TopNav root.
## In the TopNav scene, mark these as unique names (right-click → Access as Unique Name):
##   %DayNum  - the label showing the day number
##   %Clock   - the label showing the time
##   %Alert   - the label that now shows events (or status on quiet days)

const STEP_MINUTES := 5          # clock jumps 5 minutes at a time
const SECONDS_PER_STEP := 1.0    # one jump per real second
const SECONDS_PER_ITEM := 2.0    # how long each event shows when several happened
const COLORS := [Color.GREEN, Color.YELLOW, Color.RED]

var clock_timer := 0.0
var cycle_timer := 0.0
var items: Array = []
var shown := 0

func _ready():
	GameState.changed.connect(refresh)
	refresh()

func _process(delta):
	# Cycle through several events
	if items.size() > 1:
		cycle_timer += delta
		if cycle_timer >= SECONDS_PER_ITEM:
			cycle_timer = 0.0
			shown = (shown + 1) % items.size()
			_show_item()
	# Clock
	if GameState.mission_over:
		return
		clock_timer += delta
	if clock_timer >= SECONDS_PER_STEP:
		clock_timer -= SECONDS_PER_STEP
		GameState.advance_clock(STEP_MINUTES)
		%Clock.text = GameState.clock_text()
		if GameState.minutes >= GameState.DAY_END:
			GameState.add_log("[color=gray]Midnight: Day ended automatically.[/color]")
			GameState.simulate_day()

func refresh():
	%DayNum.text = "%02d" % GameState.day
	%Clock.text = GameState.clock_text()
	items = GameState.banner_items()
	shown = 0
	cycle_timer = 0.0
	_show_item()

func _show_item():
	var item: Dictionary = items[shown]
	var count := "" if items.size() < 2 else " %d/%d" % [shown + 1, items.size()]
	%Alert.text = item.text + count
	%Alert.modulate = COLORS[item.level]
	# Quick flash so a new red event grabs attention
	if item.level == 2:
		var t := create_tween()
		t.tween_property(%Alert, "modulate:a", 0.3, 0.15)
		t.tween_property(%Alert, "modulate:a", 1.0, 0.15)
