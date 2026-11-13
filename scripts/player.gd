extends CharacterBody2D
## The little steppe spirit — Dala's heart.
## Run, jump (coyote time + jump buffer + variable height), double jump,
## air dash with afterimages, squash & stretch, i-frames after taking damage.

signal jumped
signal double_jumped
signal dashed(direction: float)
signal landed(fall_speed: float)
signal hurt_taken(from_pos: Vector2)
signal died
signal bounced

const GRAVITY := 2400.0
const MAX_SPEED := 430.0
const ACCEL := 3400.0
const AIR_ACCEL := 2500.0
const FRICTION := 3800.0
const JUMP_VEL := 1010.0
const DOUBLE_JUMP_VEL := 880.0
const JUMP_CUT := 0.42
const COYOTE_TIME := 0.12
const JUMP_BUFFER := 0.14
const DASH_SPEED := 1080.0
const DASH_TIME := 0.16
const DASH_COOLDOWN := 0.85
const MAX_HEARTS := 3

var hearts: int = MAX_HEARTS
var facing: float = 1.0
var dead: bool = false
var input_locked: bool = false

var _coyote := 0.0
var _buffer := 0.0
var _dash_t := 0.0
var _dash_cd := 0.0
var _iframes := 0.0
var _can_double := true
var _squash_x := 1.0
var _squash_y := 1.0
var _dash_dir := 1.0
var _was_on_floor := false
var _fall_speed := 0.0
var _blink := 0.0
var _blink_timer := 2.5

const SPIRIT = preload("res://assets/sprites/spirit.png")
var anim_time: float = 0.0

const HALF_SIZE := Vector2(21.0, 25.0)


func _ready() -> void:
	add_to_group("player")
	_fall_speed = 0.0


