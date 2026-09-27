# Pocket Pitch

Pocket Pitch is a small, turn-based flick soccer game made with Godot for
Android and desktop. It focuses on quick matches, simple physics, and a basic
retro presentation.

## Features

- Single-player matches against a simple computer opponent
- Local two-player matches on the same device
- Choice of three or five physics-based player discs per team
- Touchscreen and mouse controls
- First team to score three goals wins
- Retro graphics and sound effects

## Requirements

- Godot 4.7 or a compatible newer Godot 4 release
- Android export templates and an Android SDK when creating an APK

## Running the game

1. Open this directory from the Godot Project Manager.
2. Press **F6** or **F5** to run the game.
3. Choose **1 Player** or **2 Players** from the main menu.

## Controls

1. Select one of the highlighted discs belonging to the active team.
2. Drag backward from the disc to choose the shot direction and power.
3. Release to shoot.
4. Wait for all pieces to stop moving before the next turn begins.

On Android, use one finger. On desktop, use the left mouse button.

## Match rules

- Teams take one shot per turn.
- A goal counts when the entire ball crosses the goal line.
- After a goal, the team that conceded takes the next turn.
- The first team to score three goals wins the match.

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
scripts/
  main.gd            Match flow, input, scoring, and computer opponent
  player_disc.gd     Team piece state and appearance
  retro_audio.gd     Generated retro sound effects
AGENTS.md             Project coding and scene-authoring guidelines
project.godot         Godot project configuration
```

## Development guidelines

Read [AGENTS.md](AGENTS.md) before changing the project. Visible game objects
should be authored in scenes, and GDScript should follow the official Godot
style guide with clear names and learning-friendly comments.
