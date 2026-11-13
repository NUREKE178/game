extends Area2D

const ICON = preload("res://assets/sprites/coin.png")
## Shiny coin — bobs and spins, disappears with a pop when touched.

signal collected(pos: Vector2)

var _t: float = 0.0
var _collected: bool = false
var _base_y: float = 0.0

const RADIUS := 20.0


func _ready() -> void:
	add_to_group("coins")
	collision_layer = 1 << 3
	collision_mask = 1 << 1
	monitoring = true
	monitorable = false
	_base_y = position.y
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = RADIUS
	col.shape = shape
	add_child(col)
	body_entered.connect(_on_body)
	area_entered.connect(_on_area)


func _process(delta: float) -> void:
	_t += delta
	if _collected:
		return
	# bob + spin squash
	position.y = _base_y + sin(_t * 2.4) * 6.0
	var squish := 1.0 + 0.14 * sin(_t * 6.0)
	scale = Vector2(squish, 1.0 / squish)
	rotation = sin(_t * 1.2) * 0.08
	queue_redraw()


func _on_body(body: Node) -> void:
	if body.is_in_group("player"):
		_collect()


func _on_area(area: Area2D) -> void:
	if area.is_in_group("player_hitbox"):
		_collect()


func _collect() -> void:
	if _collected:
		return
	_collected = true
	collected.emit(global_position)
	SFX.play("coin")
	# pop animation
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.6, 1.6), 0.14)
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(queue_free)


func _draw() -> void:
	draw_texture_rect(ICON, Rect2(-20, -20, 40, 40), false)
