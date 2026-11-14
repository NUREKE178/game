# ASHORE — 3D survival prototype

A first-person survival **vertical slice** in Godot 4. A plane descends toward a secluded island; the player wakes near the wreck, explores the forest, gathers supplies and makes a small camp. This is a prototype, not a completed 3–4 hour game, and its generated 3D models are placeholders rather than final photorealistic assets. There are currently no enemies, story campaign, tree cutting, swimming or multiplayer.

## Run

Import `project.godot` in Godot 4, let assets finish importing, then press F5. On the main menu, choose **New Game**. If an existing save is present, a second press confirms replacement. **Continue** opens the saved island.

## Controls

| Action | Key |
| --- | --- |
| Look | Mouse |
| Move | W A S D |
| Sprint | Left Shift |
| Jump | Space |
| Pick up resources / collect water near the pond | E |
| Build campfire or shelter | C |
| Eat berries | R |
| Drink water | F |
| Pause / skip the crash intro | Esc |

Find sticks, stones and berry bushes on the ground. Fresh water is available at the pond inland. A campfire costs 3 sticks and 2 stones; a shelter costs 5 sticks. They are placed in front of the player on dry ground. The current shelter and fire are visual structures, not yet a complete warmth or sleeping system.

Health decreases when food or water runs out. The player wakes near the wreck if health runs out or they fall off the island; collected supplies remain. The world is a finite island surrounded by ocean, not a voxel world and there is no digging.

## Settings and saving

Select **Low**, **Medium** or **High** graphics in the main menu or pause menu. The presets adjust 3D render scale, view distance, shadows and anti-aliasing; Medium is the default. These are manual settings, not automatic hardware detection. Master volume is adjustable in both menus; mouse sensitivity is in the main menu. Settings are saved in `user://ashore_settings.cfg`.

The game stores one save in `user://ashore_save_v1.json`. Player position, needs, collected resources and placed structures are saved every 30 seconds, when leaving to the menu, and on a normal window close. The older 2D prototype uses a different save path and is not overwritten.

## Assets

The title background, forest floor and bark textures were generated for this project. The terrain, vegetation, wreck and structures are original procedural prototype meshes. Ambience, footsteps, item and crash sounds are synthesized by `tools/make_island_audio.py` without external samples. Nunito is provided under SIL Open Font License; see `assets/fonts/OFL-Nunito.txt`.

## Checks

```sh
python3 tests/check_island.py
godot --headless --path . --editor --import
godot --headless --path . --script res://tests/island_smoke.gd
```

The headless smoke test does not write save files. Graphical, audio, performance, gamepad and end-to-end save/restore checks still require interactive testing on a Godot-enabled system. The previous 2D prototype's scenes remain in the repository but are not the active game.
