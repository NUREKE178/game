extends Node2D
## Procedural steppe sky — gradient, sun/moon, drifting clouds,
## far and near hills with parallax. No textures needed.

var level_data: Dictionary = {}
var _time: float = 0.0
var _cam_x: float = 0.0

func set_level(data: Dictionary) -> void:
	level_data = data
	queue_redraw()

func set_camera_x(x: float) -> void:
	_cam_x = x
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if level_data.is_empty():
		return
	var vp := get_viewport_rect().size
	# use big rect to cover screen regardless of camera
	var cam := get_viewport().get_camera_2d()
	var cam_pos := cam.global_position if cam else Vector2.ZERO
	# draw in world space? Instead draw in screen space by using position+cam
	# Simpler: draw sky gradient as viewport-covering rects relative to cam
	# We'll draw directly in world coords covering large area around camera
	var top_col := Color(level_data.get("sky_top", "#3a1c5c"))
	var bot_col := Color(level_data.get("sky_bottom", "#ff9e5e"))
	var far_col := Color(level_data.get("far_hill", "#241a3f"))
	var near_col := Color(level_data.get("near_hill", "#171233"))
	var sun_col := Color(level_data.get("sun_color", "#ffd166"))

	var left := cam_pos.x - vp.x
	var right := cam_pos.x + vp.x * 1.5
	var top := cam_pos.y - vp.y
	var bottom := cam_pos.y + vp.y * 1.2
	# sky gradient — 12 horizontal strips
	var strips := 12
	var sky_h := bottom - top
	for i in range(strips):
		var t0 := float(i) / strips
		var t1 := float(i + 1) / strips
		var col := top_col.lerp(bot_col, t0)
		var y0 := top + sky_h * t0
		var y1 := top + sky_h * t1
		draw_rect(Rect2(Vector2(left, y0), Vector2(right - left, y1 - y0)), col)

	# sun / moon
	var sun_x := cam_pos.x + vp.x * 0.35 + sin(_time * 0.06) * 18.0
	var sun_y := top + vp.y * 0.28
	draw_circle(Vector2(sun_x, sun_y), 54.0, Color(sun_col, 0.18))
	draw_circle(Vector2(sun_x, sun_y), 36.0, Color(sun_col, 0.85))
	draw_circle(Vector2(sun_x - 6.0, sun_y - 6.0), 9.0, Color(1, 1, 1, 0.45))

	# clouds — two layers with different parallax factors
	_draw_clouds(cam_pos, left, right, top, vp, 0.25)
	_draw_clouds(cam_pos, left, right, top, vp, 0.55)

	# hills — parallax: far moves 0.3x, near 0.65x
	# We draw hills as polygons that move slower than camera
	var far_parallax := 0.30
	var near_parallax := 0.62
	_draw_hills(cam_pos, left, right, bottom, vp, far_parallax, far_col, 0.85, 120.0)
	_draw_hills(cam_pos, left, right, bottom, vp, near_parallax, near_col, 1.0, 210.0)

	# stars for night level (level 3) — detect via top color
	if top_col.b < 0.2:
		var star_base := cam_pos.x * 0.15
		for i in range(24):
			var sx := fmod(star_base * 0.7 + i * 137.5, right - left) + left
			var sy := top + 20.0 + fmod(i * 73.0, vp.y * 0.45)
			var tw := 0.5 + 0.5 * sin(_time * (1.2 + i * 0.07) + i)
			draw_circle(Vector2(sx, sy), 1.0 + tw * 0.8, Color(1, 1, 1, 0.75 * tw))


func _draw_clouds(cam_pos: Vector2, left: float, right: float, top: float, vp: Vector2, factor: float) -> void:
	var base_x := cam_pos.x * factor
	var y := top + vp.y * (0.32 if factor < 0.4 else 0.42)
	for i in range(5):
		var cx := fmod(base_x * 0.5 + i * 420.0, right - left + 600.0) + left - 100.0
		# bob
		var bob := sin(_time * 0.35 + i * 1.1) * 6.0
		var pos := Vector2(cx, y + bob + i * 18.0)
		var alpha := 0.22 if factor < 0.4 else 0.34
		var col := Color(1, 1, 1, alpha)
		draw_circle(pos, 28.0, col)
		draw_circle(pos + Vector2(22.0, 4.0), 22.0, col)
		draw_circle(pos + Vector2(-18.0, 6.0), 18.0, col)
		draw_circle(pos + Vector2(8.0, -10.0), 16.0, col)


func _draw_hills(cam_pos: Vector2, left: float, right: float, bottom: float, vp: Vector2, parallax: float, col: Color, alpha: float, height: float) -> void:
	var base_x := cam_pos.x * parallax
	# Create a smooth hill silhouette using sine waves
	var hill_y := bottom - (120.0 if parallax < 0.5 else 40.0)
	var points := PackedVector2Array()
	var step := 40.0
	var start_x := left - 400.0
	var end_x := right + 400.0
	# top edge
	var x := start_x
	while x <= end_x:
		var local_x := x + base_x * 0.15
		var h := sin(local_x * 0.0021) * height * 0.35 + sin(local_x * 0.005 + 1.2) * height * 0.18 + sin(local_x * 0.0012 + 2.5) * height * 0.22
		points.append(Vector2(x, hill_y - h))
		x += step
	# bottom edge
	points.append(Vector2(end_x, bottom + 40.0))
	points.append(Vector2(start_x, bottom + 40.0))
	draw_polygon(points, PackedColorArray([Color(col, alpha)]))
	# hill highlight
	var hl_points := PackedVector2Array()
	x = start_x
	while x <= end_x:
		var local_x := x + base_x * 0.15
		var h := sin(local_x * 0.0021) * height * 0.35 + sin(local_x * 0.005 + 1.2) * height * 0.18 + sin(local_x * 0.0012 + 2.5) * height * 0.22
		hl_points.append(Vector2(x, hill_y - h))
		x += step
	# draw line along crest
	for i in range(hl_points.size() - 1):
		draw_line(hl_points[i], hl_points[i+1], Color(1, 1, 1, 0.07), 2.0)
