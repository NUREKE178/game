extends Node2D
## A chunk owns its terrain visuals and collision. Coordinates remain global.

const CELL := 32
const WIDTH := 16
const TOP := -12
const BOTTOM := 26
var world
var chunk_x: int
var textures := {
	1: preload("res://assets/fantasy/grass.png"),
	2: preload("res://assets/fantasy/dirt.png"),
	3: preload("res://assets/fantasy/stone.png"),
	4: preload("res://assets/fantasy/wood.png"),
	5: preload("res://assets/fantasy/leaves.png"),
	6: preload("res://assets/fantasy/berry.png"),
	7: preload("res://assets/fantasy/plank.png"),
	8: preload("res://assets/fantasy/brick.png"),
}

func build() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	# Merge adjacent solid cells horizontally to keep collision count modest.
	for y in range(TOP, BOTTOM + 1):
		var x := chunk_x * WIDTH
		var end := x + WIDTH
		while x < end:
			if world.is_solid(world.get_cell(x, y)):
				var start := x
				while x < end and world.is_solid(world.get_cell(x, y)):
					x += 1
				var shape := RectangleShape2D.new()
				shape.size = Vector2((x - start) * CELL, CELL)
				var collider := CollisionShape2D.new()
				collider.shape = shape
				collider.position = Vector2((start + x) * CELL * 0.5, (y + 0.5) * CELL)
				body.add_child(collider)
			else:
				x += 1
	queue_redraw()

func _draw() -> void:
	for y in range(TOP, BOTTOM + 1):
		for x in range(chunk_x * WIDTH, (chunk_x + 1) * WIDTH):
			var tile: int = world.get_cell(x, y)
			if textures.has(tile):
				draw_texture_rect(textures[tile], Rect2(x * CELL, y * CELL, CELL, CELL), false)
