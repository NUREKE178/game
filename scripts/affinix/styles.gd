extends RefCounted
const BOLD = preload("res://assets/fonts/Nunito-ExtraBold.ttf")
static func panel(color: Color = Color("#293b30")) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = color
	result.border_color = Color("#9caa88")
	result.set_border_width_all(2)
	result.set_content_margin_all(14)
	result.set_corner_radius_all(3)
	return result
static func button(button: Button) -> void:
	button.custom_minimum_size.y = 42
	button.add_theme_font_override("font", BOLD)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_stylebox_override("normal", panel(Color("#526b51")))
	button.add_theme_stylebox_override("hover", panel(Color("#789474")))
	button.add_theme_stylebox_override("pressed", panel(Color("#405b45")))
	button.add_theme_stylebox_override("disabled", panel(Color("#414d40")))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color("#f5f1db"))
static func label(text: String, size: int = 16) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", Color("#f3eedc"))
	return result
