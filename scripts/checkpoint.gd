extends Area2D
## Checkpoint flag — saves respawn position.

signal activated(pos: Vector2)

var active: bool = false
var _t: float = 0.0

func _ready() -> void:
	collision_layer = 1 << 3
	collision_mask = 1 << 1
	monitoring = true
	monitorable = false
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(40.0, 64.0)
	col.shape = shape
	col.position = Vector2(0.0, -12.0)
	add_child(col)
	body_entered.connect(_on_body)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _on_body(body: Node) -> void:
	if active:
		return
	if body.is_in_group("player"):
		active = true
		activated.emit(global_position)
		SFX.play("checkpoint")
		# pop
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector2(1.2, 1.2), 0.12)
		tw.tween_property(self, "scale", Vector2.ONE, 0.12)


func _draw() -> void:
	# pole
	draw_line(Vector2(0.0, 22.0), Vector2(0.0, -38.0), Color("#e8dcc0"), 4.0)
	draw_circle(Vector2(0.0, -40.0), 4.0, Color("#ffd166"))
	# flag
	var flutter := sin(_t * 4.0) * 2.0
	var col: Color = Color("#2ec4b6") if active else Color("#8a7a6a")
	var flag_pts := PackedVector2Array([
		Vector2(2.0, -36.0),
		Vector2(28.0 + flutter, -32.0),
		Vector2(28.0 - flutter * 0.5, -18.0),
		Vector2(2.0, -16.0),
	])
	draw_polygon(flag_pts, PackedColorArray([col]))
	# ornament if active
	if active:
		draw_circle(Vector2(14.0, -24.0), 2.5, Color(1, 1, 1, 0.9))
		draw_circle(Vector2(0.0, 22.0), 6.0, Color("#ffd166", 0.35))
		_draw_star(Vector2(14.0, -26.0), 3.0, Color("#ffd166"))
	# base
	draw_rect(Rect2(Vector2(-10.0, 18.0), Vector2(20.0, 8.0)), Color("#6b4c2a"))


func _draw_star(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(10):
		var ang := -PI / 2.0 + i * PI / 5.0
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(ang), sin(ang)) * rr)
	draw_polygon(pts, PackedColorArray([col]))
