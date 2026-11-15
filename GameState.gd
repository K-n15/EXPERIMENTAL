extends Node
## GameState.gd: register as an Autoload named "GameState".
## Values marked (NASA) come from NASA sources; the rest are gameplay values you can tune.

signal changed
signal log_added(line)
signal mission_ended(won: bool, reason: String)

# ---------------- Constants ----------------
const CREW_SIZE := 4                 # NASA habitat reference crew
const O2_PER_CREW := 0.84            # kg per person per day (NASA BVAD)
const WATER_PER_CREW := 4.0          # L per person per day (gameplay, rounded)
const FOOD_PER_CREW := 2.4           # kg per person per day (NASA, ISS packaged food)
const SOLAR_ARRAY_KW := 10.0         # one vertical solar array (NASA VSAT)
const REACTOR_KW := 40.0             # fission surface power (NASA FSP)
const HABITAT_KW := 20.0             # habitat with crew aboard (NASA)
const HOURS := 24.0
const DOSE_HABITAT := 0.5            # mSv/day inside the shielded habitat (gameplay)
const DOSE_OUTSIDE := 1.4            # mSv/day on the surface (Chang'E 4 measurement)
const DOSE_LIMIT := 250.0            # mSv, NASA per-solar-event limit
const DOSE_EXPEDITION := 2.0         # mSv/day far from the habitat (gameplay)
const DAY_START := 6 * 60            # clock resets to 06:00 each morning
const DAY_END := 23 * 60 + 59        # clock stops at 23:59 until END DAY

const TASKS := ["Rest", "Repair", "Clean", "Mine", "Farm", "Research", "Medic",
	"Build Reactor", "Build Comms", "Expedition"]
const OUTSIDE_TASKS := ["Repair", "Clean", "Mine", "Build Reactor", "Build Comms", "Expedition"]
const TASK_DAYS := {"Build Reactor": 3, "Build Comms": 2, "Expedition": 2}   # multi-day jobs
const TASK_INFO := {
	"Rest":     "Recover 30 fatigue.",
	"Repair":   "Seal a hull leak first, otherwise fix one broken module. Uses 1 spare part. Outside: more radiation.",
	"Clean":    "Remove 40% of the dust on the solar panels. Outside: more radiation.",
	"Mine":     "+20 L water from ice. Needs Ice Mining switched on. Outside: more radiation.",
	"Farm":     "Doubles greenhouse food (1.5 to 3 kg). Needs the Greenhouse on.",
	"Research": "+1 research point.",
	"Medic":    "Treat the most tired crewmate: -25 fatigue. Uses 5 medical supplies.",
	"Build Reactor": "3 DAYS. Reactor gives +40 kW day and night. Crew member is locked in. Outside.",
	"Build Comms":   "2 DAYS. Brings Comms online so you can order supplies. Crew member is locked in. Outside.",
	"Expedition":    "2 DAYS. +60 L water and +2 research, no power needed. Highest radiation.",
}

## Short banner labels for each event: [text, level] (0 = good/green, 1 = caution/yellow, 2 = danger/red)
const EVENT_LABELS := {
	"storm": ["SOLAR STORM", 2], "meteorite": ["METEORITE HIT", 2], "moonquake": ["MOONQUAKE", 1],
	"breakdown": ["BREAKDOWN", 1], "dust": ["DUST STORM", 1], "blight": ["CROP BLIGHT", 1],
	"contamination": ["WATER SPOILED", 1], "illness": ["CREW SICK", 1], "cold": ["DEEP COLD", 1],
	"blackout": ["COMMS BLACKOUT", 1], "delay": ["LANDER DELAYED", 1], "ice_find": ["ICE FOUND", 0],
}

const CARGO := {
	"Food":    {"food": 40.0},
	"Water":   {"water": 60.0},
	"Parts":   {"parts": 2},
	"Medical": {"medical": 20.0},
}

# ---------------- Mission ----------------
var day: int
var minutes: int                     # clock, minutes since midnight
var mission_length: int
var chosen_length := 30              # remembered across restarts: 7 = training, 30 = full mission
var ice_goal: float                  # objective: litres of ice to mine
var mission_over: bool
var shadow_days: Array
var in_shadow: bool
var storm_today: bool
var sheltered: bool
var farm_bonus: bool
var hull_leak: bool                  # micrometeorite hole: loses O2 every day until repaired
var comms_blackout: int              # days until a comms blackout ends
var events_today: Array = []         # banner items from the last END DAY: {"text", "level"}

