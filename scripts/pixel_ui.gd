extends RefCounted
## Shared nine-slice pixel-art UI styles.

const BOLD = preload("res://assets/fonts/Nunito-ExtraBold.ttf")
const PANEL := preload("res://assets/ui/panel.png")
const NORMAL := preload("res://assets/ui/button.png")
const HOVER := preload("res://assets/ui/button_hover.png")
const PRESSED := preload("res://assets/ui/button_pressed.png")
const DISABLED := preload("res://assets/ui/button_disabled.png")

static func style(texture: Texture2D, margin: float = 8.0) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = texture
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_texture_margin(side, 8.0)
		box.set_content_margin(side, margin)
	return box

static func apply_button(button: Button) -> void:
	button.add_theme_font_override("font", BOLD)
	button.add_theme_stylebox_override("normal", style(NORMAL))
	button.add_theme_stylebox_override("hover", style(HOVER))
	button.add_theme_stylebox_override("pressed", style(PRESSED))
	button.add_theme_stylebox_override("disabled", style(DISABLED))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color("#24223a"))
	button.add_theme_color_override("font_hover_color", Color("#24223a"))
	button.add_theme_color_override("font_pressed_color", Color("#24223a"))
	button.add_theme_color_override("font_disabled_color", Color("#c8c3b8"))
