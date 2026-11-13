extends Area2D
## Spikes — hurt the player on touch.

func _ready() -> void:
	collision_layer = 1 << 4
	collision_mask = 1 << 1
	monitoring = true
	monitorable = false
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(48.0, 22.0)
	col.shape = shape
	col.position = Vector2(0.0, 6.0)
	add_child(col)
	body_entered.connect(_on_body)
	# also check continuously for dashing player
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			_try_hurt(body)


func _on_body(body: Node) -> void:
	if body.is_in_group("player"):
		_try_hurt(body)


func _try_hurt(player: Node) -> void:
	if player.has_method("hurt"):
		# don't hurt if player is dashing — dash is invincible
		if "is_dashing" in player and player.is_dashing():
			return
		player.hurt(global_position)


func _draw() -> void:
	# base bar
	draw_rect(Rect2(Vector2(-24.0, 10.0), Vector2(48.0, 8.0)), Color("#3a2a1a"))
	# spikes
	for i in range(3):
		var x := -16.0 + i * 16.0
		var pts := PackedVector2Array([
			Vector2(x - 7.0, 10.0),
			Vector2(x, -10.0),
			Vector2(x + 7.0, 10.0),
		])
		draw_polygon(pts, PackedColorArray([Color("#c1121f")]))
		draw_polygon(
			PackedVector2Array([Vector2(x - 4.0, 6.0), Vector2(x, -4.0), Vector2(x + 4.0, 6.0)]),
			PackedColorArray([Color("#e8a0a8")])
		)
	# glow
	draw_circle(Vector2(0.0, 0.0), 18.0, Color("#c1121f", 0.08))