# ---------------- Power ----------------
var solar_arrays: int
var dust: int                        # % lost to dust on the panels
var reactor_built: bool
var battery: float                   # kWh
var battery_max: float
var power_generated: float           # kW
var power_used: float                # kW
var solar_output: float              # kW
var solar_condition: String
var brownout: bool

# ---------------- Life support ----------------
var oxygen: float                    # kg stored
var oxygen_max: float
var co2: float                       # 0-100, 100 = dangerous
var water: float                     # L stored
var water_max: float
var food: float                      # kg stored
var food_max: float
var parts: int
var medical: float
var research: int
var ice_mined: float

# ---------------- Systems, crew, comms ----------------
var modules: Array
var crew: Array
var comms_online: bool
var supply_eta: int                  # days until the lander arrives, -1 = none ordered
var supply_cooldown: int
var supply_order: String
var log_lines: Array[String] = []


func _ready():
	randomize()
	reset()


## Pass a length (7 or 30) to start that kind of mission; leave it out to repeat the last one.
func reset(length: int = 0):
	if length > 0:
		chosen_length = length
	day = 1
	minutes = DAY_START
	mission_length = chosen_length
	mission_over = false
	# Even Shackleton Ridge is in shadow ~6% of the time (NASA). A 2-day shadow needs the reactor.
	if mission_length <= 7:
		shadow_days = [4]
		ice_goal = 40.0
	else:
		shadow_days = [8, 18, 19, 27]
		ice_goal = 150.0
	in_shadow = false
	storm_today = false
	sheltered = false
	farm_bonus = false
	hull_leak = false
	comms_blackout = 0
	events_today.clear()

	solar_arrays = 4
	dust = 0
	reactor_built = false
	battery = 900.0
	battery_max = 1000.0
	solar_condition = "Functional"
	brownout = false

	# Starting life support. Crew of 4 breathes 3.36 kg of O2 a day.
	oxygen = 21.0                    # 70%: about 6 days of air if the generator stops
	oxygen_max = 30.0
	co2 = 10.0                       # normal cabin level; 100 = dangerous
	water = 200.0                    # 80%
	water_max = 250.0
	food = 70.0                      # 70%: about 7 days for 4 people
	food_max = 100.0
	parts = 2
	medical = 50.0
	research = 0
	ice_mined = 0.0

	modules = [
		{"id": "oxygen", "name": "Oxygen Generator", "on": true, "broken": false, "power": 5,
			"text": "[color=green]+O2[/color]  [color=red]-Water  -5 kW[/color]"},
		{"id": "scrubber", "name": "CO2 Scrubber", "on": true, "broken": false, "power": 3,
			"text": "[color=green]-CO2[/color]  [color=red]-3 kW[/color]"},
		{"id": "recycler", "name": "Water Recycler", "on": true, "broken": false, "power": 4,
			"text": "[color=green]Saves ~90% of water[/color]  [color=red]-4 kW[/color]"},
		{"id": "greenhouse", "name": "Greenhouse", "on": true, "broken": false, "power": 5,
			"text": "[color=green]+Food[/color]  [color=red]-5 kW[/color]"},
		{"id": "mining", "name": "Ice Mining", "on": false, "broken": false, "power": 15,
			"text": "[color=green]+Water (needs a Miner)[/color]  [color=red]-15 kW[/color]"},
		{"id": "alarm", "name": "Radiation Alarm", "on": true, "broken": false, "power": 1,
			"text": "[color=green]Storm warnings[/color]  [color=red]-1 kW[/color]"},
	]

	crew = [
		{"name": "Mira Chen", "task": "Farm", "fatigue": 0, "dose": 0.0, "days_left": 0, "outside": false, "far": false},
		{"name": "Tomas Reyes", "task": "Build Reactor", "fatigue": 0, "dose": 0.0, "days_left": 0, "outside": false, "far": false},
		{"name": "Ada Okafor", "task": "Research", "fatigue": 0, "dose": 0.0, "days_left": 0, "outside": false, "far": false},
		{"name": "Leo Novak", "task": "Rest", "fatigue": 0, "dose": 0.0, "days_left": 0, "outside": false, "far": false},
	]

	comms_online = false             # assign Build Comms to bring it online
	supply_eta = -1
	supply_cooldown = 0
	supply_order = ""
	log_lines.clear()
	add_log("[color=gray]========== DAY 1 ==========[/color]")
	add_log("Mission start: %d days. Shadow expected on Day %s, no solar power then." % [mission_length, shadow_text()])
	preview_power()


