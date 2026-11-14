# AFFINIX

A Godot 4 top-down pixel-art survival adventure. Open `project.godot` in Godot 4, allow the assets to import, then press **F5**. The active main scene is `scenes/affinix/menu.tscn`. Linux and Windows are the intended desktop platforms.

## Current scope

This is the **first playable implementation**, not the requested finished 3–4 hour game. It includes a title menu, six connected stylized regions, Chill Boy movement, camera, terrain collision, gathering and respawn, inventory, crafting, structure placement and recovery, two NPC conversations and favors, fishing, a 13-step main journal, needs, sleep, day/night tint, weather, original synthesized music/effects, and one save slot. The original ASHORE and ORMA scenes remain in the repository but are not launched.

The V2 visual pass uses layered `TileMapLayer` terrain with corner-based transition masks and terrain metadata, plus a finer shoreline layer. The lake has curved collision, animated glints and reeds. Chill Boy has a 32×32, four-direction sheet with idle, walk, run, gather, chop, fish and interaction states, and the compact HUD has a selected quick slot. Resource IDs and the version-one save format are retained.

The artwork and animation remain simple original pixel art, not a finished production-quality art set; the lake is an ellipse and the terrain is deterministically generated rather than hand-authored. Several existing props and NPC sprites are retained. The underground remains a region rather than a separate cave scene. Not yet complete: a hand-authored full-length campaign or verified 3–4 hour pacing, full NPC schedules, complete animal AI, drag-and-drop inventory/equipment, extensive building customization, configurable controls, advanced tools, a cooking station, multiple save slots, proper ending polish, and visual/audio playtesting. The generated title illustration and textures are original project assets; the character/terrain sprites were made for the project. Nunito is licensed under SIL OFL (`assets/fonts/OFL-Nunito.txt`). Sounds are synthesized by `tools/make_affinix_audio.py` and `tools/make_island_audio.py`.

## Controls

- **WASD / arrows** move; **Shift** runs.
- **E** or left click interacts. Approach the cabin first to read the notebook.
- **I** opens inventory (select food to eat); **C** opens recipes and structures. **1–8** or the on-screen hotbar use the fixed quick slots: food is eaten, resources open the bag, and tools explain their automatic use when carried.
- To build, choose a structure, move the mouse near the player and click or press **E**; **R** rotates, **Esc** cancels. Stand near a structure and press **X** to reclaim its materials. Use a chest with **E** to store or withdraw items; a tent permits sleep; a campfire enables recipes and warmth.
- **J** opens the journal; **M** opens the map; **Esc** pauses. The pause menu can turn the atmospheric overlay off for lighter rendering.
- Save manually from the pause menu or save and return to the title. Autosave runs every 30 seconds and on a normal window close. Data is stored separately from the earlier games at `user://affinix_save_v1.json`.

The game asks for confirmation before replacing an existing AFFINIX save. Continue does not overwrite an unreadable save.

## Testing

```sh
python3 tests/affinix/check_assets.py
gdparse scripts/affinix/*.gd tests/affinix/smoke.gd
# With Godot 4 installed, import the project first:
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/affinix/smoke.gd
godot --headless --path . --script res://tests/affinix/visual_smoke.gd
```

The headless tests change only in-memory state and do not write the player's save. They exercise crafting, movement in four directions and diagonally, running, lake collision, sprite-frame selection, terrain metadata, 1280×720 HUD bounds, gathering, fishing, hotbar, UI, pause and sleep. Both passed in a custom Godot 4.4.1 headless build without a renderer. A separate sandboxed save/reload test passed. That custom build reports a missing renderer and audio-resource cleanup warnings on exit; it cannot validate actual on-screen rendering, animation appearance, sounds or the complete story. Test the project interactively in the official Godot 4 editor as well.
