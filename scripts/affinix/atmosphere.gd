extends Node2D
## Rain, fog and fireflies live above the y-sorted actors and below the HUD.
var world
var clock := 0.0
func _process(delta: float) -> void:
	clock += delta
	queue_redraw()
func _draw() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var center := camera.get_screen_center_position()
	var weather: String = str(AffState.data["weather"])
	if weather == "Rain":
		for i in range(45):
			var x := fposmod(i * 73.0 + clock * 40.0, 700.0) + center.x - 350.0
			var y := fposmod(i * 59.0 + clock * 100.0, 400.0) + center.y - 200.0
			draw_line(Vector2(x, y), Vector2(x - 2, y + 6), Color(0.8, 0.9, 0.9, 0.5), 1.0)
	if weather == "Fog":
		draw_rect(Rect2(center - Vector2(350, 200), Vector2(700,400)), Color(0.85,0.9,0.86,0.05))
	if world.region(center) == "Misty Mountains" and weather in ["Rain", "Wind"]:
		for i in range(32):
			var x := fposmod(i * 61.0 + clock * 8.0, 700.0) + center.x - 350.0
			var y := fposmod(i * 83.0 + clock * 18.0, 400.0) + center.y - 200.0
			draw_circle(Vector2(x, y), 1.0, Color(0.95, 0.98, 1, 0.8))
	var minute: float = float(AffState.data["minute"])
	if minute >= 1140 or minute < 360:
		for i in range(14):
			var x := center.x - 330 + fposmod(i * 127.0 + sin(clock * 0.5 + i) * 15, 660)
			var y := center.y - 180 + fposmod(i * 79.0 + cos(clock * 0.7 + i) * 8, 360)
			var alpha := 0.25 + 0.45 * (0.5 + 0.5 * sin(clock * 2 + i))
			draw_circle(Vector2(x, y), 1.0, Color(1, 0.90, 0.55, alpha))
