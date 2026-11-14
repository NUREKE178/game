extends Control
const STYLE = preload("res://scripts/island/ui_style.gd")
const BACKGROUND = preload("res://assets/island/menu_background.png")
const SAVE_PATH := "user://ashore_save_v1.json"
var settings: Control
var new_button: Button
var message: Label
var confirming := false

func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var background := TextureRect.new()
	background.texture = BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var tint := ColorRect.new()
	tint.color = Color(0.025, 0.05, 0.06, 0.55)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tint)
	var panel := PanelContainer.new()
	panel.position = Vector2(60, 75)
	panel.custom_minimum_size = Vector2(420, 0)
	panel.add_theme_stylebox_override("panel", STYLE.panel(Color(0.035, 0.055, 0.065, 0.82)))
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 11)
	panel.add_child(box)
	var eyebrow := STYLE.label("SURVIVAL  /  PROTOTYPE", 13, Color("#91b5a4"))
	box.add_child(eyebrow)
	var title := STYLE.label("ASHORE", 68, Color("#f1f2e8"))
	title.add_theme_font_override("font", STYLE.BOLD)
	box.add_child(title)
	var gap := Control.new()
	gap.custom_minimum_size.y = 18
	box.add_child(gap)
	var continue_button := _button("CONTINUE")
	continue_button.disabled = not FileAccess.file_exists(SAVE_PATH)
	continue_button.pressed.connect(_continue)
	box.add_child(continue_button)
	new_button = _button("NEW GAME")
	new_button.pressed.connect(_new_game)
	box.add_child(new_button)
	var settings_button := _button("SETTINGS")
	settings_button.pressed.connect(func(): settings.visible = true)
	box.add_child(settings_button)
	var exit_button := _button("EXIT")
	exit_button.pressed.connect(func(): get_tree().quit())
	box.add_child(exit_button)
	message = STYLE.label("", 13, Color("#e7c19c"))
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(message)
	_build_settings()

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	STYLE.button(button)
	return button

func _new_game() -> void:
	if FileAccess.file_exists(SAVE_PATH) and not confirming:
		confirming = true
		new_button.text = "CONFIRM NEW GAME"
		message.text = "Starting a new game replaces your current save. Press again to confirm."
		return
	get_tree().set_meta("ashore_new", true)
	get_tree().change_scene_to_file("res://scenes/island_world.tscn")

func _continue() -> void:
	get_tree().set_meta("ashore_new", false)
	get_tree().change_scene_to_file("res://scenes/island_world.tscn")

func _build_settings() -> void:
	settings = Control.new()
	settings.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(settings)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.7)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 0)
	panel.add_theme_stylebox_override("panel", STYLE.panel(Color("#142126")))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var heading := STYLE.label("SETTINGS", 30)
	heading.add_theme_font_override("font", STYLE.BOLD)
	column.add_child(heading)
	column.add_child(STYLE.label("GRAPHICS QUALITY", 14))
	var quality := OptionButton.new()
	quality.add_item("Low")
	quality.add_item("Medium")
	quality.add_item("High")
	quality.select(Preferences.quality)
	STYLE.button(quality)
	quality.item_selected.connect(func(index: int):
		Preferences.quality = index
		Preferences.save_settings()
	)
	column.add_child(quality)
	column.add_child(STYLE.label("MASTER VOLUME", 14))
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.value = Preferences.volume
	slider.value_changed.connect(func(value: float):
		Preferences.volume = value
		Preferences.save_settings()
	)
	column.add_child(slider)
	column.add_child(STYLE.label("MOUSE SENSITIVITY", 14))
	var sensitivity := HSlider.new()
	sensitivity.min_value = 0.001
	sensitivity.max_value = 0.006
	sensitivity.step = 0.00025
	sensitivity.value = Preferences.sensitivity
	sensitivity.value_changed.connect(func(value: float):
		Preferences.sensitivity = value
		Preferences.save_settings()
	)
	column.add_child(sensitivity)
	var close := _button("BACK")
	close.pressed.connect(func(): settings.visible = false)
	column.add_child(close)
	settings.visible = false
