extends CharacterBody2D
## A grumpy little steppe slime. Patrols back and forth, gets stomped.

const GRAVITY := 2400.0
const SPEED := 115.0
const PATROL := 170.0
const HALF_SIZE := Vector2(23.0, 17.0)

var spawn_x: float = 0.0
var _dir: float = 1.0
var _t: float = 0.0
var _squish: float = 1.0
var dead: bool = false
var _dead_t: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	spawn_x = global_position.x
	set_meta("half_size", HALF_SIZE)


func _physics_process(delta: float) -> void:
	_t += delta

	if dead:
		_dead_t += delta
		_squish = lerpf(_squish, 0.18, 1.0 - exp(-10.0 * delta))
		scale = Vector2(2.0 - _squish, _squish)
		modulate.a = maxf(0.0, 1.0 - _dead_t / 0.45)
		if _dead_t > 0.45:
			queue_free()
		return

	velocity.y += GRAVITY * delta
	velocity.x = _dir * SPEED
	move_and_slide()

	if global_position.x > spawn_x + PATROL:
		_dir = -1.0
	elif global_position.x < spawn_x - PATROL:
		_dir = 1.0
	if is_on_wall():
		_dir = -_dir

	# walk wobble
	var wobble := 1.0 + 0.09 * sin(_t * 9.0)
	_squish = lerpf(_squish, wobble, 1.0 - exp(-10.0 * delta))
	scale = Vector2(1.0 / sqrt(_squish), _squish)
	modulate.a = 1.0


func get_hurt_rect() -> Rect2:
	return Rect2(global_position - HALF_SIZE, HALF_SIZE * 2.0)


func stomp() -> void:
	if dead:
		return
	dead = true
	velocity = Vector2.ZERO


func _draw() -> void:
	# slime body
	draw_circle(Vector2(0.0, 6.0), 20.0, Color("#3f9e4d"))
	draw_circle(Vector2(0.0, 2.0), 18.0, Color("#56c271"))
	draw_circle(Vector2(0.0, 9.0), 11.0, Color("#7de29a"))
	# shine
	draw_circle(Vector2(-7.0, -3.0), 3.4, Color(1.0, 1.0, 1.0, 0.45))
	# angry eyes
	draw_circle(Vector2(-7.0, 1.0), 2.8, Color("#12351b"))
	draw_circle(Vector2(7.0, 1.0), 2.8, Color("#12351b"))
	draw_circle(Vector2(-7.8, 0.1), 0.9, Color("#ffffff"))
	draw_circle(Vector2(6.2, 0.1), 0.9, Color("#ffffff"))
	# grumpy brows
	draw_line(Vector2(-10.5, -4.5), Vector2(-4.0, -2.0), Color("#12351b"), 1.6)
	draw_line(Vector2(10.5, -4.5), Vector2(4.0, -2.0), Color("#12351b"), 1.6)
