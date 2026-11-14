extends Node2D
## One grounded drawable per object so the scene tree can y-sort against Chill Boy.
const TREE = preload("res://assets/affinix/tree.png")
const PINE = preload("res://assets/affinix/pine.png")
const PINE_SMALL = preload("res://assets/affinix/pine_small.png")
const TREE_SMALL = preload("res://assets/affinix/tree_small.png")
const GOLD = preload("res://assets/affinix/golden_tree.png")
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
const LOG = preload("res://assets/affinix/fallen_log.png")
const HERB = preload("res://assets/affinix/herb.png")
const LEAVES = preload("res://assets/affinix/leaf_pile.png")
const REEDS = [preload("res://assets/affinix/reeds_0.png"), preload("res://assets/affinix/reeds_1.png"), preload("res://assets/affinix/reeds_2.png")]
const FLOWERS = [preload("res://assets/affinix/wildflower_cream.png"), preload("res://assets/affinix/wildflower_pink.png"), preload("res://assets/affinix/wildflower_blue.png"), preload("res://assets/affinix/grass_tuft.png")]
var info: Dictionary = {}
var map
var animation_time := 0.0
var original := Vector2.ZERO
var variant := 0
var is_building := false
var is_animal := false

func setup(source: Dictionary, parent_world, building: bool = false, animal: bool = false) -> void:
	info = source.duplicate()
	map = parent_world
	is_building = building
	is_animal = animal
	position = info.get("pos", info.get("origin", Vector2.ZERO))
	original = position
	variant = absi(hash(str(info.get("id", position)))) % 4

func _ready() -> void:
	set_process(is_animal or info.get("kind", "") in ["tree", "flower", "reed"])
	if is_building and info.get("id", "") in ["campfire", "lamp"]:
		_add_light()

func _add_light() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.80, 0.48, 0.75))
	gradient.set_color(1, Color(1.0, 0.6, 0.25, 0.0))
	var texture := GradientTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = gradient
	var light := PointLight2D.new()
	light.texture = texture
	light.color = Color(1.0, 0.76, 0.45)
	light.energy = 0.7
	light.position.y = -10
	add_child(light)

func _process(delta: float) -> void:
	animation_time += delta
	if is_animal:
		var phase: float = float(info.get("phase", 0.0))
		var displacement := Vector2(sin(animation_time * 0.5 + phase) * 8, cos(animation_time * 0.4 + phase) * 5)
		var desired := original + displacement
		if is_instance_valid(map.hero) and desired.distance_to(map.hero.position) < 40:
			desired += (desired - map.hero.position).normalized() * 10
		position = desired
	if info.get("kind", "") in ["tree", "flower", "reed"]:
		rotation = sin(animation_time * 0.8 + variant * 2.0) * (0.009 if info.get("kind", "") == "tree" else 0.025)

func _draw() -> void:
	var kind: String = str(info.get("kind", info.get("id", "")))
	if is_animal:
		var animal_tex: Texture2D = RABBIT if kind == "rabbit" else FOX if kind == "fox" else BIRD
		draw_texture_rect(animal_tex, Rect2(-8,-12,16,16), false)
		return
	if is_building:
		_draw_building(kind)
		return
	if kind in ["tree", "stone", "berry", "npc", "home", "mineral", "crystal"]:
		draw_set_transform(Vector2(0, 1), 0, Vector2(1.5, 0.4))
		draw_circle(Vector2.ZERO, 7.0, Color(0.09, 0.13, 0.10, 0.24))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	match kind:
		"lake":
			draw_circle(Vector2(0, -2), 5, Color(0.55, 0.83, 0.83, 0.7))
			draw_arc(Vector2(0, -2), 7, 0, TAU, 16, Color(0.85, 0.95, 0.89, 0.7), 1.0)
		"home": draw_texture_rect(CABIN, Rect2(-40,-56,80,64), false)
		"tree":
			var tree: Texture2D = GOLD if map.region(position) == "Autumn Valley" else PINE_SMALL if variant == 0 else PINE if variant == 1 else TREE_SMALL if variant == 2 else TREE
			var size := tree.get_size()
			draw_texture_rect(tree, Rect2(-size.x / 2.0, -size.y + 5.0, size.x, size.y), false)
		"stone", "mineral", "crystal": draw_texture_rect(ROCK, Rect2(-12,-15,24,18), false, Color("#c5c8ee") if kind == "crystal" else Color.WHITE)
		"berry": draw_texture_rect(BERRY, Rect2(-12,-16,24,18), false)
		"mushroom": draw_texture_rect(MUSHROOM, Rect2(-8,-14,16,16), false)
		"npc": draw_texture_rect(NPC, Rect2(-12,-27,24,30), false)
		"branch": draw_texture_rect(LOG, Rect2(-8,-14,16,16), false)
		"herb": draw_texture_rect(HERB, Rect2(-8,-14,16,16), false)
		"leaves": draw_texture_rect(LEAVES, Rect2(-8,-14,16,16), false)
		"note", "board", "treasure": draw_texture_rect(CHEST, Rect2(-12,-16,24,18), false)
		"reed": draw_texture_rect(REEDS[variant % 3], Rect2(-8,-19,16,20), false)
		"flower": draw_texture_rect(FLOWERS[variant], Rect2(-8,-15,16,18), false)

func _draw_building(kind: String) -> void:
	match kind:
		"campfire": draw_texture_rect(FIRE, Rect2(-10,-16,20,18), false)
		"chest": draw_texture_rect(CHEST, Rect2(-12,-17,24,18), false)
		"tent":
			draw_colored_polygon(PackedVector2Array([Vector2(-14,0),Vector2(0,-22),Vector2(14,0)]), Color("#d4c49e"))
			draw_line(Vector2(0,-22), Vector2.ZERO, Color("#5d5444"), 2)
		_:
			var direction := Vector2(9, 0).rotated(float(info.get("rotation", 0)) * PI / 2.0)
			draw_line(-direction, direction, Color("#c1a276"), 3)
