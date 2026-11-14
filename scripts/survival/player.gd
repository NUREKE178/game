extends CharacterBody2D

const SPIRIT = preload("res://assets/sprites/spirit.png")
const SPEED := 210.0
const JUMP := -520.0
const GRAVITY := 1350.0
var facing := 1.0
var animation_time := 0.0
var controls_enabled := true

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(22, 34)
	collision.shape = shape
	add_child(collision)

func _physics_process(delta: float) -> void:
	animation_time += delta
	var direction := Input.get_axis("orma_left", "orma_right") if controls_enabled else 0.0
	if direction != 0.0:
		facing = signf(direction)
	velocity.x = move_toward(velocity.x, direction * SPEED, 1500.0 * delta)
	velocity.y += GRAVITY * delta
	if controls_enabled and Input.is_action_just_pressed("orma_jump") and is_on_floor():
		velocity.y = JUMP
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	var row := 0
	if not is_on_floor():
		row = 2
	elif absf(velocity.x) > 20.0:
		row = 1
	var frame := int(animation_time * (8.0 if row == 1 else 3.0)) % 4
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
	draw_texture_rect_region(SPIRIT, Rect2(-27, -30, 54, 54), Rect2(frame * 48, row * 48, 48, 48))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
