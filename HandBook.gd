extends Control
## handbook.gd: attach to the Handbook root.
## Scene layout (Root: Full Rect, Process > Mode: Always):
##   Handbook (Control)
##   ├─ Dim (ColorRect)               Full Rect, black ~50% alpha, Mouse Filter: Stop
##   └─ CenterContainer               Full Rect
##      └─ Window (PanelContainer)    Custom Minimum Size 560 × 300
##         └─ VBoxContainer
##            ├─ Header (HBoxContainer)
##            │  ├─ Title (Label)     "HANDBOOK", Horizontal: Fill + Expand
##            │  └─ Close (Button)    "BACK"  ← unique name %Close, Autowrap Off
##            └─ Tabs (TabContainer)  ← unique name %Tabs, Vertical: Fill + Expand
## The pages are created by this script, so leave Tabs empty.

const H := "[color=#7fd3ff]%s[/color]"          # heading color
const GOOD := "[color=#6fe36f]%s[/color]"
const WARN := "[color=#ffd84a]%s[/color]"
const BAD := "[color=#ff6b6b]%s[/color]"

func _ready():
	hide()
	%Close.pressed.connect(close)
	_add_page("Goal", _goal())
	_add_page("How to Play", _how_to_play())
	_add_page("Crew", _crew())
	_add_page("Systems", _systems())
	_add_page("Events", _events())
	_add_page("Real Science", _science())

func open():
	%Tabs.current_tab = 0
	show()
	get_tree().paused = true

func close():
	hide()
	get_tree().paused = false

func _unhandled_input(event):
	if visible and event.is_action_pressed("ui_cancel"):     # Esc closes the handbook
		close()
		get_viewport().set_input_as_handled()

func _add_page(title: String, text: String):
	var page := RichTextLabel.new()
	page.name = title
	page.bbcode_enabled = true
	page.scroll_active = true
	page.fit_content = false
	page.autowrap_mode = TextServer.AUTOWRAP_WORD
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.text = text
	%Tabs.add_child(page)


# ---------------- Pages ----------------

func _goal() -> String:
	return "\n".join([
		H % "YOU ARE THE BASE COMMANDER",
		"Your crew of 4 lives in a base on Shackleton Connecting Ridge, near the Moon's south pole. NASA chose this ridge for its Moon Base: it gets almost constant sunlight, and the dark craters nearby hold water ice.",
		"",
		H % "YOUR MISSION",
		"Keep everyone alive for %d days. There is never enough power, air, water or crew time for everything, so you have to choose." % GameState.mission_length,
		"",
		H % "OBJECTIVES",
		"1. Survive all %d days." % GameState.mission_length,
		"2. Keep every crew member's radiation dose under 50 mSv.",
		"3. Mine %d L of water ice." % GameState.ice_goal,
		"",
		WARN % ("Tip: SHADOW on Day %s. The Sun is blocked and the solar panels make nothing. Plan ahead!" % GameState.shadow_text()),
	])

func _how_to_play() -> String:
	return "\n".join([
		H % "EACH DAY",
		"1. Give every crew member a task (right side).",
		"2. Switch systems on or off in UTILITY > EXPAND.",
		"3. Press END DAY. The day plays out and the MISSION LOG tells you what happened.",
		"",
		H % "THE SCREEN",
		"TOP BANNER: day, time, and last night's events. Green = good, yellow = careful, red = danger.",
		"CURRENT POWER: G = power generated, C = power consumed. If C is bigger than G, your battery drains.",
		"UTILITY: oxygen (O2), carbon dioxide (CO2) and water (H2O). For CO2, LOWER is better.",
		"COMMS: order supplies from Earth once Comms is built.",
		"CREW: tasks and health. Hover over a task to see what it does.",
		"",
		H % "LOSING",
		BAD % "The mission fails if oxygen, water or food runs out, if CO2 reaches 100, or if anyone passes 250 mSv of radiation.",
		"The end screen explains what went wrong, so you can try a better plan.",
	])

