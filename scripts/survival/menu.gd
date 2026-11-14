extends Control

const BG = preload("res://assets/fantasy/background.png")
const UI = preload("res://scripts/pixel_ui.gd")
const SAVE_PATH := "user://orma_world_v1.json"
var confirming := false
var new_button: Button
var hint: Label

func _ready() -> void:
	get_tree().paused = false
	var background := TextureRect.new()
	background.texture = BG
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var shade := ColorRect.new()
	shade.color = Color(0.06, 0.08, 0.16, 0.48)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(410, 0)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 12)
	center.add_child(column)
	var kicker := _label("БІР ӘЛЕМ • ӨЗ ХИКАЯҢ", 16, Color("#c5d8c4"))
	column.add_child(kicker)
	var title := _label("ORMA", 88, Color("#fff0cd"))
	title.add_theme_font_override("font", UI.BOLD)
	title.add_theme_color_override("font_outline_color", Color("#29364b"))
	title.add_theme_constant_override("outline_size", 5)
	column.add_child(title)
	column.add_child(_label("Сиқырлы ормандағы жаңа өмір", 22, Color("#f1dfcb")))
	var gap := Control.new()
	gap.custom_minimum_size.y = 24
	column.add_child(gap)
	var continue_button := _button("Жалғастыру")
	continue_button.disabled = not FileAccess.file_exists(SAVE_PATH)
	continue_button.pressed.connect(_continue_world)
	column.add_child(continue_button)
	new_button = _button("Жаңа әлем")
	new_button.pressed.connect(_new_world)
	column.add_child(new_button)
	var exit_button := _button("Шығу")
	exit_button.pressed.connect(func(): get_tree().quit())
	column.add_child(exit_button)
	hint = _label("Зертте. Жина. Өзіңе үй сал.", 15, Color("#d7e4dc"))
	column.add_child(hint)

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(360, 52)
	button.add_theme_font_size_override("font_size", 19)
	UI.apply_button(button)
	return button

func _continue_world() -> void:
	get_tree().set_meta("orma_new_world", false)
	get_tree().change_scene_to_file("res://scenes/survival_world.tscn")

func _new_world() -> void:
	if FileAccess.file_exists(SAVE_PATH) and not confirming:
		confirming = true
		new_button.text = "Растау: ескі әлем өшеді"
		hint.text = "Бас тарту үшін Жалғастыруды таңда."
		return
	get_tree().set_meta("orma_new_world", true)
	get_tree().change_scene_to_file("res://scenes/survival_world.tscn")
