extends Node2D
## Deterministic horizontally streamed world. Only edits are saved.

const Chunk = preload("res://scripts/survival/chunk.gd")
const Player = preload("res://scripts/survival/player.gd")
const HUD = preload("res://scripts/survival/hud.gd")
const SAVE_PATH := "user://orma_world_v1.json"
const CELL := 32
const CHUNK_WIDTH := 16
const TOP := -12
const BOTTOM := 26
const REACH := 145.0
const AIR := 0
const GRASS := 1
const DIRT := 2
const STONE := 3
const WOOD := 4
const LEAVES := 5
const BERRY := 6
const PLANK := 7
const BRICK := 8
const ITEMS := ["dirt", "stone", "wood", "plank", "berry", "brick"]
const ITEM_NAMES := {"dirt": "Топырақ", "stone": "Тас", "wood": "Ағаш", "plank": "Тақтай", "berry": "Жидек", "brick": "Кірпіш"}
const ITEM_TILES := {"dirt": DIRT, "stone": STONE, "wood": WOOD, "plank": PLANK, "brick": BRICK}

var world_seed := 1
var changes: Dictionary = {}
var inventory: Dictionary = {"dirt": 0, "stone": 0, "wood": 0, "plank": 0, "berry": 2, "brick": 0}
var chunks: Dictionary = {}
var player: Player
var hud: HUD
var health := 100.0
var hunger := 100.0
var day_time := 0.23
var selected := 0
var autosave_timer := 0.0
var message_timer := 0.0
var is_paused := false
var inventory_open := false
var save_enabled := true
var last_center_chunk := 999999

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_inputs()
	world_seed = randi_range(1, 100000)
	var is_new: bool = bool(get_tree().get_meta("orma_new_world", true))
	get_tree().set_meta("orma_new_world", false)
	var loaded := false
	if not is_new:
		loaded = _load_world()
		if not loaded:
			save_enabled = false
	_create_background()
	player = Player.new()
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	player.z_index = 5
	player.position = Vector2(16, (surface(0) - 2) * CELL)
	if loaded and _saved_position.size() == 2:
		player.position = Vector2(float(_saved_position[0]), float(_saved_position[1]))
	add_child(player)
	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.zoom = Vector2(1, 1)
	player.add_child(camera)
	_update_chunks(true)
	var layer := CanvasLayer.new()
	layer.layer = 10
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	hud = HUD.new()
	hud.world = self
	layer.add_child(hud)
	hud.refresh()
	if is_new and not _save_world():
		hud.notify("Әлемді сақтау мүмкін болмады")
	if not is_new and not loaded:
		hud.notify("Сақталған әлем оқылмады. Жаңа әлем уақытша ашылды.")

var _saved_position: Array = []
var _night_shade: ColorRect

func _create_background() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)
	var background := TextureRect.new()
	background.texture = preload("res://assets/fantasy/background.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(background)
	_night_shade = ColorRect.new()
	_night_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_night_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_night_shade)

func _setup_inputs() -> void:
	_add_keys("orma_left", [KEY_A, KEY_LEFT])
	_add_keys("orma_right", [KEY_D, KEY_RIGHT])
	_add_keys("orma_jump", [KEY_SPACE, KEY_W, KEY_UP])

func _add_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for code in keys:
		var event := InputEventKey.new()
		event.physical_keycode = code
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)

func _process(delta: float) -> void:
	if is_paused:
		return
	day_time = fposmod(day_time + delta / 720.0, 1.0)
	var darkness := clampf((cos(day_time * TAU) + 0.1) * 0.48, 0.0, 0.45)
	_night_shade.color = Color(0.08, 0.10, 0.24, darkness)
	hunger = maxf(0.0, hunger - delta * 0.14)
	if hunger <= 0.0:
		health = maxf(0.0, health - delta * 1.0)
	elif hunger > 65.0:
		health = minf(100.0, health + delta * 0.08)
	if health <= 0.0:
		_respawn()
	_update_chunks(false)
	autosave_timer += delta
	if autosave_timer >= 30.0:
		autosave_timer = 0.0
		_save_world()
	message_timer += delta
	if message_timer > 0.25:
		message_timer = 0.0
		hud.refresh_stats()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE:
				if inventory_open:
					set_inventory(false)
				else:
					set_pause(not is_paused)
				get_viewport().set_input_as_handled()
			KEY_E:
				if not is_paused:
					set_inventory(not inventory_open)
			KEY_F:
				if not is_paused and not inventory_open:
					eat_berry()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6:
				if not is_paused and not inventory_open:
					selected = int(event.physical_keycode - KEY_1)
					hud.refresh()
	if event is InputEventMouseButton and event.pressed and not is_paused and not inventory_open:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_mine()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_place()