func _crew() -> String:
	var lines := [
		H % "FATIGUE",
		"Every task except Rest adds 15 fatigue. At 80 a crew member is too exhausted to work. Rest removes 30.",
		"Outside tasks give more radiation than staying in the habitat.",
		"",
		H % "TASKS",
	]
	for t in GameState.TASKS:
		var days := ""
		if t in GameState.TASK_DAYS:
			days = WARN % (" (%d days, locked in)" % GameState.TASK_DAYS[t])
		lines.append("[color=#ffffff]%s[/color]%s: %s" % [t.to_upper(), days, GameState.TASK_INFO[t]])
	lines.append("")
	lines.append(WARN % "Multi-day jobs lose a day of progress if the crew must shelter from a storm or is exhausted.")
	return "\n".join(lines)

func _systems() -> String:
	return "\n".join([
		H % "POWER",
		"4 solar arrays make 10 kW each (40 kW). The habitat alone needs 20 kW, and each system adds more.",
		"Extra power charges the battery (1000 kWh). On the shadow day, the battery must carry the whole base.",
		"Dust on the panels lowers their power. Assign Clean.",
		GOOD % "Build the REACTOR for +40 kW, day and night.",
		"",
		H % "LIFE SUPPORT",
		"OXYGEN GENERATOR: splits water into oxygen. The crew breathes 3.4 kg of O2 a day.",
		"CO2 SCRUBBER: removes the carbon dioxide the crew breathes out. Never switch it off for long!",
		"WATER RECYCLER: saves about 90% of used water.",
		"GREENHOUSE: grows food. A Farmer doubles the harvest.",
		"ICE MINING: needs 15 kW and a crew member on Mine.",
		"",
		H % "RADIATION",
		"The RADIATION ALARM warns the crew to shelter when a solar storm hits. Without it, a storm can give a huge dose.",
		"",
		H % "SUPPLIES",
		"Once Comms is online, order Food, Water, Parts or Medical. A lander arrives in 2 days, then you must wait 5 days to order again.",
		"Spare PARTS are needed for every repair. You start with only 2!",
	])

func _events() -> String:
	return "\n".join([
		"Events get more likely as the mission goes on. Near the end, two can happen on the same day.",
		"",
		BAD % "SOLAR STORM: a burst of radiation from the Sun. With the alarm on, the crew shelters and loses the day's work. With it off, everyone gets a big dose.",
		BAD % "METEORITE HIT: a tiny rock punches a hole in the habitat. Air leaks out (-2 kg O2 every day) until someone Repairs it.",
		WARN % "MOONQUAKE: breaks a system and destroys a spare part.",
		WARN % "BREAKDOWN: a random system stops working. Assign Repair.",
		WARN % "DUST STORM: lunar dust coats the solar panels (-30% power). Assign Clean.",
		WARN % "CROP BLIGHT: 10 kg of food is lost and the Greenhouse needs Repair.",
		WARN % "WATER SPOILED: 30 L of water is contaminated.",
		WARN % "CREW SICK: one crew member gets +40 fatigue. Assign a Medic or let them Rest.",
		WARN % "DEEP COLD: the batteries lose 200 kWh.",
		WARN % "COMMS BLACKOUT: no supply orders for 2 days.",
		WARN % "LANDER DELAYED: your supply lander arrives 2 days later.",
		GOOD % "ICE FOUND: +30 L of water. Lucky!",
	])

func _science() -> String:
	return "\n".join([
		H % "THIS GAME USES REAL NASA NUMBERS",
		"Oxygen: each astronaut breathes about 0.84 kg of O2 a day (NASA life-support baseline, BVAD).",
		"Power: NASA's early base camp needs under 100 kW. A habitat uses about 20 kW, and one vertical solar array makes about 10 kW.",
		"Reactor: NASA plans a fission reactor on the Moon so the base has power through dark periods.",
		"Water: the ISS recycles about 98% of its water. This game uses 90% to keep it simple.",
		"Radiation: China's Chang'E 4 lander measured about 1.4 mSv a day on the lunar surface. NASA limits a crew's dose from one solar storm to 250 mSv.",
		"Storm shelters: NASA's Orion spacecraft has radiation sensors that warn the crew to shelter, just like your alarm.",
		"Moonquakes: seismometers left by the Apollo astronauts recorded real moonquakes.",
		"Dust: Apollo crews found lunar dust clogged equipment and wore through seals.",
		"",
		H % "WHERE THE BASE IS",
		"NASA's Moon Base plan picks Shackleton Connecting Ridge at the lunar south pole, near water ice in permanently shadowed craters.",
		"",
		"[color=#9a9a9a]Some numbers are simplified for gameplay. This is a student project and is not made or endorsed by NASA.[/color]",
	])
