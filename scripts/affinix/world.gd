extends Node2D
const Visual = preload("res://scripts/affinix/world_visual.gd")
const Terrain = preload("res://scripts/affinix/terrain.gd")
## Six fixed regions with authored landmarks and deterministic resource placement.
const CELL := 16
const WIDTH := 120
const HEIGHT := 80
const REGIONS := ["Whispering Forest", "Crystal Lake", "Autumn Valley", "Forgotten Village", "Secret Underground", "Misty Mountains"]
var objects: Array[Dictionary] = []
var animals: Array[Dictionary] = []
var hero: CharacterBody2D
var obstacles: Dictionary = {}
var visuals: Dictionary = {}
var visual_root: Node2D
var building_signature := ""

func _ready() -> void:
	var ground := Terrain.new()
	ground.name = "Terrain"
	add_child(ground)
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
	# A convex ellipse follows the lake instead of stair-stepped collision rectangles.
	var water_shape := ConvexPolygonShape2D.new()
	var points := PackedVector2Array()
	for i in range(64):
		var angle := TAU * float(i) / 64.0
		points.append(Vector2(cos(angle) * 160.0, sin(angle) * 128.0))
	water_shape.points = points
	var water_collision := CollisionShape2D.new()
	water_collision.position = Vector2(992, 320)
	water_collision.shape = water_shape
	body.add_child(water_collision)
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
	for i in range(24):
		var angle := TAU * float(i) / 24.0
		var p := Vector2(992 + cos(angle) * 173, 320 + sin(angle) * 139)
		if p.distance_to(Vector2(816, 320)) < 40:
			continue
		var reed := Visual.new()
		reed.setup({"id":"reed_%d" % i, "kind":"reed", "pos":p}, self)
		root.add_child(reed)
	for i in range(7):
		var angle := TAU * (float(i) + 0.5) / 7.0
		var p := Vector2(992 + cos(angle) * 180, 320 + sin(angle) * 148)
		if p.distance_to(Vector2(816, 320)) < 40:
			continue
		var shore_rock := Visual.new()
		shore_rock.setup({"id":"shore_rock_%d" % i, "kind":"stone", "pos":p}, self)
		root.add_child(shore_rock)
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
