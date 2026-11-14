extends Control
const STYLE = preload("res://scripts/affinix/styles.gd")
var game
const ICONS := {
	"health": preload("res://assets/affinix/icon_health.png"), "hunger": preload("res://assets/affinix/icon_hunger.png"),
	"energy": preload("res://assets/affinix/icon_energy.png"), "temperature": preload("res://assets/affinix/icon_temperature.png"),
	"wood": preload("res://assets/affinix/icon_wood.png"), "stone": preload("res://assets/affinix/icon_stone.png"),
	"axe": preload("res://assets/affinix/icon_axe.png"), "pickaxe": preload("res://assets/affinix/icon_pickaxe.png"),
	"rod": preload("res://assets/affinix/icon_rod.png"), "berry": preload("res://assets/affinix/icon_berry.png"),
	"meal": preload("res://assets/affinix/icon_meal.png"), "lantern": preload("res://assets/affinix/icon_lantern.png"),
	"Sunny": preload("res://assets/affinix/icon_sun.png"), "Rain": preload("res://assets/affinix/icon_rain_icon.png"),
	"Fog": preload("res://assets/affinix/icon_fog_icon.png"), "Wind": preload("res://assets/affinix/icon_wind_icon.png")}
const HOTBAR := ["wood", "stone", "axe", "pickaxe", "rod", "berry", "meal", "lantern"]
var bars: Dictionary = {}
var hotbar_buttons: Array[Button] = []
var location: Label
var weather_icon: TextureRect
var selected_slot := 0
var overlay_tween: Tween
var prompt: Label
var notice: Label
var notice_timer := 0.0
var notice_queue: Array[String] = []
var overlay: Control
var box: VBoxContainer
var fishing := false
var fishing_time := 0.0
var fish_marker: ProgressBar

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hud()
	_build_overlay()
	AffState.changed.connect(refresh)

func _hud_style(color: Color, border: Color, margin: int = 5) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(margin)
	return style

func _build_hud() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.add_theme_stylebox_override("panel", _hud_style(Color(0.07,0.13,0.10,0.83), Color(0.52,0.61,0.49,0.55), 7))
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)
	var colors := {"health":Color("#d37c72"), "hunger":Color("#dbb279"), "energy":Color("#a3be80"), "temperature":Color("#85b2bc")}
	for id in ["health", "hunger", "energy", "temperature"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 5)
		v.add_child(row)
		var icon := TextureRect.new()
		icon.texture = ICONS[id]
		icon.custom_minimum_size = Vector2(18,18)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(112, 8)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.show_percentage = false
		bar.add_theme_stylebox_override("background", _hud_style(Color("#26382d"), Color.TRANSPARENT, 0))
		bar.add_theme_stylebox_override("fill", _hud_style(colors[id], Color.TRANSPARENT, 0))
		row.add_child(bar)
		bars[id] = bar
	var clock_panel := PanelContainer.new()
	clock_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	clock_panel.offset_left = -185
	clock_panel.offset_right = 185
	clock_panel.offset_top = 18
	clock_panel.add_theme_stylebox_override("panel", _hud_style(Color(0.07,0.13,0.10,0.83), Color(0.52,0.61,0.49,0.55), 7))
	add_child(clock_panel)
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 7)
	clock_panel.add_child(title_row)
	weather_icon = TextureRect.new()
	weather_icon.custom_minimum_size = Vector2(20,20)
	weather_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	weather_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_row.add_child(weather_icon)
	location = STYLE.label("", 15)
	location.add_theme_font_override("font", STYLE.BOLD)
	title_row.add_child(location)
	prompt = STYLE.label("", 16)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.offset_left = -360
	prompt.offset_right = 360
	prompt.offset_top = -124
	prompt.offset_bottom = -100
	add_child(prompt)
	var slots := HBoxContainer.new()
	slots.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	slots.offset_left = -241
	slots.offset_right = 241
	slots.offset_top = -87
	slots.offset_bottom = -30
	slots.add_theme_constant_override("separation", 5)
	slots.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(slots)
	for i in range(HOTBAR.size()):
		var item: String = HOTBAR[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(55, 54)
		button.icon = ICONS[item]
		button.expand_icon = true
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_font_override("font", STYLE.BOLD)
		button.add_theme_font_size_override("font_size", 11)
		button.add_theme_color_override("font_color", Color("#f3eedc"))
		button.tooltip_text = "%d · %s. %s" % [i + 1, AffState.ITEM_NAMES[item], "Eat" if item in ["berry", "meal"] else "Tools work automatically when carried" if item in ["axe", "pickaxe", "rod", "lantern"] else "Open bag"]
		var index := i
		button.pressed.connect(func(): use_hotbar(index))
		slots.add_child(button)
		hotbar_buttons.append(button)
	_update_slot_styles()
	var help := STYLE.label("E interact   ·   I bag   ·   C craft   ·   J journal   ·   Esc pause", 12)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	help.offset_left = -360
	help.offset_right = 360
	help.offset_top = -25
	help.offset_bottom = -4
	add_child(help)
	notice = STYLE.label("", 16)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	notice.offset_left = -400
	notice.offset_right = 400
	notice.offset_top = -157
	notice.offset_bottom = -132
	notice.z_index = 30
	add_child(notice)

func _update_slot_styles() -> void:
	for i in range(hotbar_buttons.size()):
		var selected := i == selected_slot
		var b := hotbar_buttons[i]
		b.add_theme_stylebox_override("normal", _hud_style(Color(0.17,0.25,0.17,0.96) if selected else Color(0.07,0.13,0.10,0.86), Color("#e4d5a4") if selected else Color("#637661"), 3))
		b.add_theme_stylebox_override("hover", _hud_style(Color("#47644c"), Color("#e4d5a4"), 3))
		b.add_theme_stylebox_override("pressed", _hud_style(Color("#344b39"), Color("#e4d5a4"), 3))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func use_hotbar(index: int) -> void:
	if game.paused or game.screen_open or game.placing >= 0 or index < 0 or index >= HOTBAR.size():
		return
	selected_slot = index
	_update_slot_styles()
	var button := hotbar_buttons[index]
	button.modulate = Color(1.35, 1.35, 1.15)
	create_tween().tween_property(button, "modulate", Color.WHITE, 0.20)
	var item: String = HOTBAR[index]
	if item in ["berry", "meal"]:
		if AffState.amount(item) > 0:
			AffState.eat(item)
		else:
			notify("No %s in your bag." % AffState.ITEM_NAMES[item])
	elif item in ["axe", "pickaxe", "rod", "lantern"]:
		notify("%s works automatically when carried." % AffState.ITEM_NAMES[item] if AffState.amount(item) > 0 else "Craft a %s first." % AffState.ITEM_NAMES[item])
	else:
		open_inventory()

func _build_overlay() -> void:
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.04,0.08,0.06,0.72)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560,0)
	panel.add_theme_stylebox_override("panel", STYLE.panel(Color("#293b30")))
	center.add_child(panel)
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)
	overlay.visible = false