# ---------------- Helpers ----------------
func module(id: String) -> Dictionary:
	for m in modules:
		if m.id == id:
			return m
	return {}

func running(id: String) -> bool:
	var m := module(id)
	return m.on and not m.broken and not brownout

func max_dose() -> float:
	var highest := 0.0
	for c in crew:
		highest = max(highest, c.dose)
	return highest

func add_log(text: String):
	#var line := "[Day %d] %s" % [day, text]
	log_lines.append(text)
	log_added.emit(text)

func objectives() -> Array:
	return [
		{"text": "Survive %d days" % mission_length, "done": mission_over and day >= mission_length},
		{"text": "Keep every crew dose under 50 mSv", "done": max_dose() < 50.0},
		{"text": "Mine %d L of water ice (%d/%d)" % [ice_goal, ice_mined, ice_goal], "done": ice_mined >= ice_goal},
	]

func shadow_text() -> String:
	var parts_list := []
	for d in shadow_days:
		parts_list.append(str(d))
	return ", ".join(parts_list)

## Power numbers for the bars right now, without spending battery.
func preview_power():
	solar_output = 0.0 if day in shadow_days else solar_arrays * SOLAR_ARRAY_KW * (1.0 - dust / 100.0)
	power_generated = solar_output + (REACTOR_KW if reactor_built else 0.0)
	power_used = HABITAT_KW
	for m in modules:
		if m.on and not m.broken:
			power_used += m.power
	changed.emit()


# ---------------- Clock and alerts ----------------
func advance_clock(game_minutes: int):
	minutes = min(minutes + game_minutes, DAY_END)

func clock_text() -> String:
	return "%02d:%02d" % [floori(minutes / 60.0), minutes % 60]

## The most serious problem right now: level 0 = nominal, 1 = caution, 2 = warning.
func alert() -> Dictionary:
	if brownout or battery <= 0.0:
		return {"level": 2, "text": "NO POWER"}
	if hull_leak:
		return {"level": 2, "text": "HULL LEAK"}
	if oxygen < oxygen_max * 0.25:
		return {"level": 2, "text": "LOW O2"}
	if co2 >= 60.0:
		return {"level": 2, "text": "HIGH CO2"}
	if water < water_max * 0.15:
		return {"level": 2, "text": "LOW WATER"}
	if food < food_max * 0.15:
		return {"level": 2, "text": "LOW FOOD"}
	if day in shadow_days:
		return {"level": 1, "text": "SHADOW"}
	for m in modules:
		if m.broken:
			return {"level": 1, "text": "REPAIR"}
	if battery < battery_max * 0.3:
		return {"level": 1, "text": "LOW BATTERY"}
	if dust >= 30:
		return {"level": 1, "text": "DUSTY PANELS"}
	if oxygen < oxygen_max * 0.5:
		return {"level": 1, "text": "O2 FALLING"}
	return {"level": 0, "text": "NOMINAL"}

## What the top banner shows: last night's events, or the current status if nothing happened.
func banner_items() -> Array:
	if events_today.is_empty():
		return [alert()]
	return events_today


func health_text(c: Dictionary) -> String:
	if c.dose >= 100.0:
		return "Radiation sick"
	if c.fatigue >= 80:
		return "Exhausted"
	if c.fatigue >= 50:
		return "Tired"
	return "Healthy"


# ---------------- The day ----------------
func simulate_day():
	if mission_over:
		return
	events_today.clear()
	in_shadow = day in shadow_days
	_random_event()
	_crew_tasks()
	_power()
	_life_support()
	_radiation()
	_supply()
	_check_end()
	if not mission_over:
		day += 1
		minutes = DAY_START
		add_log("[color=gray]========== DAY %d ==========[/color]" % day)
		if day in shadow_days:
			add_log("[color=yellow]Shadow today: solar panels will produce nothing. Save battery![/color]")
	preview_power()


