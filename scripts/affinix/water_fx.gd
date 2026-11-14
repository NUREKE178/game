extends Node2D
## Restrained, pixel-sized moving glints over the lake.
var elapsed := 0.0
var redraw_timer := 0.0
func _process(delta: float) -> void:
	elapsed += delta
	redraw_timer += delta
	if redraw_timer > 0.12:
		redraw_timer = 0.0
		queue_redraw()
func _draw() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera and camera.get_screen_center_position().distance_to(Vector2(992, 320)) > 560:
		return
	for i in range(35):
		var x := 992.0 + sin(i * 8.14) * 142.0
		var y := 320.0 + cos(i * 5.37) * 108.0
		if Vector2((x - 992) / 160.0, (y - 320) / 128.0).length() > 0.90:
			continue
		var shimmer := 0.10 + 0.16 * (0.5 + 0.5 * sin(elapsed * 1.3 + i * 2.0))
		var offset := roundf(sin(elapsed * 0.6 + i) * 2)
		draw_line(Vector2(roundf(x + offset), roundf(y)), Vector2(roundf(x + offset + 3 + i % 3), roundf(y)), Color(0.83,0.91,0.84,shimmer), 1.0)

	# Broken highlights along the inner bank suggest a soft moving shoreline.
	for i in range(32):
		var angle := TAU * float(i) / 32.0
		var strength := 0.08 + 0.10 * (0.5 + 0.5 * sin(elapsed + i * 0.8))
		var a := Vector2(992 + cos(angle) * 155.0, 320 + sin(angle) * 123.0).round()
		var b := Vector2(992 + cos(angle + 0.10) * 155.0, 320 + sin(angle + 0.10) * 123.0).round()
		draw_line(a, b, Color(0.89, 0.92, 0.79, strength), 1.0)
