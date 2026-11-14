extends CharacterBody2D
signal step_taken
const ATLAS = preload("res://assets/affinix/chill_boy.png")
var input_enabled := true
var facing := 0
var animation_time := 0.0
var step_timer := 0.0
var walking := false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CircleShape2D.new()
	shape.radius = 5.0
	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)
	var camera := Camera2D.new()
	camera.zoom = Vector2(2, 2)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 1920
	camera.limit_bottom = 1280
	add_child(camera)

func _physics_process(delta: float) -> void:
	if not input_enabled:
		velocity = Vector2.ZERO
		walking = false
		return
	var direction := Input.get_vector("aff_left", "aff_right", "aff_up", "aff_down")
	walking = direction.length() > 0.1
	var running := walking and Input.is_action_pressed("aff_run") and float(AffState.data["energy"]) > 4.0
	velocity = direction * (100.0 if running else 65.0)
	if walking:
		if absf(direction.x) > absf(direction.y):
			facing = 2 if direction.x < 0 else 3
		else:
			facing = 1 if direction.y < 0 else 0
		var run_cost := 0.04 if AffState.amount("backpack") > 0 else 0.08
		AffState.data["energy"] = maxf(0.0, float(AffState.data["energy"]) - delta * (run_cost if running else 0.015))
		step_timer -= delta
		if step_timer <= 0.0:
			step_taken.emit()
			step_timer = 0.28 if running else 0.43
	move_and_slide()
	animation_time += delta
	queue_redraw()

func _draw() -> void:
	var frame := int(animation_time * (7.0 if walking else 1.5)) % 4
	draw_texture_rect_region(ATLAS, Rect2(-16, -29, 32, 32), Rect2(frame * 32, facing * 32, 32, 32))
