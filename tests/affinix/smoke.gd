extends SceneTree
## Run in Godot 4 after importing. Does not write to the player's save file.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state = root.get_node("AffState")
	var previous: Dictionary = state.data.duplicate(true)
	state.new_game()
	assert(state.amount("wood") == 0)
	state.add_item("wood", 3)
	state.add_item("stone", 2)
	state.set_flag("notebook")
	assert(state.data["quest"] == 2)
	state.craft(0)
	assert(state.amount("axe") == 1)
	assert(state.amount("wood") == 0)
	state.add_item("wood", 3)
	state.add_item("stone", 2)
	assert(state.add_building(0, Vector2(320, 340), 0))
	assert(state.has_building("campfire"))
	assert(state.data["quest"] == 3)
	var scene = load("res://scenes/affinix/game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.player != null and scene.world != null and scene.hud != null)
	assert(scene.world.region(Vector2(288, 320)) == "Whispering Forest")
	assert(scene.player.get_parent().y_sort_enabled)
	assert(scene.world.visuals.size() == scene.world.objects.size())
	assert(scene.hud.hotbar_buttons.size() == 8)
	var start_pos: Vector2 = scene.player.position
	Input.action_press("aff_right")
	await create_timer(0.3).timeout
	Input.action_release("aff_right")
	assert(scene.player.position.x > start_pos.x + 3.0)
	var tree: Dictionary = {}
	for object in scene.world.objects:
		if object["kind"] == "tree":
			tree = object
			break
	assert(not tree.is_empty())
	scene.player.position = tree["pos"] + Vector2(0, 16)
	scene.selected = tree
	var before_wood: int = state.amount("wood")
	scene._interact()
	assert(state.amount("wood") > before_wood)
	assert(not scene.world.active(tree))
	assert(not scene.world.visuals[tree["id"]].visible)
	state.data["hunger"] = 50.0
	var berry_count: int = state.amount("berry")
	scene.hud.use_hotbar(5)
	assert(state.amount("berry") == berry_count - 1 and state.data["hunger"] > 50.0)
	var cache: Dictionary = {}
	for object in scene.world.objects:
		if object["id"] == "hidden_cache_1":
			cache = object
			break
	assert(not cache.is_empty())
	scene.player.position = cache["pos"] + Vector2(0, 15)
	scene.selected = cache
	scene._interact()
	assert(not scene.world.active(cache))
	scene.hud.open_inventory()
	assert(scene.screen_open)
	scene.hud.close_screen()
	assert(not scene.screen_open)
	scene.hud.open_crafting()
	assert(scene.screen_open)
	scene.hud.close_screen()
	scene.hud.open_journal()
	assert(scene.screen_open)
	scene.hud.close_screen()
	scene.hud.open_fishing()
	assert(scene.hud.fishing)
	scene.hud.close_screen()
	scene.set_pause(true)
	assert(paused)
	scene.set_pause(false)
	assert(not paused)
	var old_day: int = int(state.data["day"])
	state.sleep()
	assert(state.data["day"] == old_day + 1)
	scene.queue_free()
	await process_frame
	state.data = previous
	print("AFFINIX smoke test passed")
	quit(0)
