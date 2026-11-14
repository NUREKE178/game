extends CharacterBody2D
signal step_taken
const ATLAS = preload("res://assets/affinix/chill_boy_v2.png")
var input_enabled := true
var facing := 0
var animation_time := 0.0
var step_timer := 0.0
var walking := false
var running := false
var action_timer := 0.0
var lantern_light: PointLight2D

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
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.87, 0.65, 0.65))
	gradient.set_color(1, Color(1.0, 0.73, 0.45, 0.0))
	var texture := GradientTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = gradient
	lantern_light = PointLight2D.new()
	lantern_light.texture = texture
	lantern_light.color = Color(1.0, 0.82, 0.57)
	lantern_light.energy = 0.65
	lantern_light.position.y = -10
	add_child(lantern_light)

func _physics_process(delta: float) -> void:
	lantern_light.visible = AffState.amount("lantern") > 0
	if not input_enabled:
		velocity = Vector2.ZERO
		walking = false
		action_timer = maxf(0.0, action_timer - delta)
		queue_redraw()
		return
	var direction := Input.get_vector("aff_left", "aff_right", "aff_up", "aff_down")
	walking = direction.length() > 0.1
	running = walking and Input.is_action_pressed("aff_run") and float(AffState.data["energy"]) > 4.0
	velocity = velocity.move_toward(direction * (100.0 if running else 65.0), 500.0 * delta)
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
	action_timer = maxf(0.0, action_timer - delta)
	queue_redraw()

func interact_animation() -> void:
	action_timer = 0.35

func _draw() -> void:
	draw_set_transform(Vector2(0, 1), 0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 7.0, Color(0.08, 0.12, 0.09, 0.28))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var frame := int(animation_time * (12.0 if running else 8.0)) % 8 if walking else 0
	var action_offset := -2.0 * sin((0.35 - action_timer) / 0.35 * PI) if action_timer > 0.0 else 0.0
	draw_texture_rect_region(ATLAS, Rect2(-16, -29 + action_offset, 32, 32), Rect2(frame * 32, facing * 32, 32, 32))