## Events get more likely each day: about 50% on Day 2, 75% on Day 5, 90%+ by Day 7.
## From Day 5, a second event can hit on the same day.
func _random_event():
	storm_today = false
	if comms_blackout > 0:
		comms_blackout -= 1
		if comms_blackout == 0:
			comms_online = true
			add_log("[color=green]Comms link restored.[/color]")
	if day == 1:
		return
	# Ramp up over the mission: ~45% early, ~85% near the end, a second event in the last third.
	var progress := float(day) / mission_length
	if randf() < 0.4 + 0.45 * progress:
		_apply_event(_pick_event())
		if progress >= 0.66 and randf() < 0.3:
			_apply_event(_pick_event())


func _pick_event() -> String:
	# [event id, weight]: higher weight = more common, 0 = never
	var pool := [
		["storm", 3], ["dust", 3], ["breakdown", 3], ["meteorite", 2], ["moonquake", 2],
		["blight", 2], ["contamination", 2], ["illness", 2], ["cold", 2], ["ice_find", 1],
	]
	if comms_online:
		pool.append(["blackout", 2])
	if supply_eta > 0:
		pool.append(["delay", 2])
	var total := 0
	for e in pool:
		total += e[1]
	var roll := randi() % total
	for e in pool:
		roll -= e[1]
		if roll < 0:
			return e[0]
	return "dust"


func _apply_event(id: String):
	events_today.append({"text": EVENT_LABELS[id][0], "level": EVENT_LABELS[id][1]})
	match id:
		"storm":
			storm_today = true
			if running("alarm"):
				add_log("[color=red]SOLAR STORM! The alarm warned the crew and they sheltered. Today's work is lost.[/color]")
			else:
				add_log("[color=red]SOLAR STORM hit with NO warning: the radiation alarm was off![/color]")
		"dust":
			dust = min(dust + 30, 90)
			add_log("[color=yellow]Dust storm: solar panels coated (-%d%% power). Assign Clean.[/color]" % dust)
		"breakdown":
			var m = modules.pick_random()
			m.broken = true
			add_log("[color=yellow]%s broke down. Assign Repair.[/color]" % m.name)
		"meteorite":
			hull_leak = true
			oxygen = max(oxygen - 4.0, 0.0)
			add_log("[color=red]MICROMETEORITE punctured the habitat! Air is leaking (-2 kg O2 every day). Assign Repair NOW.[/color]")
		"moonquake":
			var m = modules.pick_random()
			m.broken = true
			if parts > 0:
				parts -= 1
			add_log("[color=yellow]Moonquake! (Apollo seismometers recorded real ones.) %s broke and a spare part was lost.[/color]" % m.name)
		"blight":
			food = max(food - 10.0, 0.0)
			module("greenhouse").broken = true
			add_log("[color=yellow]Greenhouse blight: 10 kg of crops lost and the Greenhouse needs Repair.[/color]")
		"contamination":
			water = max(water - 30.0, 0.0)
			add_log("[color=yellow]Water tank contaminated: 30 L had to be thrown away.[/color]")
		"illness":
			var c = crew.pick_random()
			c.fatigue = min(c.fatigue + 40, 100)
			add_log("[color=yellow]%s is sick (+40 fatigue). Assign a Medic or let them Rest.[/color]" % c.name)
		"cold":
			battery = max(battery - 200.0, 0.0)
			add_log("[color=yellow]Extreme cold drained the batteries: -200 kWh.[/color]")
		"blackout":
			comms_online = false
			comms_blackout = 2
			add_log("[color=yellow]Comms blackout: the relay satellite is out of view for 2 days. No supply orders.[/color]")
		"delay":
			supply_eta += 2
			add_log("[color=yellow]The supply lander is delayed 2 days.[/color]")
		"ice_find":
			water = min(water + 30.0, water_max)
			add_log("[color=green]Lucky find: ice-rich soil next to the base! +30 L water.[/color]")


