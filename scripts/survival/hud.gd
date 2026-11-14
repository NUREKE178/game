extends Control
## Survival HUD, inventory and pause screens.

const UI = preload("res://scripts/pixel_ui.gd")
const ICONS := [
	preload("res://assets/fantasy/dirt.png"),
	preload("res://assets/fantasy/stone.png"),
	preload("res://assets/fantasy/wood.png"),
	preload("res://assets/fantasy/plank.png"),
	preload("res://assets/fantasy/berry.png"),
	preload("res://assets/fantasy/brick.png"),
]
const ITEMS := ["dirt", "stone", "wood", "plank", "berry", "brick"]
const ITEM_NAMES := {"dirt": "Топырақ", "stone": "Тас", "wood": "Ағаш", "plank": "Тақтай", "berry": "Жидек", "brick": "Кірпіш"}
var world
var stats: Label
var day_label: Label
var selected_label: Label
var message: Label
var hotbar_buttons: Array[Button] = []
var inventory_view: Control
var pause_view: Control
var items_label: Label
var message_time := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hud()
	_build_inventory()
	_build_pause()

func _build_hud() -> void:
	var top := PanelContainer.new()
	top.position = Vector2(24, 22)
	top.add_theme_stylebox_override("panel", UI.style(UI.PANEL, 12))
	add_child(top)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	top.add_child(column)
	stats = _label("", 18)
	stats.add_theme_font_override("font", UI.BOLD)
	column.add_child(stats)
	day_label = _label("", 14)
	column.add_child(day_label)
	var instructions := _label("A / D  жүру     SPACE  секіру     E  крафт     F  жидек     ESC  пауза", 15)
	instructions.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	instructions.position = Vector2(-620, 25)
	instructions.add_theme_color_override("font_color", Color("#f4eedc"))
	add_child(instructions)
	var bottom := VBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bottom.offset_left = -320
	bottom.offset_right = 320
	bottom.offset_top = -124
	bottom.offset_bottom = -12
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 3)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom)
	selected_label = _label("", 14)
	selected_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(selected_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	bottom.add_child(row)
	for i in range(6):
		var button := Button.new()
		button.custom_minimum_size = Vector2(92, 60)
		button.icon = ICONS[i]
		button.expand_icon = true
		button.add_theme_font_size_override("font_size", 14)
		UI.apply_button(button)
		var index := i
		button.pressed.connect(func():
			world.selected = index
			refresh()
		)
		row.add_child(button)
		hotbar_buttons.append(button)
	var help := _label("Сол жақ: қазу / жинау     •     Оң жақ: блок қою", 14)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(help)
	message = _label("", 17)
	message.z_index = 20
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.set_anchors_preset(Control.PRESET_CENTER)
	message.position = Vector2(-300, 155)
	message.size = Vector2(600, 35)
	message.add_theme_font_override("font", UI.BOLD)
	add_child(message)

func _build_inventory() -> void:
	inventory_view = _overlay()
	var panel := _center_panel(inventory_view, Vector2(560, 430))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(_title("Сөмке және крафт"))
	box.add_child(_label("Жиналған ресурстар", 17))
	items_label = _label("", 18)
	items_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(items_label)
	box.add_child(_label("Рецепт: 1 ағаш → 4 тақтай", 18))
	var craft := _button("4 тақтай жасау")
	craft.pressed.connect(func(): world.craft_planks())
	box.add_child(craft)
	box.add_child(_label("Рецепт: 2 тас → 4 кірпіш", 18))
	var brick := _button("4 кірпіш жасау")
	brick.pressed.connect(func(): world.craft_bricks())
	box.add_child(brick)
	var close := _button("Жабу  •  E")
	close.pressed.connect(func(): world.set_inventory(false))
	box.add_child(close)
	inventory_view.visible = false

func _build_pause() -> void:
	pause_view = _overlay()
	var panel := _center_panel(pause_view, Vector2(440, 330))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(_title("Демалыс"))
	box.add_child(_label("Әлемің осында күтіп тұрады.", 17))
	var resume := _button("Жалғастыру")
	resume.pressed.connect(func(): world.set_pause(false))
	box.add_child(resume)
	var save := _button("Сақтау және мәзір")
	save.pressed.connect(func(): world.save_and_menu())
	box.add_child(save)
	pause_view.visible = false

func _overlay() -> Control:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.05, 0.07, 0.12, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)
	return overlay

func _center_panel(parent: Control, dimensions: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -dimensions.x / 2
	panel.offset_right = dimensions.x / 2
	panel.offset_top = -dimensions.y / 2
	panel.offset_bottom = dimensions.y / 2
	panel.add_theme_stylebox_override("panel", UI.style(UI.PANEL, 24))
	parent.add_child(panel)
	return panel

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#fff0d2"))
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.10, 0.16, 0.8))
	label.add_theme_constant_override("outline_size", 2)
	return label

func _title(text: String) -> Label:
	var label := _label(text, 30)
	label.add_theme_font_override("font", UI.BOLD)
	return label

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size", 18)
	UI.apply_button(button)
	return button

func refresh_stats() -> void:
	stats.text = "ӨМІР  %d     АШТЫҚ  %d" % [int(world.health), int(world.hunger)]
	day_label.text = "ОРМАН  /  " + ("ТҮН" if world.day_time < 0.15 or world.day_time > 0.85 else "КҮН")

func refresh() -> void:
	if not is_instance_valid(stats):
		return
	refresh_stats()
	for i in range(hotbar_buttons.size()):
		var item: String = ITEMS[i]
		var button: Button = hotbar_buttons[i]
		button.text = "%d  ×%d" % [i + 1, int(world.inventory[item])]
		button.modulate = Color.WHITE if world.selected == i else Color(0.68, 0.70, 0.72)
	var selected_item: String = ITEMS[world.selected]
	selected_label.text = "%s  •  %d / 6" % [ITEM_NAMES[selected_item], world.selected + 1]
	var lines: Array[String] = []
	for item in ITEMS:
		lines.append("%s: %d" % [ITEM_NAMES[item], int(world.inventory[item])])
	items_label.text = "    ".join(lines)

func set_inventory_visible(value: bool) -> void:
	inventory_view.visible = value
	refresh()

func set_pause_visible(value: bool) -> void:
	pause_view.visible = value

func notify(text: String) -> void:
	message.text = text
	message_time = 3.0

func _process(delta: float) -> void:
	if message_time > 0.0:
		message_time -= delta
		if message_time <= 0.0:
			message.text = ""
