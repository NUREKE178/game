extends Node2D
## Pixel-art steppe backdrop. Drawn relative to the active camera.

const BACKDROP = preload("res://assets/bg/menu_bg.png")
var level_data: Dictionary = {}

func set_level(data: Dictionary) -> void:
	level_data = data
	queue_redraw()

func set_camera_x(_x: float) -> void:
	queue_redraw()

func _draw() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var viewport_size := get_viewport_rect().size / camera.zoom
	var center := camera.get_screen_center_position()
	var tint := Color.WHITE
	if level_data.get("sky_top", "") == "#12112b":
		tint = Color(0.72, 0.76, 1.0)
	draw_texture_rect(BACKDROP, Rect2(center - viewport_size * 0.5, viewport_size), false, tint)
