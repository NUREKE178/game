extends Node3D
## A small, handcrafted procedural island survival vertical slice.

const Player = preload("res://scripts/island/player.gd")
const Hud = preload("res://scripts/island/hud.gd")
const SAVE_PATH := "user://ashore_save_v1.json"
const MAP_HALF := 140.0
const GRID_SIZE := 141
const STEP := 2.0
const POND := Vector2(13, 2)
const RESOURCES := {"stick": "Stick", "stone": "Stone", "berry": "Berries"}
var noise := FastNoiseLite.new()
var player: Player
var hud: Hud
var sun: DirectionalLight3D
var resource_nodes: Array[Node3D] = []
var structures: Array = []
var gathered: Dictionary = {}
var inventory: Dictionary = {"stick": 0, "stone": 0, "berry": 2, "water": 1}
var health := 100.0
var hunger := 100.0
var thirst := 100.0
var day_time := 0.25
var target: Node3D
var pond_target := false
var intro := false
var intro_time := 0.0
var intro_cabin: Node3D
var paused := false
var crafting := false
var save_enabled := true
var autosave := 0.0
var refresh_time := 0.0
var saved_position: Array = []
var seed := 771927

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	noise.seed = seed
	noise.frequency = 0.023
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.5
	var fresh: bool = bool(get_tree().get_meta("ashore_new", true))
	get_tree().set_meta("ashore_new", false)
	if not fresh and not _load_save():
		save_enabled = false
	_build_environment()
	_build_terrain()
	_build_landscape()
	_build_resources()
	_build_pond()
	_build_wreck()
	for entry in structures:
		if entry is Dictionary and entry.has("type"):
			_add_structure(str(entry["type"]), Vector3(float(entry.get("x", 0)), 0, float(entry.get("z", 0))))
	player = Player.new()
	player.world = self
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	player.position = Vector3(4, height_at(4, 84) + 0.1, 84)
	if saved_position.size() == 3:
		player.position = Vector3(float(saved_position[0]), float(saved_position[1]), float(saved_position[2]))
	add_child(player)
	Preferences.apply_graphics(get_viewport(), sun, player.camera)
	var layer := CanvasLayer.new()
	layer.layer = 10
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	hud = Hud.new()
	hud.world = self
	layer.add_child(hud)
	if fresh:
		_start_intro()
	else:
		player.enabled = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if not save_enabled:
			hud.notify("Save could not be read. Returning to menu will not overwrite it.")
	hud.refresh()

func _setup_input() -> void:
	_add_action("island_left", [KEY_A, KEY_LEFT])
	_add_action("island_right", [KEY_D, KEY_RIGHT])
	_add_action("island_forward", [KEY_W, KEY_UP])
	_add_action("island_back", [KEY_S, KEY_DOWN])
	_add_action("island_jump", [KEY_SPACE])
	_add_action("island_sprint", [KEY_SHIFT])

func _add_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for code in keys:
		var event := InputEventKey.new()
		event.physical_keycode = code
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)

func height_at(x: float, z: float) -> float:
	var distance := Vector2(x, z).length()
	var coast_noise := noise.get_noise_2d(x * 0.6 + 400.0, z * 0.6 + 400.0) * 10.0
	var coast := 1.0 - smoothstep(90.0, 118.0, distance + coast_noise)
	var rolling := 5.8 + noise.get_noise_2d(x, z) * 4.2
	var base := coast * maxf(2.3, rolling) - 1.1
	var pond_distance := Vector2(x - POND.x, z - POND.y).length()
	var pond_flat := 1.0 - smoothstep(3.2, 6.0, pond_distance)
	var pond_height := maxf(2.3, 5.8 + noise.get_noise_2d(POND.x, POND.y) * 4.2) - 1.1
	return lerpf(base, pond_height, pond_flat)

func _build_environment() -> void:
	var environment := Environment.new()
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#47738b")
	sky_material.sky_horizon_color = Color("#c7c9bb")
	sky_material.ground_bottom_color = Color("#354446")
	sky_material.ground_horizon_color = Color("#a9b4ac")
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.75
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("#9eaead")
	environment.fog_density = 0.0025
	var env_node := WorldEnvironment.new()
	env_node.environment = environment
	add_child(env_node)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -35, 0)
	sun.light_color = Color("#fff0d4")
	sun.light_energy = 1.1
	add_child(sun)

