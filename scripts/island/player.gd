extends CharacterBody3D

const WALK_SPEED := 4.4
const RUN_SPEED := 7.0
const JUMP_SPEED := 6.3
var camera: Camera3D
var enabled := false
var stamina := 100.0
var step_timer := 0.0
var world

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)
	camera = Camera3D.new()
	camera.position.y = 1.62
	camera.fov = 76.0
	camera.current = true
	add_child(camera)

func _unhandled_input(event: InputEvent) -> void:
	if not enabled or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * Preferences.sensitivity)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * Preferences.sensitivity, -1.45, 1.45)

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	var axis := Input.get_vector("island_left", "island_right", "island_forward", "island_back")
	var dir := (transform.basis * Vector3(axis.x, 0, axis.y)).normalized()
	var sprinting := Input.is_action_pressed("island_sprint") and stamina > 1.0 and axis.length() > 0.1
	if sprinting:
		stamina = maxf(0.0, stamina - delta * 13.0)
	else:
		stamina = minf(100.0, stamina + delta * 9.0)
	var speed := RUN_SPEED if sprinting else WALK_SPEED
	velocity.x = move_toward(velocity.x, dir.x * speed, 22.0 * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, 22.0 * delta)
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	elif Input.is_action_just_pressed("island_jump"):
		velocity.y = JUMP_SPEED
	move_and_slide()
	if is_on_floor() and dir.length() > 0.1:
		step_timer -= delta
		if step_timer <= 0:
			Sound.play("step")
			step_timer = 0.33 if sprinting else 0.5
	else:
		step_timer = 0.0
