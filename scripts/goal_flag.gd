extends Area2D
## Goal flag — touching it wins the level.

signal reached

const FLAG = preload("res://assets/sprites/flag.png")
var _t: float = 0.0
var _reached := false

func _ready() -> void:
	collision_layer = 1 << 3
	collision_mask = 1 << 1
	monitoring = true
	monitorable = false
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(44.0, 72.0)
	col.shape = shape
	col.position = Vector2(0.0, -10.0)
	add_child(col)
	body_entered.connect(_on_body)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _on_body(body: Node) -> void:
	if body.is_in_group("player") and not _reached:
		_reached = true
		reached.emit()
		set_deferred("monitoring", false)


func _draw() -> void:
	draw_texture_rect(FLAG, Rect2(-20, -44, 64, 72), false)
