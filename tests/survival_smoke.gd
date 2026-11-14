extends SceneTree
## Run with: godot --headless --path . --script res://tests/survival_smoke.gd
## This test never writes a save file.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	set_meta("orma_new_world", false)
	var world = load("res://scenes/survival_world.tscn").instantiate()
	root.add_child(world)
	world.save_enabled = false
	await process_frame
	assert(world.player != null and world.hud != null)
	assert(world.chunks.size() == 7)
	assert(world.get_cell(0, world.surface(0)) == 1)
	var x := -20
	var y: int = world.surface(x) + 1
	world._set_cell(x, y, 0)
	assert(world.get_cell(x, y) == 0)
	world.inventory["wood"] = 1
	world.inventory["plank"] = 0
	world.craft_planks()
	assert(world.inventory["wood"] == 0 and world.inventory["plank"] == 4)
	world.inventory["stone"] = 2
	world.inventory["brick"] = 0
	world.craft_bricks()
	assert(world.inventory["stone"] == 0 and world.inventory["brick"] == 4)
	world.inventory["berry"] = 1
	world.hunger = 50.0
	world.eat_berry()
	assert(world.hunger == 70.0 and world.inventory["berry"] == 0)
	world.set_pause(true)
	assert(paused)
	world.set_pause(false)
	assert(not paused)
	world.set_inventory(true)
	assert(world.inventory_open and not world.player.controls_enabled)
	world.set_inventory(false)
	assert(world.player.controls_enabled)
	world.queue_free()
	print("ORMA survival smoke test passed")
	quit(0)
