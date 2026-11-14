extends Control
const STYLE = preload("res://scripts/affinix/styles.gd")
const BACK = preload("res://assets/affinix/title.png")
var status: Label
var confirm := false
var new_button: Button

func _ready() -> void:
	get_tree().paused = false
	var back := TextureRect.new()
	back.texture = BACK
	back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	var shade := ColorRect.new()
	shade.color = Color(0.07, 0.12, 0.09, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var card := PanelContainer.new()
	card.position = Vector2(90, 70)
	card.custom_minimum_size = Vector2(420, 0)
	card.add_theme_stylebox_override("panel", STYLE.panel(Color(0.12, 0.19, 0.15, 0.93)))
	add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	card.add_child(column)
	column.add_child(STYLE.label("A QUIET SURVIVAL ADVENTURE", 13))
	var title: Label = STYLE.label("AFFINIX", 62)
	title.add_theme_font_override("font", STYLE.BOLD)
	column.add_child(title)
	column.add_child(STYLE.label("Take your time. The forest can wait.", 16))
	var gap := Control.new()
	gap.custom_minimum_size.y = 16
	column.add_child(gap)
	var resume := _button("Continue")
	resume.disabled = not FileAccess.file_exists(AffState.SAVE_PATH)
	resume.pressed.connect(_continue)
	column.add_child(resume)
	new_button = _button("New game")
	new_button.pressed.connect(_new_game)
	column.add_child(new_button)
	var volume_lbl: Label = STYLE.label("Volume", 15)
	column.add_child(volume_lbl)
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = AffAudio.volume
	volume.value_changed.connect(AffAudio.set_volume)
	column.add_child(volume)
	var quit := _button("Quit")
	quit.pressed.connect(func(): get_tree().quit())
	column.add_child(quit)
	status = STYLE.label("", 13)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)

func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	STYLE.button(b)
	return b

func _continue() -> void:
	if not AffState.load_game():
		status.text = "The save could not be read. It has not been changed."
		return
	get_tree().change_scene_to_file("res://scenes/affinix/game.tscn")

func _new_game() -> void:
	if FileAccess.file_exists(AffState.SAVE_PATH) and not confirm:
		confirm = true
		new_button.text = "Confirm new game"
		status.text = "This will replace the existing save. Press again to confirm."
		return
	AffState.new_game()
	get_tree().change_scene_to_file("res://scenes/affinix/game.tscn")
