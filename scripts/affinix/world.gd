extends Node2D
const Visual = preload("res://scripts/affinix/world_visual.gd")
## Six fixed regions with authored landmarks and deterministic resource placement.
const CELL := 16
const WIDTH := 120
const HEIGHT := 80
const GRASS = preload("res://assets/affinix/grass.png")
const WATER = preload("res://assets/affinix/water.png")
const AUTUMN = preload("res://assets/affinix/autumn.png")
const VILLAGE = preload("res://assets/affinix/village.png")
const CAVE = preload("res://assets/affinix/cave.png")
const MOUNTAIN = preload("res://assets/affinix/mountain.png")
const TREE = preload("res://assets/affinix/tree.png")
const DARK_TREE = preload("res://assets/affinix/dark_tree.png")
const CABIN = preload("res://assets/affinix/cabin.png")
const ROCK = preload("res://assets/affinix/rock.png")
const BERRY = preload("res://assets/affinix/berry_bush.png")
const MUSHROOM = preload("res://assets/affinix/mushroom.png")
const NPC = preload("res://assets/affinix/npc.png")
const FIRE = preload("res://assets/affinix/campfire.png")
const CHEST = preload("res://assets/affinix/chest.png")
const RABBIT = preload("res://assets/affinix/rabbit.png")
const FOX = preload("res://assets/affinix/fox.png")
const BIRD = preload("res://assets/affinix/bird.png")
const REGIONS := ["Whispering Forest", "Crystal Lake", "Autumn Valley", "Forgotten Village", "Secret Underground", "Misty Mountains"]
var objects: Array[Dictionary] = []
var animals: Array[Dictionary] = []
var time := 0.0
var hero: CharacterBody2D
var obstacles: Dictionary = {}
var visuals: Dictionary = {}
var visual_root: Node2D
var building_root: Node2D
var building_signature := ""
var redraw_timer := 0.0
const TILESETS := {
	"Whispering Forest": [preload("res://assets/affinix/forest_0.png"),preload("res://assets/affinix/forest_1.png"),preload("res://assets/affinix/forest_2.png"),preload("res://assets/affinix/forest_3.png")],
	"Crystal Lake": [preload("res://assets/affinix/forest_0.png"),preload("res://assets/affinix/forest_1.png"),preload("res://assets/affinix/forest_2.png"),preload("res://assets/affinix/forest_3.png")],
	"Autumn Valley": [preload("res://assets/affinix/autumn2_0.png"),preload("res://assets/affinix/autumn2_1.png"),preload("res://assets/affinix/autumn2_2.png"),preload("res://assets/affinix/autumn2_3.png")],
	"Forgotten Village": [preload("res://assets/affinix/village2_0.png"),preload("res://assets/affinix/village2_1.png"),preload("res://assets/affinix/village2_2.png"),preload("res://assets/affinix/village2_3.png")],
	"Secret Underground": [preload("res://assets/affinix/cave2_0.png"),preload("res://assets/affinix/cave2_1.png"),preload("res://assets/affinix/cave2_2.png"),preload("res://assets/affinix/cave2_3.png")],
	"Misty Mountains": [preload("res://assets/affinix/mountain2_0.png"),preload("res://assets/affinix/mountain2_1.png"),preload("res://assets/affinix/mountain2_2.png"),preload("res://assets/affinix/mountain2_3.png")],
}
const PATH_TILES = [preload("res://assets/affinix/path_0.png"),preload("res://assets/affinix/path_1.png"),preload("res://assets/affinix/path_2.png"),preload("res://assets/affinix/path_3.png")]
const WATER_TILES = [preload("res://assets/affinix/lake_0.png"),preload("res://assets/affinix/lake_1.png"),preload("res://assets/affinix/lake_2.png"),preload("res://assets/affinix/lake_3.png")]

func _ready() -> void:
	build_map()
	AffState.changed.connect(queue_redraw)
	AffState.changed.connect(_sync_obstacles)
	AffState.changed.connect(refresh_visuals)

func region(pos: Vector2) -> String:
	var col := clampi(floori(pos.x / (40.0 * CELL)), 0, 2)
	var row := 1 if pos.y >= 40 * CELL else 0
	return REGIONS[col + row * 3]

func is_water(pos: Vector2) -> bool:
	var p := Vector2((pos.x / CELL - 62.0) / 10.0, (pos.y / CELL - 20.0) / 8.0)
	return p.length_squared() < 1.0

