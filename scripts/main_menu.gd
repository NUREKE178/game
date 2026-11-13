extends Control
## Main menu for DALA — Steppe Spirit. All UI built in code,
## so the .tscn is just a single Control with this script.

const PixelUI = preload("res://scripts/pixel_ui.gd")
const MENU_BG = preload("res://assets/bg/menu_bg.png")
const _LevelsPreload = preload("res://scripts/levels.gd")

var _cards: Array[Control] = []
var _t: float = 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	queue_redraw()


func _build_ui() -> void:
	# Title area — centered top
	var title_box := VBoxContainer.new()
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	title_box.position = Vector2(0, 48)
	title_box.size = Vector2(1280, 140)
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_box)

	var title := Label.new()
	title.text = "DALA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 88)
	title.add_theme_color_override("font_color", Color("#ffd166"))
	title.add_theme_color_override("font_outline_color", Color(0,0,0,0.85))
	title.add_theme_constant_override("outline_size", 10)
	title_box.add_child(title)

	var sub := Label.new()
	sub.text = "Степной дух  •  Steppe Spirit"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(1,1,1,0.85))
	title_box.add_child(sub)

	var sub2 := Label.new()
	sub2.text = "жүгір  •  секір  •  зымыра  •  туды көтер"
	sub2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub2.add_theme_font_size_override("font_size", 16)
	sub2.add_theme_color_override("font_color", Color(1,1,1,0.55))
	title_box.add_child(sub2)

	# Level cards row
	var row := HBoxContainer.new()
	row.name = "Row"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	row.position = Vector2(0, 230)
	row.size = Vector2(1280, 320)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	for i in range(Levels.level_count()):
		var card := _make_card(i)
		row.add_child(card)
		_cards.append(card)

	# Bottom bar
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 20)
	bottom.position = Vector2(0, 620)
	bottom.size = Vector2(1280, 60)
	add_child(bottom)

	var mute_btn := Button.new()
	mute_btn.text = "Дыбыс: Қосулы" if not Game.muted else "Дыбыс: Өшірулі"
	mute_btn.custom_minimum_size = Vector2(220, 44)
	mute_btn.add_theme_font_size_override("font_size", 16)
	PixelUI.apply_button(mute_btn)
	mute_btn.pressed.connect(func():
		Game.toggle_mute()
		mute_btn.text = "Дыбыс: Қосулы" if not Game.muted else "Дыбыс: Өшірулі"
		SFX.play("click")
	)
	bottom.add_child(mute_btn)

	var quit_btn := Button.new()
	quit_btn.text = "Шығу"
	quit_btn.custom_minimum_size = Vector2(140, 44)
	quit_btn.add_theme_font_size_override("font_size", 16)
	PixelUI.apply_button(quit_btn)
	quit_btn.pressed.connect(func(): SFX.play("click"); Game.quit_game())
	bottom.add_child(quit_btn)

	# Controls hint
	var hint := Label.new()
	hint.text = "A/D немесе ←/→ қозғалу  •  Space/W секіру  •  X/Shift зымырау  •  Esc тоқтату"
	hint.position = Vector2(0, 684)
	hint.size = Vector2(1280, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(1,1,1,0.38))
	add_child(hint)


func _make_card(idx: int) -> Control:
	var data: Dictionary = Levels.get_level(idx)
	var unlocked: bool = Game.is_level_unlocked(idx)
	var best: Dictionary = Game.best.get(idx, {"coins":0,"stars":0,"time":0.0,"done":false})
	var done: bool = bool(best.get("done", false))
	var stars: int = int(best.get("stars", 0))

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 280)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", PixelUI.style(PixelUI.PANEL, 16.0))
	if not unlocked:
		card.modulate = Color(0.68, 0.68, 0.72)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	# number badge
	var badge := Label.new()
	badge.text = "%d" % (idx + 1)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 42)
	badge.add_theme_color_override("font_color", Color(data.get("sun_color", "#ffd166")))
	badge.add_theme_color_override("font_outline_color", Color(0,0,0,0.7))
	badge.add_theme_constant_override("outline_size", 6)
	vbox.add_child(badge)

	var name_lbl := Label.new()
	name_lbl.text = str(data.get("name", ""))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", Color(1,1,1,0.95))
	vbox.add_child(name_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = str(data.get("subtitle", ""))
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 14)
	sub_lbl.add_theme_color_override("font_color", Color(1,1,1,0.55))
	vbox.add_child(sub_lbl)

	# stars row
	var stars_row := HBoxContainer.new()
	stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stars_row.add_theme_constant_override("separation", 4)
	vbox.add_child(stars_row)
	for i in range(3):
		var s := Label.new()
		if not unlocked:
			s.text = "☆"
			s.add_theme_color_override("font_color", Color(1,1,1,0.12))
		else:
			s.text = "★" if i < stars else "☆"
			s.add_theme_color_override("font_color", Color("#ffd166") if i < stars else Color(1,1,1,0.18))
		s.add_theme_font_size_override("font_size", 24)
		stars_row.add_child(s)

	# stats
	var stats := Label.new()
	if not unlocked:
		stats.text = "Құлыпталған"
		stats.add_theme_color_override("font_color", Color(1,1,1,0.35))
	else:
		if done:
			var c := int(best.get("coins",0))
			var t: float = float(best.get("time",0.0))
			var mins := int(t) / 60
			var secs := int(t) % 60
			stats.text = "%d тиын  •  %02d:%02d" % [c, mins, secs]
			stats.add_theme_color_override("font_color", Color(1,1,1,0.65))
		else:
			stats.text = "ойналмады"
			stats.add_theme_color_override("font_color", Color(1,1,1,0.4))
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 13)
	vbox.add_child(stats)

	# play button
	var btn := Button.new()
	btn.text = "Ойнау" if unlocked else "Жабық"
	btn.custom_minimum_size = Vector2(200, 42)
	btn.disabled = not unlocked
	btn.add_theme_font_size_override("font_size", 18)
	PixelUI.apply_button(btn)
	btn.pressed.connect(func():
		if unlocked:
			SFX.play("click")
			Game.start_level(idx)
	)
	vbox.add_child(btn)

	# card hover effect
	card.mouse_entered.connect(func():
		if unlocked:
			card.modulate = Color(1.05, 1.05, 1.05)
	)
	card.mouse_exited.connect(func():
		card.modulate = Color.WHITE if unlocked else Color(0.68, 0.68, 0.72)
	)

	return card

func _draw() -> void:
	var target := size if size.x > 10.0 and size.y > 10.0 else Vector2(1280, 720)
	draw_texture_rect(MENU_BG, Rect2(Vector2.ZERO, target), false)