func _open(title: String) -> void:
	fishing = false
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()
	var heading := STYLE.label(title, 28)
	heading.add_theme_font_override("font", STYLE.BOLD)
	box.add_child(heading)
	var was_visible := overlay.visible
	overlay.visible = true
	if not was_visible:
		if overlay_tween:
			overlay_tween.kill()
		overlay.modulate.a = 0.0
		overlay_tween = create_tween()
		overlay_tween.tween_property(overlay, "modulate:a", 1.0, 0.16)
	game.set_screen(true)

func _text(text: String, size: int = 16) -> void:
	var label: Label = STYLE.label(text, size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(label)

func _button(text: String, callback: Callable, enabled: bool = true) -> void:
	var b := Button.new()
	b.text = text
	b.disabled = not enabled
	STYLE.button(b)
	b.pressed.connect(callback)
	box.add_child(b)

func close_screen() -> void:
	fishing = false
	game.player.fishing = false
	if overlay_tween:
		overlay_tween.kill()
	overlay.modulate.a = 1.0
	overlay.visible = false
	game.set_screen(false)
	if game.paused:
		game.set_pause(false)

func open_home() -> void:
	_open("The cabin")
	_text("An old notebook waits on the table. This little place can be home.")
	if not AffState.data["flags"].get("notebook", false):
		_button("Read the notebook", func():
			AffState.set_flag("notebook")
			open_note("The notebook", "If you found this cabin, it is yours now. The village is quiet, but it does not have to stay that way. Follow the old paths and leave a light on for someone else.")
		)
	elif int(AffState.data["quest"]) >= 12 and not AffState.data["flags"].get("ending", false):
		_button("Read the final page", func():
			AffState.set_flag("ending")
			open_note("The last page", "The village was never lost. It was waiting for someone to care. Thank you for bringing the light back. Your story here can continue.")
		)
	_button("Sleep until morning", func(): AffState.sleep(); game._save(); close_screen())
	_button("Close", close_screen)

func open_note(title: String, text: String) -> void:
	_open(title)
	_text(text, 19)
	_button("Close", close_screen)

func open_npc(id: String) -> void:
	_open("Rowan · Fisherman" if id == "rowan" else "Ada · Villager")
	_text("The lake rewards patience. A quiet day is never wasted." if id == "rowan" else "Your cabin belonged to a kind soul. Perhaps the old notice board can be repaired.", 18)
	var status: String = str(AffState.data["side"].get(id, "available"))
	var need := {"fish":2} if id == "rowan" else {"wood":4}
	var reward := {"herb":3} if id == "rowan" else {"berry":4}
	var explanation := "Bring two fish; I'll share some herbs." if id == "rowan" else "Four pieces of wood would mend an old bench."
	_text("A SMALL FAVOR · " + explanation, 15)
	if status == "available":
		_button("Accept favor", func():
			AffState.data["side"][id] = "active"
			open_npc(id)
		)
	elif status == "active":
		_button("Deliver · " + _cost(need), func():
			if AffState.spend(need):
				for item in reward:
					AffState.add_item(str(item), int(reward[item]))
				AffState.data["side"][id] = "done"
				notify("Thank you. A little reward for your help.")
				open_npc(id)
			else:
				notify("You don't have the requested items yet.")
		)
	else:
		_text("Favor complete.", 14)
	_button("Close", close_screen)

func open_inventory() -> void:
	_open("The bag")
	_text("Food can be eaten here. Tools work automatically when carried.", 14)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500, 330)
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var inv: Dictionary = AffState.data["inventory"]
	var found := false
	for id in AffState.ITEM_NAMES:
		var count := int(inv.get(id, 0))
		if count <= 0:
			continue
		found = true
		if id in ["berry", "mushroom", "fish", "meal"]:
			var item_id: String = id
			var button := Button.new()
			button.text = "Eat %s  × %d" % [AffState.ITEM_NAMES[id], count]
			button.tooltip_text = "Eat one to restore hunger."
			STYLE.button(button)
			button.pressed.connect(func(): AffState.eat(item_id); open_inventory())
			list.add_child(button)
		else:
			list.add_child(STYLE.label("%s  × %d" % [AffState.ITEM_NAMES[id], count], 15))
	if not found:
		list.add_child(STYLE.label("Your bag is empty."))
	_button("Close", close_screen)