func add_obj(id: String, kind: String, x: float, y: float) -> void:
	objects.append({"id":id, "kind":kind, "pos":Vector2(x * CELL, y * CELL)})

func build_map() -> void:
	objects.clear()
	add_obj("home", "home", 18, 18)
	add_obj("rowan", "npc", 49, 20)
	add_obj("ada", "npc", 20, 55)
	add_obj("lake", "lake", 51, 20)
	add_obj("note", "note", 25, 55)
	add_obj("board", "board", 24, 58)
	for entry in [["tree",13,18],["tree",23,17],["stone",14,23],["stone",23,23],["berry",16,23],["mushroom",22,25],["branch",17,24],["branch",19,24],["branch",21,24],["leaves",15,25]]:
		add_obj("starter_" + str(objects.size()), str(entry[0]), float(entry[1]), float(entry[2]))
	var rng := RandomNumberGenerator.new()
	rng.seed = 72901
	for y in range(3, HEIGHT - 3, 3):
		for x in range(3, WIDTH - 3, 3):
			if rng.randf() > 0.36 or abs(y - 20) < 2 or abs(y - 60) < 2 or abs(x - 20) < 2 or abs(x - 60) < 2 or abs(x - 100) < 2:
				continue
			var p := Vector2(x * CELL, y * CELL)
			if is_water(p):
				continue
			var near_landmark := false
			for o in objects:
				if p.distance_to(o["pos"]) < 28.0:
					near_landmark = true
					break
			if near_landmark:
				continue
			var roll := rng.randf()
			var kind := "tree"
			var biome := region(p)
			if biome == "Misty Mountains":
				kind = "mineral" if roll < 0.55 else "stone"
			elif biome == "Secret Underground":
				kind = "crystal" if roll < 0.45 else "stone"
			elif roll < 0.2:
				kind = "berry"
			elif roll < 0.35:
				kind = "mushroom"
			elif roll < 0.46:
				kind = "branch"
			elif roll < 0.56:
				kind = "leaves"
			elif roll < 0.63:
				kind = "herb"
			add_obj("cell_%d_%d" % [x, y], kind, x, y)
	# Move after distribution so existing procedural IDs and kinds stay unchanged.
	for o in objects:
		if str(o["id"]).begins_with("cell_"):
			var cell: Vector2 = o["pos"] / CELL
			var jx := float(posmod(int(cell.x) * 19 + int(cell.y) * 7, 7)) - 3.0
			var jy := float(posmod(int(cell.x) * 11 + int(cell.y) * 13, 7)) - 3.0
			o["pos"] += Vector2(jx, jy)
	add_obj("hidden_cache_1", "treasure", 11, 68)
	add_obj("hidden_cache_2", "treasure", 109, 25)
	for i in range(12):
		animals.append({"origin":Vector2(rng.randf_range(40, 1800), rng.randf_range(40, 1200)), "kind":["rabbit", "fox", "bird"][i % 3], "phase":rng.randf_range(0, TAU)})
	_build_collision()

func _build_collision() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	# Merge horizontal runs of lake cells into a small number of shapes.
	for y in range(10, 31):
		var start := -1
		for x in range(48, 76):
			var water := is_water(Vector2((x + 0.5) * CELL, (y + 0.5) * CELL))
			if water and start < 0:
				start = x
			if not water and start >= 0:
				var shape := RectangleShape2D.new()
				shape.size = Vector2((x - start) * CELL, CELL)
				var col := CollisionShape2D.new()
				col.position = Vector2((start + x) * CELL * 0.5, (y + 0.5) * CELL)
				col.shape = shape
				body.add_child(col)
				start = -1
	for o in objects:
		if o["kind"] != "tree":
			continue
		var trunk := CollisionShape2D.new()
		var trunk_shape := CircleShape2D.new()
		trunk_shape.radius = 5.0
		trunk.shape = trunk_shape
		trunk.position = o["pos"]
		body.add_child(trunk)
		obstacles[o["id"]] = trunk
	var cabin_shape := RectangleShape2D.new()
	cabin_shape.size = Vector2(48, 25)
	var cabin_collision := CollisionShape2D.new()
	cabin_collision.shape = cabin_shape
	cabin_collision.position = Vector2(18 * CELL, 18 * CELL - 24)
	body.add_child(cabin_collision)
	_sync_obstacles()
	for data in [{"p":Vector2(960,-10),"s":Vector2(1940,20)}, {"p":Vector2(960,1290),"s":Vector2(1940,20)}, {"p":Vector2(-10,640),"s":Vector2(20,1280)}, {"p":Vector2(1930,640),"s":Vector2(20,1280)}]:
		var boundary := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = data["s"]
		boundary.shape = shape
		boundary.position = data["p"]
		body.add_child(boundary)

