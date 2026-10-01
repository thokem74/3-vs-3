# Pocket Pitch

Pocket Pitch is a small, turn-based flick soccer game made with Godot for
Android and desktop. It combines quick physics-based matches with a colorful
top-down broadcast presentation.

## Features

- Single-player matches with three CPU difficulty levels
- Local two-player matches on the same device
- Choice of 3-vs-3 or 5-vs-5 teams
- Goal-target matches to 3, 5, or 10 goals
- Timed matches lasting 3, 5, or 10 minutes
- Twelve national teams with three-color discs and vector flags
- Random, non-duplicate national teams at application startup
- Team names and flags displayed beside the scoreboard
- Visible aim guides for both player and CPU shots
- Touchscreen and mouse controls
- Striped pitch, complete field markings, goal nets, and advertising boards
- Retro-inspired graphics and generated sound effects

## National teams

Brazil, Argentina, Germany, France, Netherlands, Portugal, Japan, Mexico,
Norway, Spain, England, and Switzerland are available. Each team uses three
concentric flag-inspired colors. The two teams must always use different
nations.

## Requirements

- Godot 4.7 or a compatible newer Godot 4 release
- Android export templates and an Android SDK when creating an APK

## Running the game

1. Open this directory from the Godot Project Manager.
2. Press **F5** to run the project.
3. Choose the player mode, team size, and victory condition.
4. Optionally select **Customize Teams**, then press **Start**.

The **1P • CPU 1** button cycles through CPU Levels 1, 2, and 3 when it is
already selected. The goal and time buttons work similarly: select a match
type, then press its active button again to cycle through 3, 5, and 10. The
default match is single-player, 3-vs-3, and first to 3 goals.

## Controls

1. Select one of the highlighted discs belonging to the active team.
2. Drag backward from the disc to choose the shot direction and power.
3. Release to shoot.
4. Wait for all pieces to stop moving before the next turn begins.

On Android, use one finger. On desktop, use the left mouse button.

During a CPU turn, the yellow aim guide shows the disc, direction, and power
of the planned shot for the complete thinking period.

## Match rules

- Teams take one shot per turn.
- A goal counts when the entire ball crosses the goal line.
- After a goal, the team that conceded takes the next turn.
- In a goal-target match, the first team to reach the selected score wins.
- In a timed match, the countdown continues during turns and goal pauses. The
  team with the higher score at `00:00` wins; equal scores result in a draw.
- **Play Again** keeps the selected mode, team size, match rule, CPU level,
  and national teams.

## Android export

1. Install the Android build template from **Editor > Manage Export Templates**.
2. Configure the Android SDK in **Editor > Editor Settings > Export > Android**.
3. Open **Project > Export** and add an Android preset.
4. Choose **Export Project** to create an APK for testing or an AAB for release.

The project uses Godot's mobile renderer and is designed for landscape play.

## Project structure

```text
scenes/
  main.tscn          Main menu, pitch, interface, and match scene
  ball.tscn          Physics ball and its visible components
  player_disc.tscn   Reusable physics player piece
  nation_flag.tscn   Reusable vector flag display
scripts/
  main.gd            Match flow, input, scoring, timer, and CPU opponent
  player_disc.gd     Team piece state and appearance
  team_customization.gd  Session-only national team choices and palettes
  nation_flag.gd     Simplified vector drawings for the twelve flags
  retro_audio.gd     Generated retro sound effects
AGENTS.md             Project coding and scene-authoring guidelines
project.godot         Godot project configuration
```

## Development guidelines

Read [AGENTS.md](AGENTS.md) before changing the project. Visible game objects
should be authored in scenes, and GDScript should follow the official Godot
style guide with clear names and learning-friendly comments.
