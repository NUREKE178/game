extends Node2D
## Small CPU-only pixel flecks, one short-lived node per actual step or pickup.
var kind := "dust"
var age := 0.0
var duration := 0.45
func _process(delta: float) -> void:
	age += delta
	if age >= duration:
		queue_free()
	else:
		queue_redraw()
func _draw() -> void:
	var t := age / duration
	var color := Color(0.84, 0.79, 0.65, 0.45 * (1.0 - t)) if kind == "dust" else Color(0.83, 0.87, 0.61, 0.85 * (1.0 - t))
	for i in range(3 if kind == "dust" else 6):
		var angle := TAU * float(i) / (3.0 if kind == "dust" else 6.0)
		var distance := t * (4.0 if kind == "dust" else 9.0)
		var p := Vector2(cos(angle) * distance, sin(angle) * distance - t * 3.0).round()
		draw_rect(Rect2(p, Vector2(2, 2)), color)