func _sync_obstacles() -> void:
	for id in obstacles:
		var shape: CollisionShape2D = obstacles[id]
		var until_day := int(AffState.data["depleted"].get(id, 0))
		shape.set_deferred("disabled", until_day > int(AffState.data["day"]))

func active(o: Dictionary) -> bool:
	return int(AffState.data["depleted"].get(o["id"], 0)) <= int(AffState.data["day"])

func nearest(pos: Vector2) -> Dictionary:
	var best := 28.0
	var result: Dictionary = {}
	for o in objects:
		if not active(o):
			continue
		var distance: float = pos.distance_to(o["pos"])
		if distance < best:
			best = distance
			result = o
	return result

func attach_visuals(root: Node2D) -> void:
	visual_root = root
	for o in objects:
		var sprite := Visual.new()
		sprite.setup(o, self)
		root.add_child(sprite)
		visuals[o["id"]] = sprite
	# Small decorative plants are deliberately non-interactive, not invisible resources.
	for i in range(200):
		var x := 22 + posmod(i * 137 + i * i * 17, 1870)
		var y := 22 + posmod(i * 211 + i * i * 7, 1230)
		var p := Vector2(x, y)
		if is_water(p):
			continue
		var flower := Visual.new()
		flower.setup({"id": "flower_%d" % i, "kind": "flower", "pos": p}, self)
		root.add_child(flower)
	for data in animals:
		var animal := Visual.new()
		animal.setup(data, self, false, true)
		root.add_child(animal)
	# Buildings must share the same y-sort parent as characters and foliage.
	refresh_visuals()

func refresh_visuals() -> void:
	if not is_instance_valid(visual_root):
		return
	for o in objects:
		var item: Node2D = visuals.get(o["id"])
		if is_instance_valid(item):
			item.visible = active(o)
	var signature := JSON.stringify(AffState.data["buildings"])
	if signature == building_signature:
		return
	building_signature = signature
	for child in visual_root.get_children():
		if child.has_meta("aff_building"):
			visual_root.remove_child(child)
			child.queue_free()
	for building in AffState.data["buildings"]:
		var sprite := Visual.new()
		var descriptor: Dictionary = building.duplicate()
		descriptor["pos"] = Vector2(float(building["x"]), float(building["y"]))
		sprite.setup(descriptor, self, true)
		sprite.set_meta("aff_building", true)
		visual_root.add_child(sprite)

func _process(delta: float) -> void:
	time += delta
	redraw_timer += delta
	if redraw_timer >= 0.10:
		redraw_timer = 0.0
		queue_redraw()

func _draw() -> void:
	var camera := get_viewport().get_camera_2d()
	var center := camera.get_screen_center_position() if camera else Vector2(288,320)
	var left := maxi(0, floori((center.x - 360) / CELL))
	var right := mini(WIDTH, ceili((center.x + 360) / CELL))
	var top := maxi(0, floori((center.y - 210) / CELL))
	var bottom := mini(HEIGHT, ceili((center.y + 210) / CELL))
	for y in range(top, bottom):
		for x in range(left, right):
			var p := Vector2(x * CELL, y * CELL)
			var variant := posmod(x * 31 + y * 17 + x * y * 7, 4)
			var tiles: Array = TILESETS[region(p)]
			var texture: Texture2D = tiles[variant]
			var on_path := absi(y - 20) <= 1 or absi(y - 60) <= 1 or absi(x - 20) <= 1 or absi(x - 60) <= 1 or absi(x - 100) <= 1
			if on_path:
				texture = PATH_TILES[variant]
			if is_water(p + Vector2(8, 8)):
				texture = WATER_TILES[(variant + int(time * 0.6)) % 4]
			draw_texture_rect(texture, Rect2(p, Vector2(CELL, CELL)), false)