func open_tent() -> void:
	_open("Shelter")
	_text("Rest here until morning.")
	_button("Sleep", func(): AffState.sleep(); game._save(); close_screen())
	_button("Close", close_screen)

func open_storage() -> void:
	_open("Storage chest")
	_text("Select an item to move one between bag and chest.", 14)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500, 330)
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for id in AffState.ITEM_NAMES:
		var bag := AffState.amount(id)
		var stored := int(AffState.data["storage"].get(id, 0))
		if bag == 0 and stored == 0:
			continue
		var item_id: String = id
		var row := HBoxContainer.new()
		list.add_child(row)
		var label: Label = STYLE.label("%s   bag %d / chest %d" % [AffState.ITEM_NAMES[id], bag, stored], 14)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var put := Button.new()
		put.text = "Put"
		put.disabled = bag <= 0
		STYLE.button(put)
		put.pressed.connect(func():
			AffState.data["inventory"][item_id] = AffState.amount(item_id) - 1
			AffState.data["storage"][item_id] = int(AffState.data["storage"].get(item_id, 0)) + 1
			open_storage()
		)
		row.add_child(put)
		var take := Button.new()
		take.text = "Take"
		take.disabled = stored <= 0
		STYLE.button(take)
		take.pressed.connect(func():
			AffState.data["storage"][item_id] = int(AffState.data["storage"].get(item_id, 0)) - 1
			AffState.data["inventory"][item_id] = AffState.amount(item_id) + 1
			open_storage()
		)
		row.add_child(take)
	_button("Close", close_screen)

func _cost(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for id in cost:
		parts.append("%d %s" % [int(cost[id]), AffState.ITEM_NAMES.get(id, id)])
	return ", ".join(parts)

func open_crafting() -> void:
	_open("Crafting & building")
	_text("Choose a recipe or select a structure to place.", 14)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500,390)
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for i in range(AffState.RECIPES.size()):
		var recipe: Dictionary = AffState.RECIPES[i]
		var button := Button.new()
		button.text = "%s · %s" % [recipe["name"], _cost(recipe["cost"])]
		STYLE.button(button)
		var index := i
		button.pressed.connect(func(): AffState.craft(index); open_crafting())
		list.add_child(button)
	for i in range(AffState.BUILDINGS.size()):
		var building: Dictionary = AffState.BUILDINGS[i]
		var button := Button.new()
		button.text = "PLACE %s · %s" % [building["name"], _cost(building["cost"])]
		STYLE.button(button)
		var index := i
		button.pressed.connect(func(): game.start_placement(index))
		list.add_child(button)
	_button("Close", close_screen)