func _build_terrain() -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for z in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var px := -MAP_HALF + x * STEP
			var pz := -MAP_HALF + z * STEP
			var y := height_at(px, pz)
			vertices.append(Vector3(px, y, pz))
			uvs.append(Vector2(px / 6.0, pz / 6.0))
			var dx := height_at(px + 0.5, pz) - height_at(px - 0.5, pz)
			var dz := height_at(px, pz + 0.5) - height_at(px, pz - 0.5)
			normals.append(Vector3(-dx, 1.0, -dz).normalized())
			var variation := noise.get_noise_2d(px * 2.5, pz * 2.5) * 0.06
			var color := Color(0.27 + variation, 0.34 + variation, 0.23 + variation)
			if y < 1.2:
				color = Color(0.59 + variation, 0.55 + variation, 0.44 + variation)
			elif y > 6.8:
				color = Color(0.34 + variation, 0.36 + variation, 0.31 + variation)
			colors.append(color)
	for z in range(GRID_SIZE - 1):
		for x in range(GRID_SIZE - 1):
			var a := z * GRID_SIZE + x
			var b := a + 1
			var c := a + GRID_SIZE
			var d := c + 1
			indices.append(a)
			indices.append(c)
			indices.append(b)
			indices.append(b)
			indices.append(c)
			indices.append(d)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var terrain := ArrayMesh.new()
	terrain.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := ShaderMaterial.new()
	material.shader = preload("res://scripts/island/terrain.gdshader")
	material.set_shader_parameter("forest_ground", preload("res://assets/island/ground_grass.png"))
	terrain.surface_set_material(0, material)
	var mesh := MeshInstance3D.new()
	mesh.mesh = terrain
	add_child(mesh)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var collision := CollisionShape3D.new()
	collision.shape = terrain.create_trimesh_shape()
	body.add_child(collision)
	add_child(body)
	var ocean := MeshInstance3D.new()
	var ocean_mesh := PlaneMesh.new()
	ocean_mesh.size = Vector2(1500, 1500)
	ocean.mesh = ocean_mesh
	ocean.position.y = -0.1
	var water := StandardMaterial3D.new()
	water.albedo_color = Color("#4f777c")
	water.metallic = 0.15
	water.roughness = 0.25
	ocean.material_override = water
	add_child(ocean)

