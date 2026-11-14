extends SceneTree
## Headless checks of terrain metadata, input, collisions and animation state.
func _initialize() -> void:
	call_deferred("_run")

func advance(frames: int) -> void:
	for i in range(frames):
		await physics_frame

func _run() -> void:
	var state = root.get_node("AffState")
	var previous: Dictionary = state.data.duplicate(true)
	state.new_game()
	var scene = load("res://scenes/affinix/game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var terrain: Node = scene.world.get_node("Terrain")
	assert(terrain.layers.size() == 9)
	assert(terrain.tileset.get_terrain_sets_count() == 9)
	assert(terrain.layers[0].get_used_cells().size() == 120 * 80)
	assert(terrain.water_detail.get_used_cells().size() > 1000)
	assert(terrain.water_detail.tile_set.tile_size == Vector2i(4, 4))
	assert(terrain._mask(7, 62, 20) == 15)
	assert(terrain._mask(7, 0, 0) == 0)
	var transition_found := false
	for x in range(48, 76):
		for y in range(10, 30):
			var mask: int = terrain._mask(7, x, y)
			if mask > 0 and mask < 15:
				transition_found = true
	assert(transition_found)
	assert(scene.player.ATLAS.get_size() == Vector2(192, 896))
	for mode in scene.player.STATES:
		for direction in range(4):
			scene.player.anim_state = mode
			scene.player.facing = direction
			var rect: Rect2 = scene.player.animation_source_rect()
			assert(rect.position.y == (scene.player.STATES.find(mode) * 4 + direction) * 32)
			assert(rect.position.x >= 0 and rect.end.x <= 192 and rect.end.y <= 896)
	assert(scene.player.get_parent().y_sort_enabled)
	assert(scene.hud.hotbar_buttons.size() == 8)
	assert(root.get_visible_rect().size == Vector2(1280,720))
	var first_slot: Rect2 = scene.hud.hotbar_buttons[0].get_global_rect()
	var last_slot: Rect2 = scene.hud.hotbar_buttons[7].get_global_rect()
	assert(first_slot.position.x >= 0 and last_slot.end.x <= 1280 and last_slot.end.y <= 720)
	var player = scene.player
	player.collision_mask = 0
	for test in [["aff_up", Vector2.UP, 1], ["aff_down", Vector2.DOWN, 0], ["aff_left", Vector2.LEFT, 2], ["aff_right", Vector2.RIGHT, 3]]:
		player.position = Vector2(400, 400)
		player.velocity = Vector2.ZERO
		Input.action_press(test[0])
		await advance(16)
		Input.action_release(test[0])
		assert((player.position - Vector2(400,400)).dot(test[1]) > 5.0)
		assert(player.facing == test[2])
		assert(player.anim_state == "walk")
		await advance(9)
	player.position = Vector2(400,400)
	player.velocity = Vector2.ZERO
	Input.action_press("aff_right")
	Input.action_press("aff_down")
	await advance(16)
	Input.action_release("aff_right")
	Input.action_release("aff_down")
	var diagonal: Vector2 = player.position - Vector2(400,400)
	assert(diagonal.x > 3 and diagonal.y > 3 and absf(diagonal.x - diagonal.y) < 2.0)
	player.position = Vector2(400,400)
	player.velocity = Vector2.ZERO
	Input.action_press("aff_right")
	Input.action_press("aff_run")
	await advance(16)
	assert(player.anim_state == "run")
	Input.action_release("aff_right")
	Input.action_release("aff_run")
	assert(player.position.x > 413)
	player.collision_mask = 1
	player.position = Vector2(815,320)
	player.velocity = Vector2.ZERO
	Input.action_press("aff_right")
	await advance(48)
	Input.action_release("aff_right")
	assert(player.position.x < 829.0)
	for action in ["gather", "chop", "fish", "interact"]:
		player.interact_animation(action)
		await advance(2)
		assert(player.anim_state == action)
	state.add_item("rod")
	player.position = Vector2(816, 320)
	scene.selected = {"id":"lake", "kind":"lake", "pos":Vector2(816,320)}
	scene._interact()
	await advance(2)
	assert(player.anim_state == "fish" and scene.hud.fishing)
	scene.hud.fish_marker.value = 50
	var fish_before: int = state.amount("fish")
	for child in scene.hud.box.get_children():
		if child is Button and child.text == "Reel in":
			child.pressed.emit()
			break
	assert(state.amount("fish") == fish_before + 1 and not scene.screen_open)
	state.data["hunger"] = 50.0
	var berries: int = state.amount("berry")
	scene.hud.use_hotbar(5)
	assert(scene.hud.selected_slot == 5 and state.amount("berry") == berries - 1)
	scene.hud.open_inventory()
	assert(scene.screen_open)
	scene.hud.close_screen()
	scene.queue_free()
	await process_frame
	state.data = previous
	print("AFFINIX visual-system headless checks passed")
	quit(0)