func open_journal() -> void:
	_open("Journal")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500,350)
	box.add_child(scroll)
	var list := VBoxContainer.new()
	scroll.add_child(list)
	var current := int(AffState.data["quest"])
	for i in range(AffState.QUESTS.size()):
		var q: Dictionary = AffState.QUESTS[i]
		var mark := "DONE" if i < current else "NOW" if i == current else "LATER"
		var label: Label = STYLE.label("%s  ·  %s" % [mark, q["title"]], 15)
		list.add_child(label)
		if i == current:
			list.add_child(STYLE.label(str(q["detail"]), 14))
	list.add_child(STYLE.label("Side favors", 17))
	for id in ["rowan", "ada"]:
		var status: String = str(AffState.data["side"].get(id, "available"))
		if status != "available":
			var detail := "Bring two fish to Rowan" if id == "rowan" else "Bring four wood to Ada"
			list.add_child(STYLE.label(("DONE · " if status == "done" else "ACTIVE · ") + detail, 14))
	_button("Close", close_screen)

func open_map() -> void:
	_open("Map")
	_text("The six regions are connected by the old forest paths.")
	_text("Whispering Forest     |     Crystal Lake     |     Autumn Valley", 16)
	_text("Forgotten Village       |     Secret Underground     |     Misty Mountains", 16)
	_text("You are in: " + game.world.region(game.player.position))
	_button("Close", close_screen)

func open_fishing() -> void:
	_open("Crystal Lake")
	game.player.fishing = true
	_text("Press Reel in while the marker is in the middle.")
	fish_marker = ProgressBar.new()
	fish_marker.custom_minimum_size.y = 24
	fish_marker.max_value = 100
	fish_marker.show_percentage = false
	box.add_child(fish_marker)
	fishing = true
	fishing_time = 0
	_button("Reel in", func():
		if absf(fish_marker.value - 50.0) < 15:
			AffState.add_item("fish")
			AffAudio.play("gather")
			close_screen()
			notify("Caught a fish.")
		else:
			close_screen()
			notify("It got away. Try again.")
	)
	_button("Close", close_screen)

func set_pause_visible(value: bool) -> void:
	if value:
		_open("Paused")
		_text("Take your time.")
		_button("Resume", close_screen)
		_button("Save game", func():
			if game._save():
				notify("Game saved.")
		)
		_button("Atmosphere effects: " + ("On" if game.atmosphere.visible else "Off"), func():
			game.atmosphere.visible = not game.atmosphere.visible
			game.atmosphere.set_process(game.atmosphere.visible)
			set_pause_visible(true)
		)
		_text("Volume", 14)
		var volume := HSlider.new()
		volume.min_value = 0
		volume.max_value = 1
		volume.step = 0.05
		volume.value = AffAudio.volume
		volume.value_changed.connect(AffAudio.set_volume)
		box.add_child(volume)
		_button("Save and return to menu", game.leave)
	else:
		overlay.visible = false
		game.set_screen(false)

func refresh() -> void:
	if not is_instance_valid(location) or not is_instance_valid(game.player):
		return
	var data: Dictionary = AffState.data
	var hour := int(float(data["minute"]) / 60.0)
	var mins := int(data["minute"]) % 60
	weather_icon.texture = ICONS.get(str(data["weather"]), ICONS["Sunny"])
	location.text = "Day %d  ·  %02d:%02d  ·  %s" % [int(data["day"]), hour, mins, data["weather"]]
	location.tooltip_text = game.world.region(game.player.position)
	for id in bars:
		bars[id].value = float(data[id])
		bars[id].tooltip_text = "%s: %d / 100" % [id.capitalize(), int(data[id])]
	for i in range(hotbar_buttons.size()):
		hotbar_buttons[i].text = "%d  ×%d" % [i + 1, AffState.amount(HOTBAR[i])]
	if game.placing >= 0:
		prompt.text = "Click or E: place   ·   R: rotate   ·   Esc: cancel"
	elif game._near_building() >= 0:
		prompt.text = "E  ·  Use structure     X  ·  Pick up"
	elif game.selected.is_empty():
		prompt.text = ""
	else:
		var names := {"home":"Visit cabin", "npc":"Talk", "lake":"Fish", "note":"Read note", "board":"Repair notice board", "treasure":"Open hidden cache"}
		prompt.text = "E  ·  " + str(names.get(game.selected["kind"], "Gather " + str(game.selected["kind"])))

func notify(text: String) -> void:
	if notice_timer > 0.0:
		if text != notice.text and not notice_queue.has(text):
			if notice_queue.size() >= 6:
				notice_queue.pop_front()
			notice_queue.append(text)
		return
	notice.text = text
	notice_timer = 2.5

func _process(delta: float) -> void:
	if fishing and is_instance_valid(fish_marker):
		fishing_time += delta
		fish_marker.value = (sin(fishing_time * 2.5) + 1.0) * 50.0
	if notice_timer > 0:
		notice_timer -= delta
		if notice_timer <= 0:
			notice.text = ""
			if not notice_queue.is_empty():
				notify(notice_queue.pop_front())
