extends Area2D

const ICON = preload("res://assets/sprites/heart.png")
## Heart pickup — heals one heart.

signal collected(pos: Vector2)

var _t: float = 0.0
var _base_y: float = 0.0
var _taken: bool = false


func _ready() -> void:
	add_to_group("hearts_pickup")
	collision_layer = 1 << 3
	collision_mask = 1 << 1
	monitoring = true
	monitorable = false
	_base_y = position.y
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	col.shape = shape
	add_child(col)
	body_entered.connect(_on_body)


func _process(delta: float) -> void:
	_t += delta
	if _taken:
		return
	position.y = _base_y + sin(_t * 2.0) * 7.0
	scale = Vector2.ONE * (1.0 + 0.08 * sin(_t * 5.0))
	rotation = sin(_t * 0.9) * 0.07
	queue_redraw()


func _on_body(body: Node) -> void:
	if _taken:
		return
	if body.is_in_group("player"):
		if body.has_method("hurt"):
			# only collect if not full — but allow anyway and waste? Better only if needed.
			# Check hearts
			if "hearts" in body and "MAX_HEARTS" in body:
				if body.hearts >= body.MAX_HEARTS:
					# still collect for points, but don't heal beyond max — just give coin-like effect
					pass
			_taken = true
			collected.emit(global_position)
			SFX.play("heart")
			var tw := create_tween()
			tw.set_parallel(true)
			tw.tween_property(self, "scale", Vector2(1.5, 1.5), 0.16)
			tw.tween_property(self, "modulate:a", 0.0, 0.18)
			# heal player
			if body.has_method("hurt") and "hearts" in body:
				body.hearts = mini(body.hearts + 1, body.MAX_HEARTS)
			tw.chain().tween_callback(queue_free)


func _draw() -> void:
	draw_texture_rect(ICON, Rect2(-20, -20, 40, 40), false)
