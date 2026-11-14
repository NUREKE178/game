extends Control
const STYLE = preload("res://scripts/island/ui_style.gd")
var world
var stats: Label
var supplies: Label
var prompt: Label
var notice: Label
var notice_time := 0.0
var craft_screen: Control
var pause_screen: Control
var intro_screen: Control
var intro_shade: ColorRect
var intro_label: Label
var inventory_label: Label
var objective: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hud()
	_build_craft()
	_build_pause()
	_build_intro()

func _build_hud() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 24)
	panel.add_theme_stylebox_override("panel", STYLE.panel(Color(0.04, 0.07, 0.075, 0.75)))
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	stats = STYLE.label("", 16)
	stats.add_theme_font_override("font", STYLE.BOLD)
	column.add_child(stats)
	supplies = STYLE.label("", 13, Color("#c9d7cf"))
	column.add_child(supplies)
	objective = STYLE.label("Explore inland for fresh water.", 13, Color("#c9d7cf"))
	column.add_child(objective)
	var crosshair := STYLE.label("·", 34)
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-12, -30)
	crosshair.size = Vector2(24, 45)
	add_child(crosshair)
	prompt = STYLE.label("", 17)
	prompt.add_theme_font_override("font", STYLE.BOLD)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.set_anchors_preset(Control.PRESET_CENTER)
	prompt.position = Vector2(-240, 55)
	prompt.size = Vector2(480, 30)
	add_child(prompt)
	var help := STYLE.label("WASD Move    SHIFT Sprint    SPACE Jump    E Interact    C Craft    R Eat    F Drink    ESC Pause", 14)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	help.offset_left = -570
	help.offset_right = 570
	help.offset_top = -42
	help.offset_bottom = -12
	add_child(help)
	notice = STYLE.label("", 16, Color("#ecdfb3"))
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	notice.offset_left = -350
	notice.offset_right = 350
	notice.offset_top = -85
	notice.offset_bottom = -55
	notice.z_index = 30
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(notice)

func _overlay() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.025, 0.03, 0.76)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	return root

func _panel(root: Control, width: float) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = width
	panel.add_theme_stylebox_override("panel", STYLE.panel(Color("#142126")))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 11)
	panel.add_child(box)
	return box

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	STYLE.button(button)
	return button

func _build_craft() -> void:
	craft_screen = _overlay()
	var box := _panel(craft_screen, 460)
	var heading := STYLE.label("FIELD CRAFT", 28)
	heading.add_theme_font_override("font", STYLE.BOLD)
	box.add_child(heading)
	inventory_label = STYLE.label("", 15, Color("#b7c8bb"))
	box.add_child(inventory_label)
	box.add_child(STYLE.label("Structures are placed in front of you.", 14))
	var fire := _button("CAMPFIRE     3 STICKS  +  2 STONES")
	fire.pressed.connect(func(): world.craft("fire"))
	box.add_child(fire)
	var shelter := _button("SHELTER     5 STICKS")
	shelter.pressed.connect(func(): world.craft("shelter"))
	box.add_child(shelter)
	var close := _button("CLOSE")
	close.pressed.connect(func(): world.set_crafting(false))
	box.add_child(close)
	craft_screen.visible = false

func _build_pause() -> void:
	pause_screen = _overlay()
	var box := _panel(pause_screen, 440)
	var heading := STYLE.label("PAUSED", 30)
	heading.add_theme_font_override("font", STYLE.BOLD)
	box.add_child(heading)
	box.add_child(STYLE.label("GRAPHICS", 14))
	var quality := OptionButton.new()
	quality.add_item("Low")
	quality.add_item("Medium")
	quality.add_item("High")
	quality.select(Preferences.quality)
	STYLE.button(quality)
	quality.item_selected.connect(func(index: int):
		Preferences.quality = index
		Preferences.save_settings()
		Preferences.apply_graphics(get_viewport(), world.sun, world.player.camera)
	)
	box.add_child(quality)
	box.add_child(STYLE.label("MASTER VOLUME", 14))
	var volume := HSlider.new()
	volume.min_value = 0
	volume.max_value = 1
	volume.step = 0.05
	volume.value = Preferences.volume
	volume.value_changed.connect(func(value: float):
		Preferences.volume = value
		Preferences.save_settings()
	)
	box.add_child(volume)
	var resume := _button("RESUME")
	resume.pressed.connect(func(): world.set_pause(false))
	box.add_child(resume)
	var save := _button("SAVE & EXIT TO MENU")
	save.pressed.connect(func(): world.save_and_menu())
	box.add_child(save)
	pause_screen.visible = false

func _build_intro() -> void:
	intro_screen = Control.new()
	intro_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_screen.z_index = 50
	add_child(intro_screen)
	intro_shade = ColorRect.new()
	intro_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_shade.color = Color(0, 0, 0, 0)
	intro_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_screen.add_child(intro_shade)
	intro_label = STYLE.label("ENGINE FAILURE", 23)
	intro_label.add_theme_font_override("font", STYLE.BOLD)
	intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	intro_label.offset_left = -300
	intro_label.offset_right = 300
	intro_label.offset_top = -115
	intro_label.offset_bottom = -70
	intro_screen.add_child(intro_label)
	var skip := STYLE.label("ESC  SKIP", 13)
	skip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skip.offset_left = -130
	skip.offset_right = -20
	skip.offset_top = -40
	skip.offset_bottom = -10
	intro_screen.add_child(skip)
	intro_screen.visible = false

func show_intro(value: bool) -> void:
	intro_screen.visible = value

func update_intro(progress: float) -> void:
	intro_shade.color = Color(0, 0, 0, smoothstep(0.80, 0.98, progress))
	intro_label.text = "BRACE FOR IMPACT" if progress > 0.52 else "ENGINE FAILURE"

func set_crafting_visible(value: bool) -> void:
	craft_screen.visible = value
	refresh()

func set_pause_visible(value: bool) -> void:
	pause_screen.visible = value

func set_prompt(text: String) -> void:
	prompt.text = text

func notify(text: String) -> void:
	notice.text = text
	notice_time = 3.5

func refresh() -> void:
	stats.text = "HEALTH %d   FOOD %d   WATER %d   STAMINA %d" % [int(world.health), int(world.hunger), int(world.thirst), int(world.player.stamina)]
	supplies.text = "STICKS %d    STONES %d    BERRIES %d    WATER %d/3" % [int(world.inventory["stick"]), int(world.inventory["stone"]), int(world.inventory["berry"]), int(world.inventory["water"])]
	inventory_label.text = supplies.text

func _process(delta: float) -> void:
	if notice_time > 0:
		notice_time -= delta
		if notice_time <= 0:
			notice.text = ""