func _material(color: Color, roughness: float = 1.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _mesh(parent: Node3D, mesh: Mesh, position: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = position
	node.material_override = material
	parent.add_child(node)
	return node

func _cylinder(radius: float, height: float, top_radius: float = -1.0) -> CylinderMesh:
	var result := CylinderMesh.new()
	result.bottom_radius = radius
	result.top_radius = radius if top_radius < 0.0 else top_radius
	result.height = height
	result.radial_segments = 8
	return result

func _build_landscape() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + 17
	var bark := _material(Color("#b6a89a"))
	bark.albedo_texture = preload("res://assets/island/bark.png")
	var leaves := [_material(Color("#394f3b")), _material(Color("#435d46")), _material(Color("#354b43"))]
	for i in range(170):
		var x := rng.randf_range(-100, 100)
		var z := rng.randf_range(-100, 100)
		var h := height_at(x, z)
		if h < 1.4 or Vector2(x, z).length() > 102 or Vector2(x - POND.x, z - POND.y).length() < 8.0:
			continue
		if Vector2(x - 4, z - 84).length() < 8:
			continue
		var tree := Node3D.new()
		tree.position = Vector3(x, h - 0.3, z)
		add_child(tree)
		var size := rng.randf_range(6.5, 11.5)
		_mesh(tree, _cylinder(0.23, size * 0.72, 0.15), Vector3(0, size * 0.36, 0), bark)
		var foliage: Material = leaves[rng.randi_range(0, leaves.size() - 1)]
		for tier in range(3):
			var crown := _cylinder(1.8 - tier * 0.35, 4.0, 0.04)
			_mesh(tree, crown, Vector3(0, size * 0.49 + tier * 1.3, 0), foliage)
		var static_body := StaticBody3D.new()
		static_body.collision_layer = 1
		var collision := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = 0.28
		shape.height = size * 0.7
		collision.shape = shape
		collision.position.y = size * 0.35
		static_body.add_child(collision)
		tree.add_child(static_body)

func _build_resources() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + 432
	var kinds := ["stick", "stone", "berry"]
	for i in range(125):
		var x := rng.randf_range(-96, 96)
		var z := rng.randf_range(-96, 96)
		# Guaranteed starter supplies near the wreck; IDs remain stable across saves.
		if i < 9:
			x = 4.0 + (i % 3 - 1) * 2.3
			z = 81.0 - floori(float(i) / 3.0) * 2.3
		var y := height_at(x, z)
		if y < 0.4 or Vector2(x, z).length() > 101:
			continue
		var key := str(i)
		if gathered.has(key):
			continue
		var kind: String = kinds[i % kinds.size()]
		var node := Node3D.new()
		node.position = Vector3(x, y, z)
		node.set_meta("id", key)
		node.set_meta("kind", kind)
		add_child(node)
		resource_nodes.append(node)
		if kind == "stick":
			var stick := _mesh(node, _cylinder(0.08, 0.9), Vector3(0, 0.12, 0), _material(Color("#79614c")))
			stick.rotation_degrees.z = 82
		elif kind == "stone":
			var sphere := SphereMesh.new()
			sphere.radius = 0.25
			sphere.height = 0.36
			_mesh(node, sphere, Vector3(0, 0.16, 0), _material(Color("#858984")))
		else:
			var leaves := SphereMesh.new()
			leaves.radius = 0.42
			leaves.height = 0.5
			_mesh(node, leaves, Vector3(0, 0.25, 0), _material(Color("#4e7047")))
			var berry := SphereMesh.new()
			berry.radius = 0.11
			berry.height = 0.22
			for n in range(4):
				_mesh(node, berry, Vector3(cos(n * 1.7) * 0.25, 0.43, sin(n * 1.7) * 0.25), _material(Color("#b54b4f")))

func _build_pond() -> void:
	var pond := Node3D.new()
	pond.position = Vector3(POND.x, height_at(POND.x, POND.y) + 0.1, POND.y)
	add_child(pond)
	_mesh(pond, _cylinder(3.0, 0.08), Vector3.ZERO, _material(Color("#72979a"), 0.2))
	var ring := _cylinder(3.3, 0.08)
	_mesh(pond, ring, Vector3(0, -0.08, 0), _material(Color("#777962")))

func _build_wreck() -> void:
	var wreck := Node3D.new()
	wreck.position = Vector3(1, height_at(1, 88) + 0.75, 88)
	wreck.rotation_degrees.y = 30
	add_child(wreck)
	var metal := _material(Color("#788081"), 0.7)
	var hull := _mesh(wreck, _cylinder(0.8, 5.0, 0.7), Vector3(0, 0.3, 0), metal)
	hull.rotation_degrees.x = 90
	hull.rotation_degrees.z = 8
	var wing := BoxMesh.new()
	wing.size = Vector3(7, 0.12, 1.25)
	var wing_node := _mesh(wreck, wing, Vector3(0, 0.0, 0.3), metal)
	wing_node.rotation_degrees.z = 8

func _add_structure(kind: String, pos: Vector3) -> void:
	var structure := Node3D.new()
	structure.position = Vector3(pos.x, height_at(pos.x, pos.z), pos.z)
	structure.set_meta("kind", kind)
	add_child(structure)
	if kind == "fire":
		var stones := _material(Color("#777c76"))
		for i in range(8):
			var rock := SphereMesh.new()
			rock.radius = 0.17
			rock.height = 0.25
			_mesh(structure, rock, Vector3(cos(i * TAU / 8.0) * 0.65, 0.1, sin(i * TAU / 8.0) * 0.65), stones)
		var wood := _material(Color("#6c5040"))
		for i in range(3):
			var log := _mesh(structure, _cylinder(0.1, 1.1), Vector3(0, 0.17, 0), wood)
			log.rotation_degrees = Vector3(75, i * 60, 0)
		_mesh(structure, _cylinder(0.33, 0.85, 0.03), Vector3(0, 0.48, 0), _material(Color("#ef9b42")))
		var light := OmniLight3D.new()
		light.light_color = Color("#ff9b4b")
		light.light_energy = 1.5
		light.omni_range = 7.0
		light.position.y = 1.1
		structure.add_child(light)
	elif kind == "shelter":
		var tarp := _material(Color("#596b58"))
		var roof := PlaneMesh.new()
		roof.size = Vector2(2.5, 2.7)
		for side in [-1, 1]:
			var panel := _mesh(structure, roof, Vector3(side * 0.72, 0.9, 0), tarp)
			panel.rotation_degrees.z = side * 38.0
			panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
		var pole := _mesh(structure, _cylinder(0.07, 2.7), Vector3(0, 1.65, 0), _material(Color("#6b5140")))
		pole.rotation_degrees.x = 90

func craft(kind: String) -> void:
	if intro or not crafting:
		return
	var stick_cost := 3 if kind == "fire" else 5
	var stone_cost := 2 if kind == "fire" else 0
	if int(inventory["stick"]) < stick_cost or int(inventory["stone"]) < stone_cost:
		hud.notify("Not enough resources.")
		return
	var forward := -player.global_transform.basis.z
	var pos := player.global_position + Vector3(forward.x, 0, forward.z).normalized() * 3.0
	if Vector2(pos.x, pos.z).length() > 100.0 or height_at(pos.x, pos.z) < 0.4:
		hud.notify("Build on dry ground.")
		return
	for existing in structures:
		if Vector2(float(existing["x"]) - pos.x, float(existing["z"]) - pos.z).length() < 3.0:
			hud.notify("Choose a clear spot.")
			return
	inventory["stick"] = int(inventory["stick"]) - stick_cost
	inventory["stone"] = int(inventory["stone"]) - stone_cost
	structures.append({"type": kind, "x": pos.x, "z": pos.z})
	_add_structure(kind, pos)
	Sound.play("craft")
	hud.notify("Built " + ("campfire" if kind == "fire" else "shelter") + ".")
	hud.refresh()

func _start_intro() -> void:
	intro = true
	intro_time = 0.0
	player.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	intro_cabin = Node3D.new()
	player.add_child(intro_cabin)
	var interior := _material(Color("#434b4a"))
	var bar := BoxMesh.new()
	bar.size = Vector3(0.18, 2.5, 0.18)
	for side in [-1, 1]:
		_mesh(intro_cabin, bar, Vector3(side * 1.15, 1.65, -1.8), interior)
	var overhead := BoxMesh.new()
	overhead.size = Vector3(2.5, 0.16, 0.2)
	_mesh(intro_cabin, overhead, Vector3(0, 2.65, -1.8), interior)
	var dashboard := BoxMesh.new()
	dashboard.size = Vector3(2.5, 0.25, 0.6)
	_mesh(intro_cabin, dashboard, Vector3(0, 1.03, -1.7), interior)
	Sound.play("crash")
	hud.show_intro(true)

func _finish_intro() -> void:
	intro = false
	if is_instance_valid(intro_cabin):
		intro_cabin.queue_free()
	player.rotation = Vector3.ZERO
	player.camera.rotation = Vector3.ZERO
	player.position = Vector3(4, height_at(4, 84) + 0.1, 84)
	player.velocity = Vector3.ZERO
	player.enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.show_intro(false)
	hud.notify("Find supplies. Look for a freshwater pond inland.")
	if not _save_game():
		hud.notify("Could not save. Check disk permissions.")

func _process(delta: float) -> void:
	if paused:
		return
	if intro:
		intro_time += delta
		var t := clampf(intro_time / 7.0, 0.0, 1.0)
		player.position = Vector3(4, lerpf(68.0, 6.0, t * t), 105.0 - t * 18.0)
		player.rotation.z = sin(intro_time * 13.0) * 0.035 + t * 0.30
		player.camera.rotation.x = -t * 0.35
		hud.update_intro(t)
		if t >= 1.0:
			_finish_intro()
		return
	if not player.enabled and not crafting:
		return
	day_time = fposmod(day_time + delta / 1200.0, 1.0)
	var sun_height := sin(day_time * TAU)
	sun.rotation_degrees.x = -maxf(5.0, sun_height * 55.0)
	sun.light_energy = clampf(0.25 + sun_height, 0.25, 1.2)
	hunger = maxf(0.0, hunger - delta * 0.035)
	thirst = maxf(0.0, thirst - delta * 0.055)
	if hunger <= 0.0 or thirst <= 0.0:
		health = maxf(0.0, health - delta * 0.4)
	elif hunger > 60 and thirst > 60:
		health = minf(100.0, health + delta * 0.025)
	if health <= 0 or player.position.y < -12.0:
		_respawn()
	_update_target()
	autosave += delta
	if autosave >= 30:
		autosave = 0
		if not _save_game() and save_enabled:
			hud.notify("Autosave failed. Check disk permissions.")
	refresh_time += delta
	if refresh_time >= 0.2:
		refresh_time = 0
		hud.refresh()

func _update_target() -> void:
	target = null
	pond_target = false
	if crafting:
		hud.set_prompt("")
		return
	var best := 3.0
	var forward := -player.camera.global_transform.basis.z
	for resource in resource_nodes:
		if not is_instance_valid(resource):
			continue
		var diff: Vector3 = resource.global_position - player.global_position
		var distance := diff.length()
		if distance < best and forward.dot(diff.normalized()) > 0.35:
			best = distance
			target = resource
	if target:
		hud.set_prompt("E   TAKE " + str(RESOURCES[target.get_meta("kind")]).to_upper())
	elif Vector2(player.position.x - POND.x, player.position.z - POND.y).length() < 4.5:
		pond_target = true
		hud.set_prompt("E   COLLECT FRESH WATER")
	else:
		hud.set_prompt("")

func _interact() -> void:
	if target and is_instance_valid(target):
		var kind: String = target.get_meta("kind")
		gathered[str(target.get_meta("id"))] = true
		inventory[kind] = int(inventory[kind]) + 1
		resource_nodes.erase(target)
		target.queue_free()
		target = null
		Sound.play("collect")
		hud.notify("Picked up " + str(RESOURCES[kind]).to_lower())
		hud.refresh()
	elif pond_target:
		if int(inventory["water"]) >= 3:
			hud.notify("Water supply is full.")
		else:
			inventory["water"] = int(inventory["water"]) + 1
			Sound.play("collect")
			hud.notify("Collected fresh water.")
			hud.refresh()

func _consume(item: String) -> void:
	if int(inventory[item]) <= 0:
		hud.notify("No " + item + " left.")
		return
	if item == "berry" and hunger >= 99:
		hud.notify("You are not hungry.")
		return
	if item == "water" and thirst >= 99:
		hud.notify("You are not thirsty.")
		return
	inventory[item] = int(inventory[item]) - 1
	if item == "berry":
		hunger = minf(100.0, hunger + 22.0)
	else:
		thirst = minf(100.0, thirst + 35.0)
	Sound.play("collect")
	hud.refresh()

func _respawn() -> void:
	health = 100
	hunger = 70
	thirst = 70
	player.position = Vector3(4, height_at(4, 84) + 0.2, 84)
	player.velocity = Vector3.ZERO
	hud.notify("You woke up near the wreck. Your supplies remain.")

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if intro:
		if event.physical_keycode == KEY_ESCAPE:
			_finish_intro()
		return
	match event.physical_keycode:
		KEY_ESCAPE:
			if crafting:
				set_crafting(false)
			else:
				set_pause(not paused)
		KEY_C:
			if not paused:
				set_crafting(not crafting)
		KEY_E:
			if not paused and not crafting:
				_interact()
		KEY_R:
			if not paused and not crafting:
				_consume("berry")
		KEY_F:
			if not paused and not crafting:
				_consume("water")

func set_crafting(value: bool) -> void:
	crafting = value
	player.enabled = not value
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED
	hud.set_crafting_visible(value)

func set_pause(value: bool) -> void:
	paused = value
	get_tree().paused = value
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED
	hud.set_pause_visible(value)

func save_and_menu() -> void:
	if save_enabled and not _save_game():
		hud.notify("Save failed. Check disk permissions.")
		return
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/island_menu.tscn")

func _save_game() -> bool:
	if not save_enabled or intro:
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	var data := {"version": 1, "position": [player.position.x, player.position.y, player.position.z], "health": health, "hunger": hunger, "thirst": thirst, "inventory": inventory, "gathered": gathered, "structures": structures, "day_time": day_time}
	file.store_string(JSON.stringify(data))
	return file.get_error() == OK

func _load_save() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or int(data.get("version", 0)) != 1:
		return false
	if not data.get("inventory", {}) is Dictionary or not data.get("gathered", {}) is Dictionary or not data.get("structures", []) is Array:
		return false
	var stored_inventory: Dictionary = data.get("inventory", {})
	for key in inventory:
		inventory[key] = maxi(0, int(stored_inventory.get(key, 0)))
	gathered = data.get("gathered", {})
	structures = data.get("structures", [])
	health = clampf(float(data.get("health", 100)), 1, 100)
	hunger = clampf(float(data.get("hunger", 100)), 0, 100)
	thirst = clampf(float(data.get("thirst", 100)), 0, 100)
	day_time = fposmod(float(data.get("day_time", 0.25)), 1.0)
	if data.get("position", []) is Array:
		saved_position = data.get("position", [])
	return true

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(player) and not intro:
		_save_game()
