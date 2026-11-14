extends Node2D
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

func _ready() -> void:
	build_map()
	AffState.changed.connect(queue_redraw)
	AffState.changed.connect(_sync_obstacles)

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

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	var camera := get_viewport().get_camera_2d()
	var center := camera.get_screen_center_position() if camera else Vector2(288,320)
	var left := maxi(0, floori((center.x - 350) / CELL))
	var right := mini(WIDTH, ceili((center.x + 350) / CELL))
	var top := maxi(0, floori((center.y - 200) / CELL))
	var bottom := mini(HEIGHT, ceili((center.y + 200) / CELL))
	for y in range(top, bottom):
		for x in range(left, right):
			var p := Vector2(x * CELL, y * CELL)
			var biome := region(p)
			var texture: Texture2D = GRASS
			match biome:
				"Autumn Valley": texture = AUTUMN
				"Forgotten Village": texture = VILLAGE
				"Secret Underground": texture = CAVE
				"Misty Mountains": texture = MOUNTAIN
			if is_water(p + Vector2(8, 8)):
				texture = WATER
			draw_texture_rect(texture, Rect2(p, Vector2(CELL, CELL)), false)
			if (x * 31 + y * 17) % 23 == 0 and texture != WATER:
				draw_rect(Rect2(p + Vector2(5, 6), Vector2(2, 2)), Color("#d7d4aa"))
	# Village landmarks and resources.
	for o in objects:
		if not active(o):
			continue
		var p: Vector2 = o["pos"]
		if absf(p.x - center.x) > 390 or absf(p.y - center.y) > 245:
			continue
		match o["kind"]:
			"home": draw_texture_rect(CABIN, Rect2(p + Vector2(-40,-56), Vector2(80,64)), false)
			"tree": draw_texture_rect(DARK_TREE if region(p) == "Autumn Valley" else TREE, Rect2(p + Vector2(-24,-54), Vector2(48,60)), false)
			"stone", "mineral", "crystal": draw_texture_rect(ROCK, Rect2(p + Vector2(-12,-15), Vector2(24,18)), false, Color("#c5c8ee") if o["kind"] == "crystal" else Color.WHITE)
			"berry": draw_texture_rect(BERRY, Rect2(p + Vector2(-12,-16), Vector2(24,18)), false)
			"mushroom": draw_texture_rect(MUSHROOM, Rect2(p + Vector2(-8,-14), Vector2(16,16)), false)
			"npc": draw_texture_rect(NPC, Rect2(p + Vector2(-12,-27), Vector2(24,30)), false)
			"branch": draw_line(p + Vector2(-6,-2), p + Vector2(6,-4), Color("#5f4939"), 3.0)
			"leaves", "herb": draw_texture_rect(BERRY, Rect2(p + Vector2(-8,-12), Vector2(16,14)), false, Color("#b0dba5"))
			"note", "board": draw_texture_rect(CHEST, Rect2(p + Vector2(-12,-16), Vector2(24,18)), false)
	for building in AffState.data["buildings"]:
		var p := Vector2(float(building["x"]), float(building["y"]))
		var kind: String = building["id"]
		if kind == "campfire":
			draw_texture_rect(FIRE, Rect2(p + Vector2(-10,-16), Vector2(20,18)), false)
		elif kind == "chest":
			draw_texture_rect(CHEST, Rect2(p + Vector2(-12,-17), Vector2(24,18)), false)
		elif kind == "tent":
			draw_colored_polygon(PackedVector2Array([p + Vector2(-14,0),p + Vector2(0,-22),p + Vector2(14,0)]), Color("#d4c49e"))
			draw_line(p + Vector2(0,-22), p, Color("#5d5444"), 2)
		else:
			var direction := Vector2(9, 0).rotated(float(building.get("rotation", 0)) * PI / 2.0)
			draw_line(p - direction, p + direction, Color("#c1a276"), 3)
	for animal in animals:
		var p: Vector2 = animal["origin"] + Vector2(sin(time * 0.5 + float(animal["phase"])) * 8, cos(time * 0.4 + float(animal["phase"])) * 5)
		if hero and p.distance_to(hero.position) < 40:
			p += (p - hero.position).normalized() * 10
		var tex: Texture2D = RABBIT if animal["kind"] == "rabbit" else FOX if animal["kind"] == "fox" else BIRD
		draw_texture_rect(tex, Rect2(p + Vector2(-8,-12), Vector2(16,16)), false)

	var weather: String = str(AffState.data["weather"])
	if weather == "Rain":
		for i in range(45):
			var x := fposmod(i * 73.0 + time * 40.0, 700.0) + center.x - 350.0
			var y := fposmod(i * 59.0 + time * 100.0, 400.0) + center.y - 200.0
			draw_line(Vector2(x, y), Vector2(x - 2, y + 6), Color(0.8, 0.9, 0.9, 0.5), 1.0)
	if weather == "Fog":
		draw_rect(Rect2(center - Vector2(350, 200), Vector2(700,400)), Color(0.85,0.9,0.86,0.14))

	if region(center) == "Misty Mountains" and weather in ["Rain", "Wind"]:
		for i in range(32):
			var x := fposmod(i * 61.0 + time * 8.0, 700.0) + center.x - 350.0
			var y := fposmod(i * 83.0 + time * 18.0, 400.0) + center.y - 200.0
			draw_circle(Vector2(x, y), 1.0, Color(0.95, 0.98, 1, 0.8))
