# EXPERIMENTAL

**An experiment to put people on the Moon, and keep them alive. You are in command.**

EXPERIMENTAL is a pixel-art strategy game for young learners, made for the **NASA International Space Apps Challenge 2026** challenge *Build a Junior Astronaut Mission Trainer*. The premise: humanity's first long-term lunar outpost is an experiment, and you are its commander. You run a four-person base on Shackleton Connecting Ridge at the Moon's south pole, the site NASA picked for its Moon Base. Every day you assign tasks to your crew, switch life-support systems on and off, and deal with emergencies, while balancing power, oxygen, CO₂, water, food and radiation.

▶ **Play in your browser:** https://tk-n15.itch.io/experimental
🎬 **30-second demo:** _[video link]_

---

## Why we made it

Space-themed learning tools tend to either oversimplify the engineering trade-offs of a real mission or make them too complex for young learners. EXPERIMENTAL makes those trade-offs tangible: switching on ice mining drains the battery the crew needs during the lunar shadow, and sending an astronaut to build the reactor means nobody is free to fix the hull leak. When a mission fails, the end screen explains *why*, so players learn from their own decisions.

## How to play

1. **Choose a mission** from the main menu: *Training* (7 days) or *Full Mission* (30 days).
2. **Assign each crew member a task**: Rest, Repair, Clean, Mine, Farm, Research, Medic, or a multi-day job (Build Reactor, Build Comms, Expedition).
3. **Manage your systems** in *Utility → Expand*: oxygen generator, CO₂ scrubber, water recycler, greenhouse, ice mining and radiation alarm. Each one costs power.
4. **Press END DAY** (or wait for midnight). The day plays out, events strike, and the mission log explains what happened.
5. **Survive** to the last day and complete your objectives.

Open the **Handbook** (H icon) at any time for the rules, every task and event, and the real science behind the game.

### You lose if
oxygen, water or food runs out, CO₂ reaches a dangerous level, or a crew member passes NASA's 250 mSv radiation limit.

## Features

- **Real resource trade-offs:** generation vs. consumption, battery storage, and shadow days when the solar panels produce nothing.
- **10 crew tasks**, including multi-day jobs that lock a crew member in for 2–3 days.
- **12 random events** that grow more frequent through the mission: solar storms, micrometeorite hull breaches, moonquakes, dust storms, crop blight, comms blackouts and more.
- **Supply landers** ordered from Earth once Comms is built, with limited cargo and cooldowns.
- **Screens that come online** as the base develops.
- **An end screen that explains the outcome**, so failing teaches something.
- **An in-game Handbook**, including a *Real Science* page with the NASA facts behind the numbers.
- **Save / load, pause menu, and a training mode** short enough to finish in a few minutes.

## The science: real NASA numbers

| In the game | Based on |
| --- | --- |
| Each astronaut breathes 0.84 kg of O₂ per day | NASA life-support baseline values (BVAD) |
| Habitat uses ~20 kW; a vertical solar array makes ~10 kW; base camp under 100 kW | NASA lunar surface power studies |
| Fission reactor for power through dark periods | NASA / DOE lunar surface reactor plans |
| Base at Shackleton Connecting Ridge, near water ice | NASA Moon Base plan |
| Radiation alarm with shelter warnings | NASA Orion HERA radiation sensors (Artemis) |
| 250 mSv per-event radiation limit | NASA radiation protection standard |
| ~1.4 mSv/day on the lunar surface | Chang'E 4 lander measurements |
| Water recycling (ISS reaches 98%; game uses 90%) | ISS life-support results |
| Dust coats solar panels and wears equipment | Apollo mission dust reports (NASA) |
| A few cargo landings per year | NASA Moon Base logistics plan |

Some values are simplified or scaled for gameplay; these are noted in the source code (`GameState.gd`).

## Built with

- [Godot Engine 4.7](https://godotengine.org) (GDScript), MIT license
- [Kenney Fonts](https://kenney.nl), CC0
- All pixel art (crew portraits, station backgrounds, icons) is original, made for this project.

## Run it locally

1. Install **Godot 4.7** (standard edition).
2. Clone this repository and open `project.godot` in Godot.
3. Press **F5**.

## Sources

### NASA
- [Astronaut mass balance / BVAD values (NTRS)](https://ntrs.nasa.gov/api/citations/20190027563/downloads/20190027563.pdf)
- [OCHMO: ECLSS Technical Brief](https://www.nasa.gov/wp-content/uploads/2023/07/eclss-technical-brief-ochmo.pdf)
- [Electric Power on the Moon (Csank, 2025)](https://ntrs.nasa.gov/api/citations/20250000763/downloads/Csank_Pr_LunarSurfacePowerJAXA20250000763.pdf)
- [Lunar Surface Power Systems (Scott, 2023)](https://ntrs.nasa.gov/api/citations/20230005406/downloads/Space%20Power%20Workshop%20Plenary%20Draft%204-10-2023.pdf)
- [Lunar Surface Operations & Power Grid (NTRS)](https://ntrs.nasa.gov/citations/20230002896)
- [NASA and DOE to develop lunar surface reactor by 2030](https://www.nasa.gov/news-release/nasa-department-of-energy-to-develop-lunar-surface-reactor-by-2030)
- [OCHMO: Radiation Protection Technical Brief](https://www.nasa.gov/wp-content/uploads/2023/03/radiation-protection-technical-brief-ochmo.pdf)
- [To protect Artemis II astronauts, NASA experts keep eyes on the Sun](https://science.nasa.gov/missions/artemis/artemis-2/to-protect-artemis-ii-astronauts-nasa-experts-keep-eyes-on-sun/)
- [NASA Moon Base](https://www.nasa.gov/reference/moonbase-about/)
- [Building the Moon Base (PDF)](https://www.nasa.gov/wp-content/uploads/2026/03/building-the-moon-base.pdf)
- [Moon Base Architecture User's Guide (PDF)](https://nasa.gov/wp-content/uploads/2026/04/moon-base-architecture-users-guide.pdf)
- Gaier, *The Effects of Lunar Dust on EVA Systems During the Apollo Missions*, NASA/TM-2005-213610
- [Human Research Program: 5 Hazards of Human Spaceflight](https://www.nasa.gov/hrp/hazards)
- [Internal Layout of a Lunar Surface Habitat (NTRS)](https://ntrs.nasa.gov/api/citations/20220013669/downloads/Internal%20Layout%20of%20a%20Lunar%20Surface%20Habitat.pdf)
- [Habitat Water Wall](https://technology.nasa.gov/patent/TOP2-197)

### Other
- Zhang et al. (2020), *Science Advances*: Chang'E 4 lunar surface radiation ([summary](https://www.sci.news/space/radiation-dose-rates-lunar-surface-08893.html))
- [ISS 98% water recovery (Universe Today)](https://www.universetoday.com/162126/good-news-astronauts-are-drinking-almost-all-of-their-own-urine)
- [NASA Space Apps 2026: Junior Astronaut Mission Trainer](https://www.spaceappschallenge.org/2026/challenges/junior-astronaut-mission-trainer/)

## Use of AI

An AI assistant (Claude) was used to help research NASA sources and to draft and debug parts of the GDScript code. All game design decisions, pixel art and testing were done by the author.

## Disclaimer

This is a student project made for the NASA International Space Apps Challenge. It is **not** made, sponsored or endorsed by NASA. Some numbers are simplified for gameplay.

## License

[MIT](LICENSE)
