extends Area2D
## Spring pad / батут — launches the player high.

var _squish: float = 1.0
var _t: float = 0.0

func _ready() -> void:
	collision_layer = 1 << 3
	collision_mask = 1 << 1
	monitoring = true
	monitorable = false
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(58.0, 16.0)
	col.shape = shape
	col.position = Vector2(0.0, 6.0)
	add_child(col)
	body_entered.connect(_on_body)
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	_t += delta
	_squish = lerpf(_squish, 1.0, 1.0 - exp(-10.0 * delta))
	scale = Vector2(1.0, _squish)
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and body.velocity.y >= -100.0:
			if body.global_position.y < global_position.y - 18.0:
				_bounce(body)
				break


func _on_body(body: Node) -> void:
	if body.is_in_group("player"):
		if body.global_position.y < global_position.y:
			_bounce(body)


func _bounce(player: Node) -> void:
	if player.has_method("spring_bounce"):
		player.spring_bounce()
		SFX.play("spring")
		_squish = 0.45
		_spawn_burst()


func _spawn_burst() -> void:
	var burst := Node2D.new()
	burst.global_position = global_position + Vector2(0.0, -8.0)
	get_parent().add_child(burst)
	for i in range(6):
		var dot := Node2D.new()
		var ang := i * TAU / 6.0
		dot.position = Vector2(cos(ang), sin(ang)) * 4.0
		dot.set_meta("vel", Vector2(cos(ang), sin(ang) - 0.6) * 220.0)
		burst.add_child(dot)
		dot.set_script(_dot_script())
	var timer := Timer.new()
	timer.wait_time = 0.35
	timer.one_shot = true
	timer.timeout.connect(func(): burst.queue_free())
	burst.add_child(timer)
	timer.start()


func _dot_script() -> GDScript:
	var s := GDScript.new()
	s.source_code = "extends Node2D\nfunc _process(delta: float) -> void:\n\tvar vel: Vector2 = get_meta(\"vel\")\n\tposition += vel * delta\n\tvel.y += 900.0 * delta\n\tset_meta(\"vel\", vel)\nfunc _draw() -> void: draw_circle(Vector2.ZERO, 3.0, Color(\"#ffd166\"))\n"
	s.reload()
	return s


func _draw() -> void:
	draw_rect(Rect2(Vector2(-28.0, 10.0), Vector2(56.0, 10.0)), Color("#8b5a2b"))
	draw_rect(Rect2(Vector2(-24.0, 6.0), Vector2(48.0, 8.0)), Color("#e8a33d"))
	for i in range(3):
		var x := -16.0 + i * 16.0
		draw_line(Vector2(x, 6.0), Vector2(x + 4.0, -6.0), Color("#fff3b0"), 2.5)
		draw_line(Vector2(x + 4.0, -6.0), Vector2(x + 8.0, 6.0), Color("#fff3b0"), 2.5)
	draw_rect(Rect2(Vector2(-30.0, -8.0), Vector2(60.0, 14.0)), Color("#2ec4b6"))
	draw_rect(Rect2(Vector2(-26.0, -6.0), Vector2(52.0, 6.0)), Color("#7de2d1"))
	draw_circle(Vector2(0.0, -2.0), 2.0, Color(1, 1, 1, 0.6))