func _crew_tasks():
	farm_bonus = false
	sheltered = storm_today and running("alarm")
	for c in crew:
		c.outside = false
		c.far = false
		if sheltered:
			c.fatigue = max(c.fatigue - 10, 0)
			continue
		if c.task == "Rest":
			c.fatigue = max(c.fatigue - 30, 0)
			continue
		if c.fatigue >= 80:
			add_log("%s is too exhausted to work. Assign Rest." % c.name)
			c.fatigue = max(c.fatigue - 10, 0)
			continue
		c.fatigue = min(c.fatigue + 15, 100)
		c.outside = c.task in OUTSIDE_TASKS
		c.far = c.task == "Expedition"
		if c.task in TASK_DAYS:
			_work_long_task(c)
			continue
		match c.task:
			"Repair":
				var fixed := false
				if hull_leak and parts > 0:
					hull_leak = false
					parts -= 1
					fixed = true
					add_log("[color=green]%s sealed the hull leak.[/color]" % c.name)
				for m in modules:
					if fixed:
						break
					if m.broken and parts > 0:
						m.broken = false
						parts -= 1
						fixed = true
						add_log("%s repaired the %s." % [c.name, m.name])
						break
				if not fixed:
					add_log("%s found nothing to repair (or no spare parts)." % c.name)
			"Clean":
				if dust > 0:
					dust = max(dust - 40, 0)
					add_log("%s cleaned the solar panels." % c.name)
			"Mine":
				var miner := module("mining")
				if miner.on and not miner.broken:
					water = min(water + 20.0, water_max)
					ice_mined += 20.0
					add_log("%s mined 20 L of water ice." % c.name)
				else:
					add_log("%s couldn't mine: switch on Ice Mining first." % c.name)
			"Farm":
				if running("greenhouse"):
					farm_bonus = true
				else:
					add_log("%s couldn't farm: the Greenhouse is off." % c.name)
			"Research":
				research += 1
			"Medic":
				var patient = null
				for other in crew:
					if other != c and (patient == null or other.fatigue > patient.fatigue):
						patient = other
				if patient != null and medical >= 5.0 and patient.fatigue > 0:
					patient.fatigue = max(patient.fatigue - 25, 0)
					medical -= 5.0
					add_log("%s treated %s." % [c.name, patient.name])


## Multi-day jobs: the crew member is locked in until days_left reaches 0.
## A day lost to shelter or exhaustion doesn't count (the loop skips this function).
func _work_long_task(c: Dictionary):
	if (c.task == "Build Reactor" and reactor_built) or (c.task == "Build Comms" and (comms_online or comms_blackout > 0)):
		add_log("%s: that's already built. Switching to Rest." % c.name)
		c.task = "Rest"
		c.days_left = 0
		return
	if c.days_left == 0:
		c.days_left = TASK_DAYS[c.task]
		add_log("%s started %s (%d days)." % [c.name, c.task, c.days_left])
	c.days_left -= 1
	if c.days_left > 0:
		add_log("%s: %s, %d day(s) left." % [c.name, c.task, c.days_left])
		return
	match c.task:
		"Build Reactor":
			reactor_built = true
			add_log("[color=green]%s finished the reactor! +40 kW, day and night.[/color]" % c.name)
		"Build Comms":
			comms_online = true
			add_log("[color=green]%s brought Comms online! Supply orders available.[/color]" % c.name)
		"Expedition":
			water = min(water + 60.0, water_max)
			ice_mined += 60.0
			research += 2
			add_log("[color=green]%s returned from the expedition: +60 L water, +2 research.[/color]" % c.name)
	c.task = "Rest"


func _power():
	solar_output = 0.0 if in_shadow else solar_arrays * SOLAR_ARRAY_KW * (1.0 - dust / 100.0)
	power_generated = solar_output + (REACTOR_KW if reactor_built else 0.0)
	power_used = HABITAT_KW
	for m in modules:
		if m.on and not m.broken:
			power_used += m.power
	battery += (power_generated - power_used) * HOURS
	brownout = battery < 0.0
	if brownout:
		battery = 0.0
		add_log("[color=red]Battery empty! Life support lost power today.[/color]")
	battery = min(battery, battery_max)
	if in_shadow:
		solar_condition = "Shadow"
	elif dust > 0:
		solar_condition = "Dusty (-%d%%)" % dust
	else:
		solar_condition = "Functional"


