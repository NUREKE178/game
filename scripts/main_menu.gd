extends Control
## Main menu for DALA — Steppe Spirit. All UI built in code,
## so the .tscn is just a single Control with this script.

const _LevelsPreload = preload("res://scripts/levels.gd")

var _cards: Array[Control] = []
var _t: float = 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
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
	mute_btn.text = "🔊 Дыбыс: Қосулы" if not Game.muted else "🔇 Дыбыс: Өшірулі"
	mute_btn.custom_minimum_size = Vector2(220, 44)
	mute_btn.add_theme_font_size_override("font_size", 16)
	mute_btn.add_theme_stylebox_override("normal", _card_style(Color(0.12,0.12,0.18,0.85)))
	mute_btn.add_theme_stylebox_override("hover", _card_style(Color(0.18,0.18,0.28,0.95)))
	mute_btn.pressed.connect(func():
		Game.toggle_mute()
		mute_btn.text = "🔊 Дыбыс: Қосулы" if not Game.muted else "🔇 Дыбыс: Өшірулі"
		SFX.play("click")
	)
	bottom.add_child(mute_btn)

	var quit_btn := Button.new()
	quit_btn.text = "Шығу"
	quit_btn.custom_minimum_size = Vector2(140, 44)
	quit_btn.add_theme_font_size_override("font_size", 16)
	quit_btn.add_theme_stylebox_override("normal", _card_style(Color(0.12,0.12,0.18,0.85)))
	quit_btn.add_theme_stylebox_override("hover", _card_style(Color(0.18,0.18,0.28,0.95)))
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
	var style := _card_style(Color(0.13,0.14,0.22,0.92) if unlocked else Color(0.08,0.08,0.12,0.85))
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	card.add_theme_stylebox_override("panel", style)

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
		stats.text = "🔒 Құлыпталған"
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
	btn.text = "Ойнау ▶" if unlocked else "🔒"
	btn.custom_minimum_size = Vector2(200, 42)
	btn.disabled = not unlocked
	btn.add_theme_font_size_override("font_size", 18)
	var btn_col := Color(data.get("sun_color", "#ffd166")) if unlocked else Color(0.2,0.2,0.22,1.0)
	btn.add_theme_color_override("font_color", Color("#1a1a2e"))
	var bstyle := _card_style(btn_col)
	bstyle.corner_radius_top_left = 10
	bstyle.corner_radius_top_right = 10
	bstyle.corner_radius_bottom_left = 10
	bstyle.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("normal", bstyle)
	var hstyle := _card_style(Color("#fff3b0") if unlocked else Color(0.22,0.22,0.24))
	hstyle.corner_radius_top_left = 10
	hstyle.corner_radius_top_right = 10
	hstyle.corner_radius_bottom_left = 10
	hstyle.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("hover", hstyle)
	btn.add_theme_stylebox_override("pressed", _card_style(Color("#e8a33d")))
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
		card.modulate = Color.WHITE
	)

	return card

func _card_style(bg: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = 14
	s.corner_radius_top_right = 14
	s.corner_radius_bottom_left = 14
	s.corner_radius_bottom_right = 14
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	s.border_color = Color(1,1,1,0.08)
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	return s

func _draw() -> void:
	# gradient sky + subtle hills behind UI
	var sz := size
	if sz.x < 10:
		sz = Vector2(1280, 720)
	# sky gradient
	var top_col := Color("#3a1c5c")
	var bot_col := Color("#ff9e5e")
	var strips := 16
	for i in range(strips):
		var t0 := float(i)/strips
		var col := top_col.lerp(bot_col, t0)
		var y0 := sz.y * t0 * 0.85
		var y1 := sz.y * (float(i+1)/strips) * 0.85
		draw_rect(Rect2(Vector2(0, y0), Vector2(sz.x, y1 - y0)), col)
	# sun
	var sun_pos := Vector2(sz.x * 0.78, 90) + Vector2(sin(_t*0.3)*8, cos(_t*0.4)*4)
	draw_circle(sun_pos, 52, Color("#ffd166", 0.18))
	draw_circle(sun_pos, 34, Color("#ffd166", 0.9))
	draw_circle(sun_pos + Vector2(-6,-6), 8, Color(1,1,1,0.4))
	# clouds parallax (slow drift)
	for i in range(4):
		var cx := fmod(_t * (12 + i*6) + i*320, sz.x + 200) - 100
		var cy := 110 + i*18 + sin(_t*0.4 + i)*6
		var alpha := 0.18 + i*0.04
		var c := Color(1,1,1,alpha)
		draw_circle(Vector2(cx, cy), 30, c)
		draw_circle(Vector2(cx+24, cy+4), 22, c)
		draw_circle(Vector2(cx-18, cy+6), 18, c)
	# far hills
	var hill_col := Color("#241a3f")
	var points := PackedVector2Array()
	var step := 40.0
	var x := -40.0
	while x <= sz.x + 40:
		var h := sin(x*0.008 + _t*0.05)*18 + sin(x*0.015)*12
		points.append(Vector2(x, sz.y*0.62 - h))
		x += step
	points.append(Vector2(sz.x+40, sz.y))
	points.append(Vector2(-40, sz.y))
	draw_polygon(points, PackedColorArray([hill_col]))
	# near hills
	var near_col := Color("#171233")
	var pts2 := PackedVector2Array()
	x = -40
	while x <= sz.x + 40:
		var h2 := sin(x*0.012)*22 + sin(x*0.006 + 1.2)*14
		pts2.append(Vector2(x, sz.y*0.72 - h2))
		x += step
	pts2.append(Vector2(sz.x+40, sz.y))
	pts2.append(Vector2(-40, sz.y))
	draw_polygon(pts2, PackedColorArray([near_col]))
	# ground line
	draw_line(Vector2(0, sz.y*0.72), Vector2(sz.x, sz.y*0.72), Color(1,1,1,0.06), 2.0)
