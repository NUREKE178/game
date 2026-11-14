extends Node2D
const World = preload("res://scripts/affinix/world.gd")
const Player = preload("res://scripts/affinix/player.gd")
const HUD = preload("res://scripts/affinix/hud.gd")
const Atmosphere = preload("res://scripts/affinix/atmosphere.gd")
var world: World
var player: Player
var hud: HUD
var selected: Dictionary = {}
var screen_open := false
var paused := false
var placing := -1
var rotation_step := 0
var autosave_timer := 0.0
var refresh_timer := 0.0
var day_light: CanvasModulate
var atmosphere: Node2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	world = World.new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	var actors := Node2D.new()
	actors.y_sort_enabled = true
	actors.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(actors)
	player = Player.new()
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	var start: Array = AffState.data.get("position", [288,320])
	if start.size() == 2:
		player.position = Vector2(float(start[0]), float(start[1]))
	player.step_taken.connect(func(): AffAudio.play("step"))
	actors.add_child(player)
	world.hero = player
	world.attach_visuals(actors)
	atmosphere = Atmosphere.new()
	atmosphere.world = world
	atmosphere.process_mode = Node.PROCESS_MODE_PAUSABLE
	atmosphere.z_index = 8
	add_child(atmosphere)
	day_light = CanvasModulate.new()
	day_light.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(day_light)
	var layer := CanvasLayer.new()
	layer.layer = 10
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	hud = HUD.new()
	hud.game = self
	layer.add_child(hud)
	AffState.message.connect(hud.notify)
	AffState.quest_completed.connect(func(title: String): hud.notify("Journal updated: " + title))
	hud.refresh()

func _process(delta: float) -> void:
	if paused:
		return
	if not screen_open:
		AffState.data["minute"] = float(AffState.data["minute"]) + delta * 2.0
		if float(AffState.data["minute"]) >= 1440.0:
			AffState.data["minute"] = float(AffState.data["minute"]) - 1440.0
			AffState.data["day"] = int(AffState.data["day"]) + 1
			world._sync_obstacles()
			world.refresh_visuals()
			var weathers := ["Sunny", "Wind", "Rain", "Fog", "Sunny"]
			AffState.data["weather"] = weathers[(int(AffState.data["day"]) - 1) % weathers.size()]
		AffState.data["hunger"] = maxf(0.0, float(AffState.data["hunger"]) - delta * 0.018)
		if float(AffState.data["hunger"]) <= 0.0:
			AffState.data["health"] = maxf(0.0, float(AffState.data["health"]) - delta * 0.06)
		var cold := world.region(player.position) in ["Misty Mountains", "Secret Underground"]
		var near_fire := _near_fire()
		var temp_target := 10.0 if cold and not near_fire else 100.0
		AffState.data["temperature"] = move_toward(float(AffState.data["temperature"]), temp_target, delta * 0.2)
		if float(AffState.data["temperature"]) < 25.0:
			AffState.data["health"] = maxf(0.0, float(AffState.data["health"]) - delta * 0.04)
		if float(AffState.data["health"]) <= 0.0:
			player.position = Vector2(288, 320)
			AffState.data["health"] = 70.0
			AffState.data["hunger"] = 35.0
			AffState.data["energy"] = 45.0
			hud.notify("You woke up at the cabin. Your supplies are safe.")
		if world.region(player.position) == "Autumn Valley":
			AffState.set_flag("autumn")
	selected = world.nearest(player.position)
	var hour := float(AffState.data["minute"]) / 60.0
	# Smooth dawn, dusk and blue nights; avoid a midnight/6 AM colour jump.
	var night := 1.0 - smoothstep(5.0, 7.0, hour) if hour < 12.0 else smoothstep(18.0, 21.0, hour)
	var dusk := maxf(0.0, 1.0 - absf(hour - 18.5) / 1.5)
	var light_color := Color.WHITE.lerp(Color(0.54, 0.62, 0.80), night * 0.85)
	light_color = light_color.lerp(Color(1.0, 0.76, 0.59), dusk * 0.35)
	if world.region(player.position) == "Secret Underground":
		light_color = light_color.lerp(Color(0.65, 0.68, 0.76), 0.35)
	if AffState.amount("lantern") > 0 or _near_lamp():
		light_color = light_color.lerp(Color.WHITE, 0.15)
	day_light.color = light_color
	autosave_timer += delta
	if autosave_timer >= 30.0:
		autosave_timer = 0.0
		_save()
	refresh_timer += delta
	if refresh_timer > 0.25:
		refresh_timer = 0.0
		hud.refresh()
		AffAudio.set_environment(world.region(player.position), str(AffState.data["weather"]))
	queue_redraw()

