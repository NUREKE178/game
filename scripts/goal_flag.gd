extends Area2D
## Goal flag — touching it wins the level.

signal reached

var _t: float = 0.0

func _ready() -> void:
	collision_layer = 1 << 3
	collision_mask = 1 << 1
	monitoring = true
	monitorable = false
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(44.0, 72.0)
	col.shape = shape
	col.position = Vector2(0.0, -10.0)
	add_child(col)
	body_entered.connect(_on_body)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _on_body(body: Node) -> void:
	if body.is_in_group("player"):
		reached.emit()
		monitoring = false


func _draw() -> void:
	# glow
	draw_circle(Vector2(0.0, -16.0), 28.0 + sin(_t * 2.0) * 3.0, Color("#ffd166", 0.12))
	# pole
	draw_line(Vector2(0.0, 26.0), Vector2(0.0, -44.0), Color("#fff3b0"), 5.0)
	draw_circle(Vector2(0.0, -47.0), 5.0, Color("#ffd166"))
	# flag — large, waving
	var flutter := sin(_t * 3.5) * 3.0
	var pts := PackedVector2Array([
		Vector2(3.0, -44.0),
		Vector2(38.0 + flutter, -38.0),
		Vector2(38.0 - flutter, -18.0),
		Vector2(3.0, -12.0),
	])
	draw_polygon(pts, PackedColorArray([Color("#e63946")]))
	# Kazakh ornament on flag — simple
	draw_circle(Vector2(14.0, -28.0), 7.0, Color("#ffd166"))
	_draw_star(Vector2(14.0, -28.0), 4.0, Color("#e63946"))
	# base
	draw_rect(Rect2(Vector2(-12.0, 22.0), Vector2(24.0, 10.0)), Color("#8b5a2b"))
	# particles around
	for i in range(3):
		var a := _t * 1.8 + i * 2.1
		var p := Vector2(cos(a) * 22.0, -18.0 + sin(a * 1.3) * 10.0)
		draw_circle(p, 1.8, Color("#ffd166", 0.85))


func _draw_star(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(10):
		var ang := -PI / 2.0 + i * PI / 5.0
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(ang), sin(ang)) * rr)
	draw_polygon(pts, PackedColorArray([col]))