func _physics_process(delta: float) -> void:
	anim_time += delta
	queue_redraw()
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink = 0.12
		_blink_timer = randf_range(2.2, 4.0)
	_blink = maxf(0.0, _blink - delta)

	_iframes = maxf(0.0, _iframes - delta)
	_dash_cd = maxf(0.0, _dash_cd - delta)
	_coyote = maxf(0.0, _coyote - delta)
	_buffer = maxf(0.0, _buffer - delta)

	# squash & stretch spring back to neutral
	_squash_x = lerpf(_squash_x, 1.0, 1.0 - exp(-12.0 * delta))
	_squash_y = lerpf(_squash_y, 1.0, 1.0 - exp(-12.0 * delta))

	if dead:
		velocity.y += GRAVITY * delta
		velocity.x = lerpf(velocity.x, 0.0, 1.0 - exp(-4.0 * delta))
		move_and_slide()
		_update_visual(delta)
		return

	var dir := 0.0
	if not input_locked:
		dir = Input.get_axis("move_left", "move_right")

	var on_floor := is_on_floor()
	if on_floor:
		_coyote = COYOTE_TIME
		_can_double = true

	# ---------------- dash ----------------
	if _dash_t > 0.0:
		_dash_t -= delta
		velocity.x = _dash_dir * DASH_SPEED
		velocity.y = 0.0
		_fall_speed = 0.0
	else:
		if not on_floor:
			velocity.y += GRAVITY * delta
		else:
			_fall_speed = 0.0
		# horizontal movement
		var accel := ACCEL if on_floor else AIR_ACCEL
		if dir != 0.0:
			velocity.x = move_toward(velocity.x, dir * MAX_SPEED, accel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	# ---------------- jumping ----------------
	if not input_locked and Input.is_action_just_pressed("jump"):
		_buffer = JUMP_BUFFER

	if _buffer > 0.0:
		if _coyote > 0.0:
			_do_jump(JUMP_VEL)
			jumped.emit()
			_buffer = 0.0
			_coyote = 0.0
		elif _can_double:
			_do_jump(DOUBLE_JUMP_VEL)
			_can_double = false
			double_jumped.emit()
			_buffer = 0.0
			_squash_x = 0.75
			_squash_y = 1.35

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	# ---------------- dash trigger ----------------
	if not input_locked and Input.is_action_just_pressed("dash") and _dash_cd <= 0.0 and _dash_t <= 0.0:
		var d := dir
		if d == 0.0:
			d = facing
		_dash_dir = signf(d)
		_dash_t = DASH_TIME
		_dash_cd = DASH_COOLDOWN
		dashed.emit(_dash_dir)

	if absf(velocity.x) > 10.0 and dir != 0.0:
		facing = signf(dir)

	_fall_speed = maxf(_fall_speed, velocity.y)
	var was_on_floor := _was_on_floor
	move_and_slide()
	on_floor = is_on_floor()
	_was_on_floor = on_floor

	if on_floor and not was_on_floor:
		# landing!
		_squash_x = 1.45
		_squash_y = 0.6
		landed.emit(_fall_speed)
	elif not on_floor and was_on_floor and velocity.y >= 0.0:
		# walked off a ledge
		_coyote = COYOTE_TIME

	_update_visual(delta)


func _do_jump(vel: float) -> void:
	velocity.y = -vel
	_squash_x = 0.7
	_squash_y = 1.4


func _update_visual(_delta: float) -> void:
	var sx := _squash_x
	var sy := _squash_y
	scale = Vector2(facing * sx, sy)
	# i-frame flicker
	if _iframes > 0.0 and not dead:
		modulate.a = 0.45 + 0.4 * sin(Time.get_ticks_msec() * 0.04)
	else:
		modulate.a = 1.0


func get_hurt_rect() -> Rect2:
	var half := HALF_SIZE
	return Rect2(global_position - half, half * 2.0)


func is_dashing() -> bool:
	return _dash_t > 0.0


func dash_ready() -> float:
	## 1.0 = ready, 0.0 = just used
	if DASH_COOLDOWN <= 0.0:
		return 1.0
	return 1.0 - clampf(_dash_cd / DASH_COOLDOWN, 0.0, 1.0)


func hurt(from_pos: Vector2) -> bool:
	if dead or _iframes > 0.0 or is_dashing():
		return false
	hearts -= 1
	hurt_taken.emit(from_pos)
	var away := global_position - from_pos
	if away.length_squared() < 1.0:
		away = Vector2(0.0, -1.0)
	away = away.normalized()
	velocity = Vector2(away.x * 520.0, -620.0)
	_iframes = 1.6
	_squash_x = 1.4
	_squash_y = 0.65
	if hearts <= 0:
		_die()
	return true


func bounce() -> void:
	velocity.y = -920.0
	_squash_x = 0.7
	_squash_y = 1.4
	bounced.emit()


func spring_bounce() -> void:
	velocity.y = -1500.0
	_can_double = true
	_squash_x = 0.6
	_squash_y = 1.55


func pit_fall() -> bool:
	## returns true if the player died from the fall
	if dead:
		return true
	hearts -= 1
	hurt_taken.emit(global_position + Vector2(0.0, 600.0))
	if hearts <= 0:
		_die()
		return true
	_iframes = 2.0
	return false


func _die() -> void:
	dead = true
	velocity = Vector2(0.0, -500.0)
	died.emit()


func respawn_at(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	_fall_speed = 0.0
	_squash_x = 1.0
	_squash_y = 1.0
	modulate.a = 1.0


# Four rows: idle, run, jump and dash. All frames share a 48x48 cell.
func _draw() -> void:
	var row := 0
	if _dash_t > 0.0:
		row = 3
	elif not is_on_floor():
		row = 2
	elif absf(velocity.x) > 40.0:
		row = 1
	var frame := int(anim_time * (10.0 if row == 1 else 4.0)) % 4
	draw_texture_rect_region(SPIRIT, Rect2(-32, -38, 64, 64), Rect2(frame * 48, row * 48, 48, 48))