func surface(x: int) -> int:
	return int(round(2.0 * sin((x + world_seed * 0.03) * 0.08) + sin((x + world_seed) * 0.033)))

func _noise(x: int, salt: int) -> int:
	return posmod(x * 73 + world_seed * 37 + salt * 101, 997)

func _tree_at(x: int) -> bool:
	return abs(x) > 4 and posmod(x, 7) == 0 and _noise(x, 11) % 4 != 0

func _key(x: int, y: int) -> String:
	return "%d,%d" % [x, y]

func get_cell(x: int, y: int) -> int:
	if y < TOP or y > BOTTOM:
		return AIR
	var key := _key(x, y)
	if changes.has(key):
		return int(changes[key])
	var ground := surface(x)
	if y == ground:
		return GRASS
	if y > ground and y <= ground + 3:
		return DIRT
	if y > ground + 3:
		return STONE
	if _tree_at(x) and y >= ground - 4 and y < ground:
		return WOOD
	# Leaf crowns are separate non-solid tiles and may cross chunk boundaries.
	for tx in range(x - 2, x + 3):
		if _tree_at(tx):
			var crown := surface(tx) - 5
			if abs(x - tx) <= 2 and abs(y - crown) <= 1:
				return LEAVES
			if abs(x - tx) <= 1 and y == crown - 2:
				return LEAVES
	if y == ground - 1 and not _tree_at(x) and _noise(x, 9) % 6 == 0:
		return BERRY
	return AIR

func is_solid(tile: int) -> bool:
	return tile in [GRASS, DIRT, STONE, WOOD, PLANK, BRICK]

func _update_chunks(force: bool) -> void:
	var center := floori(player.global_position.x / float(CELL * CHUNK_WIDTH))
	if not force and center == last_center_chunk:
		return
	last_center_chunk = center
	for existing in chunks.keys():
		if absi(int(existing) - center) > 3:
			var old: Node = chunks[existing]
			remove_child(old)
			old.queue_free()
			chunks.erase(existing)
	for index in range(center - 3, center + 4):
		if not chunks.has(index):
			_create_chunk(index)

func _create_chunk(index: int) -> void:
	var chunk := Chunk.new()
	chunk.world = self
	chunk.chunk_x = index
	chunk.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(chunk)
	chunk.build()
	chunks[index] = chunk

func _set_cell(x: int, y: int, tile: int) -> void:
	changes[_key(x, y)] = tile
	var index := floori(float(x) / CHUNK_WIDTH)
	if chunks.has(index):
		var old: Node = chunks[index]
		remove_child(old)
		old.queue_free()
		chunks.erase(index)
		_create_chunk(index)

func _target_cell() -> Vector2i:
	var p := get_global_mouse_position()
	return Vector2i(floori(p.x / CELL), floori(p.y / CELL))

func _within_reach(cell: Vector2i) -> bool:
	return player.global_position.distance_to(Vector2(cell.x * CELL + CELL / 2.0, cell.y * CELL + CELL / 2.0)) <= REACH

func _mine() -> void:
	var pos := _target_cell()
	if not _within_reach(pos) or pos.y >= BOTTOM:
		return
	var tile := get_cell(pos.x, pos.y)
	var item := ""
	match tile:
		GRASS, DIRT: item = "dirt"
		STONE: item = "stone"
		WOOD: item = "wood"
		BERRY: item = "berry"
		PLANK: item = "plank"
		BRICK: item = "brick"
		LEAVES: pass
		_: return
	_set_cell(pos.x, pos.y, AIR)
	if item != "":
		inventory[item] = int(inventory[item]) + 1
	hud.refresh()

