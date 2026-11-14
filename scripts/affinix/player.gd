extends CharacterBody2D
signal step_taken
const ATLAS = preload("res://assets/affinix/chill_boy_states.png")
var input_enabled := true
var facing := 0
var animation_time := 0.0
var step_timer := 0.0
var walking := false
var running := false
var action_timer := 0.0
var action_duration := 0.5
var action_state := "interact"
var fishing := false
var anim_state := "idle"
var travel_phase := 0.0
var step_distance := 0.0
const STATES := ["idle", "walk", "run", "gather", "chop", "fish", "interact"]
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
	animation_time += delta
	action_timer = maxf(0.0, action_timer - delta)
	if not input_enabled:
		velocity = Vector2.ZERO
		walking = false
		running = false
		anim_state = "fish" if fishing else action_state if action_timer > 0 else "idle"
		queue_redraw()
		return
	var direction := Input.get_vector("aff_left", "aff_right", "aff_up", "aff_down")
	var has_input := direction.length() > 0.1
	running = has_input and Input.is_action_pressed("aff_run") and float(AffState.data["energy"]) > 4.0
	var target := direction * (100.0 if running else 65.0)
	var acceleration := 500.0 if has_input else 650.0
	velocity = velocity.move_toward(target, acceleration * delta)
	if has_input:
		# Near a diagonal, retain the current axis rather than flickering between rows.
		var ax := absf(direction.x)
		var ay := absf(direction.y)
		if ax > ay + 0.15:
			facing = 2 if direction.x < 0 else 3
		elif ay > ax + 0.15:
			facing = 1 if direction.y < 0 else 0
		elif facing in [2, 3] and ax > 0.1:
			facing = 2 if direction.x < 0 else 3
		elif ay > 0.1:
			facing = 1 if direction.y < 0 else 0
	var before := position
	move_and_slide()
	var moved := position.distance_to(before)
	walking = moved > 0.02
	if walking:
		travel_phase += moved / (4.0 if running else 5.0)
		step_distance += moved
		var stride := 15.0 if running else 19.0
		if step_distance >= stride:
			step_distance = fmod(step_distance, stride)
			step_taken.emit()
		var run_cost := 0.04 if AffState.amount("backpack") > 0 else 0.08
		AffState.data["energy"] = maxf(0.0, float(AffState.data["energy"]) - delta * (run_cost if running else 0.015))
	else:
		step_distance = 0.0
	anim_state = action_state if action_timer > 0.0 else ("run" if running else "walk") if walking else "idle"
	queue_redraw()

func interact_animation(kind: String = "interact") -> void:
	action_state = kind if kind in ["gather", "chop", "fish", "interact"] else "interact"
	action_duration = 0.55 if action_state == "chop" else 0.45
	action_timer = action_duration

func animation_source_rect() -> Rect2:
	var state_index := STATES.find(anim_state)
	var frame := 0
	if anim_state in ["walk", "run"]:
		frame = int(travel_phase) % 6
	elif anim_state in ["idle", "fish"]:
		frame = int(animation_time * (3.0 if anim_state == "fish" else 1.2)) % 6
	else:
		frame = clampi(int((1.0 - action_timer / action_duration) * 6.0), 0, 5)
	return Rect2(frame * 32, (state_index * 4 + facing) * 32, 32, 32)

func _draw() -> void:
	draw_set_transform(Vector2(0, 1), 0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 7.0, Color(0.08, 0.12, 0.09, 0.28))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	draw_texture_rect_region(ATLAS, Rect2(-16, -30, 32, 32), animation_source_rect())
