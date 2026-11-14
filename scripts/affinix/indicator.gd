extends Node2D
var game
var clock := 0.0
func _process(delta: float) -> void:
	clock += delta
	queue_redraw()
func _draw() -> void:
	if game.screen_open or game.paused or game.placing >= 0 or game.selected.is_empty():
		return
	var p: Vector2 = game.selected["pos"]
	var alpha := 0.40 + 0.12 * sin(clock * 2.0)
	draw_set_transform(p, 0, Vector2(1.0, 0.42))
	draw_arc(Vector2.ZERO, 10.0, 0, TAU, 24, Color(0.95, 0.91, 0.72, alpha), 1.0)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