func _near_fire() -> bool:
	for entry in AffState.data["buildings"]:
		if entry.get("id", "") == "campfire" and player.position.distance_to(Vector2(float(entry["x"]),float(entry["y"]))) < 70:
			return true
	return false

func _near_lamp() -> bool:
	for entry in AffState.data["buildings"]:
		if entry.get("id", "") == "lamp" and player.position.distance_to(Vector2(float(entry["x"]), float(entry["y"]))) < 80:
			return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("aff_pause"):
			if placing >= 0:
				placing = -1
				hud.notify("Placement cancelled.")
			elif screen_open:
				hud.close_screen()
			else:
				set_pause(not paused)
			return
		if paused:
			return
		if placing >= 0 and event.physical_keycode == KEY_R:
			rotation_step = (rotation_step + 1) % 4
			return
		if screen_open:
			return
		if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_8 and placing < 0:
			hud.use_hotbar(int(event.physical_keycode - KEY_1))
			return
		if event.physical_keycode == KEY_X and placing < 0:
			_remove_building()
			return
		if event.is_action_pressed("aff_interact"):
			if placing >= 0:
				_place()
			else:
				_interact()
		elif event.is_action_pressed("aff_inventory"):
			hud.open_inventory()
		elif event.is_action_pressed("aff_craft"):
			hud.open_crafting()
		elif event.is_action_pressed("aff_map"):
			hud.open_map()
		elif event.is_action_pressed("aff_journal"):
			hud.open_journal()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not paused and not screen_open:
		if placing >= 0:
			_place()
		else:
			_interact()

func set_screen(value: bool) -> void:
	screen_open = value
	player.input_enabled = not value

func set_pause(value: bool) -> void:
	paused = value
	get_tree().paused = value
	hud.set_pause_visible(value)

func start_placement(index: int) -> void:
	placing = index
	rotation_step = 0
	hud.close_screen()
	hud.notify("Move the mouse; click or E to place. R rotates, Esc cancels.")

func _place() -> void:
	var pos := get_global_mouse_position().snapped(Vector2(16,16))
	if player.position.distance_to(pos) > 90 or world.is_water(pos) or pos.x < 16 or pos.y < 16 or pos.x > 1904 or pos.y > 1264:
		hud.notify("Choose open ground near you.")
		return
	if player.position.distance_to(pos) < 14 or not world.nearest(pos).is_empty():
		hud.notify("That spot is occupied.")
		return
	for b in AffState.data["buildings"]:
		if pos.distance_to(Vector2(float(b["x"]),float(b["y"]))) < 24:
			hud.notify("That spot is occupied.")
			return
	if AffState.add_building(placing, pos, rotation_step):
		placing = -1

func _near_building() -> int:
	var index := -1
	var best := 28.0
	for i in range(AffState.data["buildings"].size()):
		var building: Dictionary = AffState.data["buildings"][i]
		var dist := player.position.distance_to(Vector2(float(building["x"]), float(building["y"])))
		if dist < best:
			best = dist
			index = i
	return index

