extends Control
const STYLE = preload("res://scripts/affinix/styles.gd")
var game
var stats: Label
var location: Label
var quest: Label
var prompt: Label
var notice: Label
var notice_timer := 0.0
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

func _build_hud() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 24)
	panel.add_theme_stylebox_override("panel", STYLE.panel(Color(0.13,0.20,0.15,0.92)))
	add_child(panel)
	var v := VBoxContainer.new()
	panel.add_child(v)
	location = STYLE.label("", 20)
	location.add_theme_font_override("font", STYLE.BOLD)
	v.add_child(location)
	stats = STYLE.label("", 15)
	v.add_child(stats)
	quest = STYLE.label("", 14)
	v.add_child(quest)
	prompt = STYLE.label("", 18)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.offset_left = -400
	prompt.offset_right = 400
	prompt.offset_top = -110
	prompt.offset_bottom = -80
	add_child(prompt)
	var help := STYLE.label("WASD move   ·   Shift run   ·   E interact   ·   I bag   ·   C craft   ·   J journal   ·   M map   ·   Esc pause", 14)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	help.offset_left = -550
	help.offset_right = 550
	help.offset_top = -40
	help.offset_bottom = -10
	add_child(help)
	notice = STYLE.label("", 16)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	notice.offset_left = -400
	notice.offset_right = 400
	notice.offset_top = -150
	notice.offset_bottom = -120
	notice.z_index = 30
	add_child(notice)

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
	overlay.visible = true
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
	location.text = "%s   ·   Day %d   ·   %02d:%02d   ·   %s" % [game.world.region(game.player.position), int(data["day"]), hour, mins, data["weather"]]
	stats.text = "Health %d    Hunger %d    Energy %d    Warmth %d" % [int(data["health"]),int(data["hunger"]),int(data["energy"]),int(data["temperature"])]
	var index := int(data["quest"])
	quest.text = "Journal · " + (str(AffState.QUESTS[index]["detail"]) if index < AffState.QUESTS.size() else "The story is complete.")
	if game.placing >= 0:
		prompt.text = "Click or E: place   ·   R: rotate   ·   Esc: cancel"
	elif game._near_building() >= 0:
		prompt.text = "E  ·  Use structure     X  ·  Pick up"
	elif game.selected.is_empty():
		prompt.text = ""
	else:
		var names := {"home":"Visit cabin", "npc":"Talk", "lake":"Fish", "note":"Read note", "board":"Repair notice board"}
		prompt.text = "E  ·  " + str(names.get(game.selected["kind"], "Gather " + str(game.selected["kind"])))

func notify(text: String) -> void:
	notice.text = text
	notice_timer = 3.0

func _process(delta: float) -> void:
	if fishing and is_instance_valid(fish_marker):
		fishing_time += delta
		fish_marker.value = (sin(fishing_time * 2.5) + 1.0) * 50.0
	if notice_timer > 0:
		notice_timer -= delta
		if notice_timer <= 0:
			notice.text = ""
