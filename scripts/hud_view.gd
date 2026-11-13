extends Control
## Heads-up display drawn procedurally: hearts, coins, timer, level name,
## dash cooldown. No image assets required.

var hearts: int = 3
var max_hearts: int = 3
var coins: int = 0
var coins_total: int = 0
var time_text: String = "00:00"
var level_text: String = ""
var dash_fill: float = 1.0

const HEART_COLOR := Color("#ff5d73")
const HEART_EMPTY := Color(0.25, 0.16, 0.22, 0.85)
const GOLD := Color("#ffd166")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func set_values(p_hearts: int, p_coins: int, p_coins_total: int, p_time: String, p_level: String, p_dash: float) -> void:
	hearts = p_hearts
	coins = p_coins
	coins_total = p_coins_total
	time_text = p_time
	level_text = p_level
	dash_fill = p_dash
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()

	# ---------------- hearts (top-left)
	for i in range(max_hearts):
		var c := Vector2(44.0 + i * 52.0, 42.0)
		if i < hearts:
			_draw_heart(c, 17.0, HEART_COLOR)
		else:
			_draw_heart(c, 17.0, HEART_EMPTY)

	# ---------------- coins (top-left, under hearts)
	var coin_c := Vector2(42.0, 100.0)
	draw_circle(coin_c, 15.0, GOLD)
	draw_circle(coin_c, 10.5, Color("#e8a33d"))
	draw_circle(coin_c, 10.5, Color("#e8a33d"), false, 2.0)
	_draw_star(coin_c, 5.0, Color("#fff3b0"))
	draw_string(font, Vector2(66.0, 108.0), "%d / %d" % [coins, coins_total], HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("#fff3b0"))

	# ---------------- level name (top-center)
	var w := size.x
	draw_string(font, Vector2(0.0, 40.0), level_text, HORIZONTAL_ALIGNMENT_CENTER, w, 26, Color(1.0, 1.0, 1.0, 0.9))

	# ---------------- timer (top-right)
	draw_string(font, Vector2(w - 300.0, 40.0), time_text, HORIZONTAL_ALIGNMENT_RIGHT, 260.0, 30, Color(1.0, 1.0, 1.0, 0.9))

	# ---------------- dash cooldown (bottom-left)
	var bar_pos := Vector2(28.0, size.y - 46.0)
	var bar_size := Vector2(180.0, 14.0)
	_draw_rounded(bar_pos, bar_size, 7.0, Color(0.0, 0.0, 0.0, 0.45))
	var fill_w := maxf(0.0, (bar_size.x - 6.0) * dash_fill)
	if fill_w > 2.0:
		var col: Color = GOLD if dash_fill >= 1.0 else Color(0.55, 0.75, 0.9, 0.95)
		_draw_rounded(bar_pos + Vector2(3.0, 3.0), Vector2(fill_w, bar_size.y - 6.0), 5.0, col)
	draw_string(font, bar_pos + Vector2(0.0, -6.0), "ЗЫМЫРАУ" if dash_fill >= 1.0 else "зымырау…", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, GOLD if dash_fill >= 1.0 else Color(1, 1, 1, 0.6))


func _draw_heart(c: Vector2, s: float, color: Color) -> void:
	# two circles + triangle
	draw_circle(c + Vector2(-s * 0.45, -s * 0.18), s * 0.52, color)
	draw_circle(c + Vector2(s * 0.45, -s * 0.18), s * 0.52, color)
	draw_polygon(
		PackedVector2Array([
			c + Vector2(-s * 0.92, s * 0.08),
			c + Vector2(s * 0.92, s * 0.08),
			c + Vector2(0.0, s * 1.05),
		]),
		PackedColorArray([color])
	)
	# shine
	if color == HEART_COLOR:
		draw_circle(c + Vector2(-s * 0.5, -s * 0.35), s * 0.16, Color(1.0, 1.0, 1.0, 0.65))


func _draw_star(c: Vector2, r: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(10):
		var angle := -PI / 2.0 + i * PI / 5.0
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(angle), sin(angle)) * rr)
	draw_polygon(pts, PackedColorArray([color]))


func _draw_rounded(pos: Vector2, sz: Vector2, r: float, color: Color) -> void:
	var rr := minf(r, minf(sz.x, sz.y) * 0.5)
	draw_rect(Rect2(pos + Vector2(rr, 0.0), Vector2(sz.x - 2.0 * rr, sz.y)), color)
	draw_rect(Rect2(pos + Vector2(0.0, rr), Vector2(sz.x, sz.y - 2.0 * rr)), color)
	draw_circle(pos + Vector2(rr, rr), rr, color)
	draw_circle(pos + Vector2(sz.x - rr, rr), rr, color)
	draw_circle(pos + Vector2(rr, sz.y - rr), rr, color)
	draw_circle(pos + Vector2(sz.x - rr, sz.y - rr), rr, color)