func _remove_building() -> void:
	var index := _near_building()
	if index < 0:
		hud.notify("Stand near a structure to pick it up.")
		return
	var building: Dictionary = AffState.data["buildings"][index]
	for recipe in AffState.BUILDINGS:
		if recipe["id"] == building["id"]:
			for item in recipe["cost"]:
				AffState.add_item(str(item), int(recipe["cost"][item]))
			break
	AffState.data["buildings"].remove_at(index)
	world.refresh_visuals()
	hud.notify("Structure picked up; its materials were returned.")

func _interact() -> void:
	var building_index := _near_building()
	if building_index >= 0:
		var building: Dictionary = AffState.data["buildings"][building_index]
		match building["id"]:
			"chest": hud.open_storage()
			"tent": hud.open_tent()
			"campfire": hud.open_crafting()
			_: hud.notify("Press X to pick up this structure.")
		return
	if selected.is_empty():
		return
	var kind: String = selected["kind"]
	player.interact_animation()
	match kind:
		"home": hud.open_home()
		"npc":
			AffState.set_flag(str(selected["id"]))
			hud.open_npc(str(selected["id"]))
		"lake":
			if AffState.amount("rod") <= 0:
				hud.notify("Craft a fishing rod first.")
			else:
				hud.open_fishing()
		"note":
			AffState.set_flag("village_note")
			hud.open_note("The old village", "We left a light on for the next traveler. Perhaps one day the village will be cared for again.")
		"treasure":
			AffState.data["depleted"][selected["id"]] = 999999
			AffState.add_item("berry", 3)
			AffState.add_item("wood", 2)
			AffAudio.play("gather")
			hud.notify("A hidden cache: 3 berries and 2 wood.")
			world.refresh_visuals()
		"board":
			if AffState.data["flags"].get("restored", false):
				hud.notify("The village notice board is repaired.")
			elif AffState.spend({"wood":6,"stone":3}):
				AffState.set_flag("restored")
				hud.notify("The village notice board stands again.")
			else:
				hud.notify("Repair the board: 6 wood and 3 stone.")
		_:
			_gather(kind)

func _gather(kind: String) -> void:
	var item := kind
	var count := 1
	if kind == "tree":
		item = "wood"
		count = 3 if AffState.amount("axe") > 0 else 1
	elif kind in ["mineral", "crystal"] and AffState.amount("pickaxe") <= 0:
		hud.notify("You need a pickaxe to gather this.")
		return
	elif kind == "berry":
		count = 2
	elif kind == "mushroom" and AffState.data["weather"] == "Rain":
		count = 2
	AffState.add_item(item, count)
	AffState.data["depleted"][selected["id"]] = int(AffState.data["day"]) + 2
	world._sync_obstacles()
	world.refresh_visuals()
	_float_pickup("+%d %s" % [count, AffState.ITEM_NAMES.get(item, item)])
	AffState.data["energy"] = maxf(0.0, float(AffState.data["energy"]) - 0.8)
	AffAudio.play("gather")
	hud.notify("Collected %d %s." % [count, AffState.ITEM_NAMES.get(item, item)])
	world.queue_redraw()

func _float_pickup(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.position = player.position + Vector2(-28, -42)
	label.z_index = 9
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color("#fff3be"))
	add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 18, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)

func _save() -> bool:
	AffState.data["position"] = [player.position.x, player.position.y]
	var ok := AffState.save_game()
	if not ok:
		hud.notify("Could not save. Check file permissions.")
	return ok

func leave() -> void:
	if not _save():
		return
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/affinix/menu.tscn")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(player) and is_instance_valid(hud):
		_save()

func _draw() -> void:
	if placing >= 0 and is_instance_valid(player):
		var p := get_global_mouse_position().snapped(Vector2(16,16))
		var valid := player.position.distance_to(p) <= 90 and not world.is_water(p)
		draw_circle(p, 10.0, Color(0.6,1,0.7,0.45) if valid else Color(1,0.5,0.4,0.45))
		draw_line(p, p + Vector2.RIGHT.rotated(rotation_step * PI / 2.0) * 14, Color.WHITE, 2)