func _life_support():
	var o2_made := 0.0
	if running("oxygen") and water >= 5.0:
		o2_made = 4.0                  # splitting ~4.5 L of water
		water -= 4.5
	var leak := 2.0 if hull_leak else 0.0
	oxygen = clamp(oxygen + o2_made - CREW_SIZE * O2_PER_CREW - leak, 0.0, oxygen_max)

	co2 = clamp(co2 + (-30.0 if running("scrubber") else 25.0), 0.0, 100.0)

	var water_used := CREW_SIZE * WATER_PER_CREW
	if running("recycler"):
		water_used *= 0.1              # ~90% recovered (the ISS reaches 98%)
	water = clamp(water - water_used, 0.0, water_max)

	var grown := 0.0
	if running("greenhouse"):
		grown = 3.0 if farm_bonus else 1.5
	food = clamp(food + grown - CREW_SIZE * FOOD_PER_CREW, 0.0, food_max)


func _radiation():
	for c in crew:
		var dose := DOSE_HABITAT
		if c.far:
			dose = DOSE_EXPEDITION
		elif c.outside:
			dose = DOSE_OUTSIDE
		if storm_today:
			dose += 10.0 if sheltered else 80.0
		c.dose += dose


# ---------------- Supply ----------------
func can_order() -> bool:
	return comms_online and supply_eta < 0 and supply_cooldown == 0 and not mission_over

func request_supply(kind: String):
	if not can_order():
		return
	supply_order = kind
	supply_eta = 2
	supply_cooldown = 5
	add_log("Supply ordered: %s. Arrives in 2 days." % kind)
	changed.emit()

func _supply():
	if supply_eta > 0:
		supply_eta -= 1
		if supply_eta == 0:
			for resource in CARGO[supply_order]:
				set(resource, get(resource) + CARGO[supply_order][resource])
			add_log("[color=green]Supply lander arrived: %s.[/color]" % supply_order)
			supply_eta = -1
	if supply_cooldown > 0:
		supply_cooldown -= 1


# ---------------- Save / load ----------------
const SAVE_PATH := "user://savegame.dat"     # works on desktop and in the browser
const SAVE_KEYS := [
	"day", "minutes", "mission_length", "chosen_length", "ice_goal", "mission_over", "shadow_days", "dust", "reactor_built",
	"battery", "battery_max", "oxygen", "oxygen_max", "co2", "water", "water_max", "food",
	"food_max", "parts", "medical", "research", "ice_mined", "modules", "crew", "comms_online",
	"comms_blackout", "supply_eta", "supply_cooldown", "supply_order", "hull_leak",
]

func save_game():
	var data := {}
	for k in SAVE_KEYS:
		data[k] = get(k)
	data["log_lines"] = Array(log_lines)
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_var(data)
	add_log("[color=gray]Game saved.[/color]")

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = f.get_var()
	if typeof(data) != TYPE_DICTIONARY:
		return false
	for k in SAVE_KEYS:
		if data.has(k):
			set(k, data[k])
	log_lines.assign(data.get("log_lines", []))
	events_today.clear()
	preview_power()
	return true


# ---------------- Ending ----------------
func _check_end():
	if oxygen <= 0.0:
		_end(false, "The crew ran out of oxygen on Day %d. The oxygen generator needs both power and water." % day)
	elif co2 >= 100.0:
		_end(false, "CO2 built up to a dangerous level on Day %d. The CO2 scrubber must stay on." % day)
	elif water <= 0.0:
		_end(false, "Water ran out on Day %d. Recycling and ice mining keep a Moon base alive." % day)
	elif food <= 0.0:
		_end(false, "Food ran out on Day %d. Greenhouses and supply landers feed the crew." % day)
	elif max_dose() >= DOSE_LIMIT:
		_end(false, "A crew member passed NASA's 250 mSv safety limit. Keep the radiation alarm on and shelter during storms.")
	elif day >= mission_length:
		var done := 0
		for o in objectives():
			if o.done:
				done += 1
		_end(true, "Mission complete! Your crew survived %d days on the Moon. Objectives met: %d/3. Research points: %d." % [mission_length, done + 1, research])

func _end(won: bool, reason: String):
	mission_over = true
	add_log(("[color=green]" if won else "[color=red]") + reason + "[/color]")
	mission_ended.emit(won, reason)
