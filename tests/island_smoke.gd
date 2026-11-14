extends SceneTree
## Run after importing: godot --headless --path . --script res://tests/island_smoke.gd
## Existing saves may be read, but are never written by this test.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	set_meta("ashore_new", false)
	var island = load("res://scenes/island_world.tscn").instantiate()
	root.add_child(island)
	island.save_enabled = false
	await process_frame
	assert(island.player != null and island.hud != null)
	assert(island.height_at(0, 0) > island.height_at(135, 0))
	island.inventory["stick"] = 10
	island.inventory["stone"] = 10
	island.crafting = true
	island.player.position = Vector3(0, island.height_at(0, 0) + 0.1, 0)
	island.structures.clear()
	island.craft("fire")
	assert(island.structures.size() == 1)
	assert(island.inventory["stick"] == 7 and island.inventory["stone"] == 8)
	island.crafting = false
	island.set_pause(true)
	assert(paused)
	island.set_pause(false)
	assert(not paused)
	island.queue_free()
	print("ASHORE smoke test passed")
	quit(0)