func _place() -> void:
	var pos := _target_cell()
	if not _within_reach(pos) or pos.y < TOP or pos.y >= BOTTOM or get_cell(pos.x, pos.y) != AIR:
		return
	var item: String = ITEMS[selected]
	if not ITEM_TILES.has(item) or int(inventory[item]) <= 0:
		hud.notify("Блок таңда: 1–4 немесе 6")
		return
	var block := Rect2(pos.x * CELL, pos.y * CELL, CELL, CELL)
	var body := Rect2(player.global_position - Vector2(11, 17), Vector2(22, 34))
	if block.intersects(body):
		return
	var attached := false
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if is_solid(get_cell(pos.x + offset.x, pos.y + offset.y)):
			attached = true
			break
	if not attached:
		hud.notify("Блокты басқа блокқа жалға")
		return
	_set_cell(pos.x, pos.y, int(ITEM_TILES[item]))
	inventory[item] = int(inventory[item]) - 1
	hud.refresh()

func craft_planks() -> void:
	if int(inventory["wood"]) < 1:
		hud.notify("1 ағаш қажет")
		return
	inventory["wood"] = int(inventory["wood"]) - 1
	inventory["plank"] = int(inventory["plank"]) + 4
	hud.notify("4 тақтай жасалды")
	hud.refresh()

func craft_bricks() -> void:
	if int(inventory["stone"]) < 2:
		hud.notify("2 тас қажет")
		return
	inventory["stone"] = int(inventory["stone"]) - 2
	inventory["brick"] = int(inventory["brick"]) + 4
	hud.notify("4 кірпіш жасалды")
	hud.refresh()

func eat_berry() -> void:
	if int(inventory["berry"]) <= 0:
		hud.notify("Жидек жоқ")
		return
	if hunger >= 100.0:
		hud.notify("Қарның тоқ")
		return
	inventory["berry"] = int(inventory["berry"]) - 1
	hunger = minf(100.0, hunger + 20.0)
	hud.notify("Жидек жедің  +20")
	hud.refresh()

func _respawn() -> void:
	health = 100.0
	hunger = 75.0
	player.position = Vector2(16, (surface(0) - 2) * CELL)
	player.velocity = Vector2.ZERO
	hud.notify("Қайта оралдың. Әлемің сақталды.")
	_update_chunks(true)

func set_inventory(value: bool) -> void:
	inventory_open = value
	player.controls_enabled = not value
	hud.set_inventory_visible(value)

func set_pause(value: bool) -> void:
	is_paused = value
	get_tree().paused = value
	hud.set_pause_visible(value)

func save_and_menu() -> void:
	if not save_enabled:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/survival_menu.tscn")
		return
	if not _save_world():
		hud.notify("Сақтау мүмкін болмады. Дискті тексер.")
		return
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/survival_menu.tscn")

func _save_world() -> bool:
	if not save_enabled:
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	var data := {"version": 1, "seed": world_seed, "changes": changes, "inventory": inventory, "health": health, "hunger": hunger, "day_time": day_time, "selected": selected, "position": [player.position.x, player.position.y]}
	file.store_string(JSON.stringify(data))
	return file.get_error() == OK

func _load_world() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or int(data.get("version", 0)) != 1:
		return false
	if not data.get("changes", {}) is Dictionary or not data.get("inventory", {}) is Dictionary:
		return false
	world_seed = int(data.get("seed", 1))
	changes = data.get("changes", {})
	var saved_inventory: Dictionary = data.get("inventory", {})
	for item in ITEMS:
		inventory[item] = maxi(0, int(saved_inventory.get(item, 0)))
	health = clampf(float(data.get("health", 100)), 1.0, 100.0)
	hunger = clampf(float(data.get("hunger", 100)), 0.0, 100.0)
	day_time = fposmod(float(data.get("day_time", 0.23)), 1.0)
	selected = clampi(int(data.get("selected", 0)), 0, ITEMS.size() - 1)
	var pos = data.get("position", [])
	if pos is Array:
		_saved_position = pos
	return true

func _draw() -> void:
	if not is_instance_valid(player) or inventory_open or is_paused:
		return
	var pos := _target_cell()
	if _within_reach(pos):
		draw_rect(Rect2(pos.x * CELL + 1, pos.y * CELL + 1, CELL - 2, CELL - 2), Color(1, 0.95, 0.75, 0.8), false, 2.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(player):
		_save_world()
