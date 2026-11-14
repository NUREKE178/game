extends RefCounted
const BOLD = preload("res://assets/fonts/Nunito-ExtraBold.ttf")

static func panel(color: Color, border: Color = Color(0.6, 0.7, 0.7, 0.25)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(18)
	return style

static func button(button: Button) -> void:
	button.custom_minimum_size.y = 48
	button.add_theme_font_override("font", BOLD)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_stylebox_override("normal", panel(Color(0.08, 0.12, 0.14, 0.88), Color(0.68, 0.78, 0.76, 0.30)))
	button.add_theme_stylebox_override("hover", panel(Color(0.26, 0.36, 0.34, 0.96), Color("#b0cfbd")))
	button.add_theme_stylebox_override("pressed", panel(Color(0.13, 0.25, 0.23, 1), Color("#d0e5cc")))
	button.add_theme_stylebox_override("disabled", panel(Color(0.08, 0.1, 0.1, 0.5)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color("#e5eddf"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.7, 0.75, 0.7, 0.4))

static func label(text: String, size: int, color: Color = Color("#e5eddf")) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.add_theme_color_override("font_outline_color", Color(0.03, 0.05, 0.06, 0.9))
	result.add_theme_constant_override("outline_size", 2)
	return result
