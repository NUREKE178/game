extends Node2D
## Main game scene — builds the level from ASCII, handles camera,
## collisions, HUD, juice and win/lose flow. No external assets.

const TILE := 64
const MAP_W := 148
const MAP_H := 17
const WORLD_W := MAP_W * TILE
const WORLD_H := MAP_H * TILE

# Preloads
const PlayerScript = preload("res://scripts/player.gd")
const SlimeScript = preload("res://scripts/slime.gd")
const CoinScript = preload("res://scripts/coin.gd")
const HeartScript = preload("res://scripts/heart_pickup.gd")
const SpringScript = preload("res://scripts/spring_pad.gd")
const CheckpointScript = preload("res://scripts/checkpoint.gd")
const GoalScript = preload("res://scripts/goal_flag.gd")
const SpikeScript = preload("res://scripts/spike.gd")
const HudScript = preload("res://scripts/hud_view.gd")
const ParallaxScript = preload("res://scripts/parallax_bg.gd")
# Force Levels class to be loaded (class_name is global but preload guarantees it)
const _LevelsPreload = preload("res://scripts/levels.gd")

var level_index: int = 0
var level_data: Dictionary = {}
var rows: Array[String] = []

var player: CharacterBody2D = null
var cam: Camera2D = null
var parallax: Node2D = null
var tiles_body: StaticBody2D = null
var entities: Node2D = null
var hud: Control = null
var ui_layer: CanvasLayer = null

var spawn_pos: Vector2 = Vector2.ZERO
var checkpoint_pos: Vector2 = Vector2.ZERO
var goal_pos: Vector2 = Vector2.ZERO

var coins_total: int = 0
var coins_got: int = 0
var start_time: float = 0.0
var level_done: bool = false
var paused: bool = false
var shake_t: float = 0.0
var shake_amt: float = 0.0

# Overlays
var pause_overlay: Control = null
var win_overlay: Control = null
var lose_overlay: Control = null

# For tile drawing
var _solid_cells: Array[Vector2i] = []


func _ready() -> void:
	level_index = Game.current_level
	level_data = Levels.get_level(level_index)
	rows = Levels.parse_map(level_data)

	# --- camera
	cam = Camera2D.new()
	cam.name = "Camera2D"
	cam.enabled = true
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	cam.limit_smoothed = true
	cam.limit_left = 0
	cam.limit_right = WORLD_W
	cam.limit_top = -220
	cam.limit_bottom = WORLD_H + 220
	cam.zoom = Vector2.ONE
	add_child(cam)

	# --- parallax
	parallax = Node2D.new()
	parallax.name = "ParallaxBG"
	parallax.z_index = -100
	parallax.set_script(ParallaxScript)
	add_child(parallax)
	parallax.set_level(level_data)

	# --- tiles physics body
	tiles_body = StaticBody2D.new()
	tiles_body.name = "Tiles"
	tiles_body.collision_layer = 1
	tiles_body.collision_mask = 0
	tiles_body.z_index = 0
	add_child(tiles_body)

	# --- entities container
	entities = Node2D.new()
	entities.name = "Entities"
	entities.z_index = 5
	add_child(entities)

	# --- UI
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	ui_layer.layer = 10
	add_child(ui_layer)

	hud = Control.new()
	hud.name = "HUD"
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.set_script(HudScript)
	ui_layer.add_child(hud)

	_build_level()
	_build_overlays()

	start_time = Time.get_ticks_msec() / 1000.0
	checkpoint_pos = spawn_pos
	# place camera initially
	cam.global_position = spawn_pos
	# connect player signals after build
	if player:
		player.jumped.connect(_on_player_jumped)
		player.double_jumped.connect(_on_player_double_jumped)
		player.dashed.connect(_on_player_dashed)
		player.landed.connect(_on_player_landed)
		player.hurt_taken.connect(_on_player_hurt)
		player.died.connect(_on_player_died)
		player.bounced.connect(_on_player_bounced)


# ==================================================================
# Level building
# ==================================================================
func _build_level() -> void:
	_solid_cells.clear()
	coins_total = 0
	var to_spawn: Array[Dictionary] = []

	for y in range(rows.size()):
		var row: String = rows[y]
		for x in range(row.length()):
			var ch: String = row[x]
			var world_pos := Vector2(x * TILE + TILE * 0.5, y * TILE + TILE * 0.5)
			match ch:
				"#":
					_solid_cells.append(Vector2i(x, y))
				"P":
					spawn_pos = world_pos
					# also ensure there's ground below for visual — already is
				"G":
					goal_pos = world_pos
					to_spawn.append({"kind": "goal", "pos": world_pos})
				"S":
					to_spawn.append({"kind": "slime", "pos": world_pos})
				"o":
					coins_total += 1
					to_spawn.append({"kind": "coin", "pos": world_pos})
				"h":
					to_spawn.append({"kind": "heart", "pos": world_pos})
				"b":
					# spring sits on top of ground — offset up by 20
					to_spawn.append({"kind": "spring", "pos": world_pos + Vector2(0, 14)})
				"C":
					to_spawn.append({"kind": "checkpoint", "pos": world_pos})
				"^":
					to_spawn.append({"kind": "spike", "pos": world_pos + Vector2(0, 14)})
				"T", "Y", "R":
					to_spawn.append({"kind": "decor", "pos": world_pos, "type": ch})
				".":
					pass
				_:
					pass

	# build physics — merge horizontal runs
	for y in range(MAP_H):
		var x := 0
		while x < MAP_W:
			if Vector2i(x, y) in _solid_cells:
				var x0 := x
				while x < MAP_W and Vector2i(x, y) in _solid_cells:
					x += 1
				var x1 := x - 1
				var n := x1 - x0 + 1
				var center := Vector2(x0 * TILE + n * TILE * 0.5, y * TILE + TILE * 0.5)
				var col := CollisionShape2D.new()
				var shape := RectangleShape2D.new()
				shape.size = Vector2(n * TILE, TILE)
				col.shape = shape
				col.position = center
				tiles_body.add_child(col)
			else:
				x += 1

	# visual tile drawer
	var tile_visual := Node2D.new()
	tile_visual.name = "TileVisual"
	tile_visual.z_index = 1
	tile_visual.set_script(_tile_visual_script())
	tile_visual.set_meta("cells", _solid_cells)
	tile_visual.set_meta("level", level_index)
	tiles_body.add_child(tile_visual)
	# keep tiles_body's own position at 0,0 — shapes already in world coords
	# move child visual to 0,0 as well
	tile_visual.position = Vector2.ZERO

	# spawn entities
	for entry in to_spawn:
		var kind: String = entry["kind"]
		var pos: Vector2 = entry["pos"]
		match kind:
			"slime":
				_spawn_slime(pos)
			"coin":
				_spawn_coin(pos)
			"heart":
				_spawn_heart(pos)
			"spring":
				_spawn_spring(pos)
			"checkpoint":
				_spawn_checkpoint(pos)
			"goal":
				_spawn_goal(pos)
			"spike":
				_spawn_spike(pos)
			"decor":
				_spawn_decor(pos, entry["type"])

	# spawn player last (on top)
	_spawn_player(spawn_pos)

	# floor killer — invisible area below world to catch pit falls
	var killer := Area2D.new()
	killer.name = "PitKiller"
	killer.collision_layer = 0
	killer.collision_mask = 1 << 1
	killer.monitoring = true
	var killer_col := CollisionShape2D.new()
	var killer_shape := RectangleShape2D.new()
	killer_shape.size = Vector2(WORLD_W, 400.0)
	killer_col.shape = killer_shape
	killer_col.position = Vector2(WORLD_W * 0.5, WORLD_H + 300.0)
	killer.add_child(killer_col)
	killer.body_entered.connect(_on_pit_enter)
	entities.add_child(killer)

	queue_redraw()


func _spawn_player(pos: Vector2) -> void:
	var p := CharacterBody2D.new()
	p.name = "Player"
	p.global_position = pos
	p.collision_layer = 1 << 1
	p.collision_mask = 1  # world only — enemies handled via rect checks
	p.set_script(PlayerScript)
	# collision shape
	var col := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 14.0
	shape.height = 22.0
	col.shape = shape
	col.position = Vector2(0, 4.0)
	p.add_child(col)
	entities.add_child(p)
	player = p


func _spawn_slime(pos: Vector2) -> void:
	var s := CharacterBody2D.new()
	s.name = "Slime"
	s.global_position = pos + Vector2(0, 10)
	s.collision_layer = 1 << 2
	s.collision_mask = 1
	s.set_script(SlimeScript)
	var col := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 14.0
	shape.height = 12.0
	col.shape = shape
	col.position = Vector2(0, 6)
	s.add_child(col)
	entities.add_child(s)


func _spawn_coin(pos: Vector2) -> void:
	var c := Area2D.new()
	c.name = "Coin"
	c.position = pos
	c.set_script(CoinScript)
	var cb := Callable(self, "_on_coin_collected")
	c.collected.connect(func(p): cb.call(p))
	entities.add_child(c)


func _spawn_heart(pos: Vector2) -> void:
	var h := Area2D.new()
	h.name = "Heart"
	h.position = pos
	h.set_script(HeartScript)
	h.collected.connect(_on_heart_collected)
	entities.add_child(h)


func _spawn_spring(pos: Vector2) -> void:
	var b := Area2D.new()
	b.name = "Spring"
	b.position = pos
	b.set_script(SpringScript)
	entities.add_child(b)


func _spawn_checkpoint(pos: Vector2) -> void:
	var cp := Area2D.new()
	cp.name = "Checkpoint"
	cp.position = pos
	cp.set_script(CheckpointScript)
	cp.activated.connect(_on_checkpoint)
	entities.add_child(cp)


func _spawn_goal(pos: Vector2) -> void:
	var g := Area2D.new()
	g.name = "Goal"
	g.position = pos
	g.set_script(GoalScript)
	g.reached.connect(_on_goal)
	entities.add_child(g)


func _spawn_spike(pos: Vector2) -> void:
	var sp := Area2D.new()
	sp.name = "Spike"
	sp.position = pos
	sp.set_script(SpikeScript)
	entities.add_child(sp)


func _spawn_decor(pos: Vector2, type: String) -> void:
	var d := Node2D.new()
	d.position = pos
	d.z_index = 0
	d.set_meta("decor_type", type)
	d.set_script(_decor_script())
	entities.add_child(d)


# ==================================================================
# Visual scripts (inner)
# ==================================================================
func _tile_visual_script() -> GDScript:
	var s := GDScript.new()
	s.source_code = """
extends Node2D
func _draw() -> void:
\tvar cells: Array = get_meta("cells")
\tvar lvl: int = int(get_meta("level"))
\t# palette per level
\tvar palettes := [
\t\t[Color("#6b4c2a"), Color("#a07a3a"), Color("#d9b36a"), Color("#fff3b0")],
\t\t[Color("#4a3a2a"), Color("#8a6a3a"), Color("#d9b36a"), Color("#fff3b0")],
\t\t[Color("#2a2a5a"), Color("#5a4a9a"), Color("#8a7ac6"), Color("#c8b6ff")],
\t]
\tvar pal: Array = palettes[clampi(lvl, 0, 2)]
\tvar base_col: Color = pal[0]
\tvar mid_col: Color = pal[1]
\tvar top_col: Color = pal[2]
\tvar hl_col: Color = pal[3]
\tvar TILE := 64.0
\tfor cell in cells:
\t\tvar x: int = cell.x
\t\tvar y: int = cell.y
\t\tvar px := x * TILE
\t\tvar py := y * TILE
\t\t# shadow
\t\tdraw_rect(Rect2(Vector2(px + 3, py + 3), Vector2(TILE, TILE)), Color(0, 0, 0, 0.18))
\t\t# base
\t\tdraw_rect(Rect2(Vector2(px, py), Vector2(TILE, TILE)), base_col)
\t\t# top bevel
\t\tdraw_rect(Rect2(Vector2(px, py), Vector2(TILE, TILE * 0.32)), top_col)
\t\tdraw_rect(Rect2(Vector2(px, py + TILE * 0.32), Vector2(TILE, TILE * 0.18)), mid_col)
\t\t# highlight line
\t\tdraw_line(Vector2(px + 3, py + 3), Vector2(px + TILE - 3, py + 3), Color(1,1,1,0.35), 2.0)
\t\tdraw_line(Vector2(px + 3, py + 3), Vector2(px + 3, py + TILE - 3), Color(1,1,1,0.15), 2.0)
\t\t# ornament — small diamond on top edge every 2 tiles
\t\tif (x + y) % 3 == 0:
\t\t\tvar cx := px + TILE * 0.5
\t\t\tvar cy := py + TILE * 0.22
\t\t\tvar pts := PackedVector2Array([Vector2(cx, cy-4), Vector2(cx+5, cy), Vector2(cx, cy+4), Vector2(cx-5, cy)])
\t\t\tdraw_polygon(pts, PackedColorArray([hl_col]))
"""
	s.reload()
	return s


func _decor_script() -> GDScript:
	var s := GDScript.new()
	s.source_code = """
extends Node2D
var _t: float = 0.0
func _ready() -> void:
\t_t = randf() * 6.28
func _process(delta: float) -> void:
\t_t += delta
\tqueue_redraw()
func _draw() -> void:
\tvar type: String = get_meta("decor_type")
\tvar sway := sin(_t * 0.9) * 2.0
\tmatch type:
\t\t"T":
\t\t\t# saxaul tree — gnarled steppe tree
\t\t\tdraw_rect(Rect2(Vector2(-5, 6), Vector2(10, 18)), Color("#5a3a1a"))
\t\t\tdraw_rect(Rect2(Vector2(-3, -2), Vector2(6, 12)), Color("#6b4c2a"))
\t\t\t# foliage clumps
\t\t\tdraw_circle(Vector2(sway, -12), 18, Color("#4a7a3a"))
\t\t\tdraw_circle(Vector2(-10, -8), 14, Color("#5a8a4a"))
\t\t\tdraw_circle(Vector2(12, -6), 15, Color("#3d6b2e"))
\t\t\tdraw_circle(Vector2(sway*0.5, -20), 10, Color("#6a9a5a"))
\t\t\t# fruit dots
\t\t\tdraw_circle(Vector2(6, -14), 2, Color("#e63946"))
\t\t\tdraw_circle(Vector2(-8, -10), 1.8, Color("#e63946"))
\t\t"Y":
\t\t\t# yurt — white felt house
\t\t\tdraw_rect(Rect2(Vector2(-20, 2), Vector2(40, 18)), Color("#e8dcc0"))
\t\t\tdraw_rect(Rect2(Vector2(-18, 6), Vector2(36, 10)), Color("#d4a574"))
\t\t\t# dome
\t\t\tvar pts := PackedVector2Array([Vector2(-20, 2), Vector2(0, -14), Vector2(20, 2)])
\t\t\tdraw_polygon(pts, PackedColorArray([Color("#fff8e0")]))
\t\t\tdraw_polygon(PackedVector2Array([Vector2(-14, 2), Vector2(0, -8), Vector2(14, 2)]), PackedColorArray([Color("#ffd166")]))
\t\t\t# door
\t\t\tdraw_rect(Rect2(Vector2(-6, 8), Vector2(12, 12)), Color("#6b4c2a"))
\t\t\tdraw_circle(Vector2(3, 14), 1.2, Color("#ffd166"))
\t\t\t# pattern
\t\t\tdraw_line(Vector2(-20, 6), Vector2(20, 6), Color("#2ec4b6"), 1.5)
\t\t"R":
\t\t\t# rock
\t\t\tdraw_circle(Vector2(0, 10), 14, Color("#7a6a5a"))
\t\t\tdraw_circle(Vector2(-6, 6), 10, Color("#8a7a6a"))
\t\t\tdraw_circle(Vector2(7, 8), 8, Color("#6a5a4a"))
\t\t\tdraw_circle(Vector2(-4, 2), 2, Color(1,1,1,0.2))
"""
	s.reload()
	return s


# ==================================================================
# Main loop — camera, HUD, interactions
# ==================================================================
func _process(delta: float) -> void:
	if level_done:
		return
	if paused:
		return
	# timer text
	var elapsed := Time.get_ticks_msec() / 1000.0 - start_time
	var mins := int(elapsed) / 60
	var secs := int(elapsed) % 60
	var time_text := "%02d:%02d" % [mins, secs]
	var dash_fill := 1.0
	if player:
		dash_fill = player.dash_ready()
		# camera follow — smooth via Camera2D smoothing, but also nudge to look ahead
		var target := player.global_position + Vector2(player.facing * 120.0, -60.0)
		cam.global_position = target
		if parallax:
			parallax.set_camera_x(cam.global_position.x)
		# keep player in bounds horizontally — soft wall at level edges
		player.global_position.x = clampf(player.global_position.x, 22.0, WORLD_W - 22.0)

		if hud:
			var lvl_name: String = level_data.get("name", "")
			hud.set_values(player.hearts if player else 0, coins_got, coins_total, time_text, lvl_name, dash_fill)

	# screen shake decay
	if shake_t > 0.0:
		shake_t -= delta
		var s := shake_amt * (shake_t / 0.35)
		cam.offset = Vector2(randf_range(-s, s), randf_range(-s, s))
		if shake_t <= 0.0:
			cam.offset = Vector2.ZERO
			shake_amt = 0.0

	_check_enemy_interactions()
	_check_pit_fall()


func _physics_process(_delta: float) -> void:
	# handle pause input
	if Input.is_action_just_pressed("pause") and not level_done:
		if not paused:
			_pause_game()
		else:
			_resume_game()


func _check_enemy_interactions() -> void:
	if not player or player.dead:
		return
	var p_rect: Rect2 = player.get_hurt_rect()
	var p_vel_y: float = player.velocity.y
	for child in entities.get_children():
		if child is CharacterBody2D and child.is_in_group("enemies"):
			if child.get("dead"):
				continue
			var e_rect: Rect2 = child.get_hurt_rect()
			if p_rect.intersects(e_rect):
				# stomp if falling and player bottom is above enemy top
				var player_bottom := p_rect.position.y + p_rect.size.y
				var enemy_top := e_rect.position.y
				if p_vel_y > 80.0 and player_bottom < enemy_top + 16.0:
					_stomp_enemy(child)
				else:
					# hurt player
					if not player.is_dashing():
						var hurt := player.hurt(child.global_position)
						if hurt:
							_screen_shake(10.0, 0.28)


func _stomp_enemy(enemy: Node) -> void:
	enemy.stomp()
	SFX.play("stomp")
	if player:
		player.bounce()
	_screen_shake(6.0, 0.18)
	_spawn_confetti(enemy.global_position, Color("#ffd166"), 10)
	# tiny squash on player already done in bounce()


func _check_pit_fall() -> void:
	if not player or level_done:
		return
	if player.global_position.y > WORLD_H + 400.0:
		_on_pit_enter(player)


func _on_pit_enter(body: Node) -> void:
	if body.is_in_group("player") and not level_done:
		if player.pit_fall():
			# died from pit
			pass
		else:
			# respawn at checkpoint with a poof
			SFX.play("hurt")
			_screen_shake(12.0, 0.35)
			player.global_position = checkpoint_pos
			player.velocity = Vector2.ZERO
			_spawn_confetti(checkpoint_pos, Color("#ff5d73"), 8)


# ==================================================================
# Player signal handlers
# ==================================================================
func _on_player_jumped() -> void:
	SFX.play("jump")
	_spawn_dust(player.global_position + Vector2(0, 16), 5)

func _on_player_double_jumped() -> void:
	SFX.play("double_jump")
	_spawn_confetti(player.global_position, Color("#7de2d1"), 6)

func _on_player_dashed(dir: float) -> void:
	SFX.play("dash")
	_screen_shake(5.0, 0.14)
	_spawn_dash_afterimage(dir)

func _on_player_landed(_fall_speed: float) -> void:
	_spawn_dust(player.global_position + Vector2(0, 18), 6)
	_screen_shake(3.0, 0.12)

func _on_player_hurt(_from_pos: Vector2) -> void:
	SFX.play("hurt")
	_screen_shake(9.0, 0.30)
	_spawn_confetti(player.global_position, Color("#ff5d73"), 8)
	# update HUD immediately
	if hud and player:
		hud.set_values(player.hearts, coins_got, coins_total, "", level_data.get("name", ""), player.dash_ready())

func _on_player_died() -> void:
	# small delay then show game over
	await get_tree().create_timer(0.7).timeout
	_show_lose()

func _on_player_bounced() -> void:
	_spawn_confetti(player.global_position + Vector2(0, 10), Color("#fff3b0"), 6)

func _on_coin_collected(pos: Vector2) -> void:
	coins_got += 1
	_spawn_confetti(pos, Color("#ffd166"), 7)
	_spawn_floating_text(pos, "+1")

func _on_heart_collected(pos: Vector2) -> void:
	_spawn_confetti(pos, Color("#ff5d73"), 8)
	_spawn_floating_text(pos, "+❤")

func _on_checkpoint(pos: Vector2) -> void:
	checkpoint_pos = pos
	_spawn_confetti(pos, Color("#2ec4b6"), 10)

func _on_goal() -> void:
	if level_done:
		return
	level_done = true
	if player:
		player.input_locked = true
		player.velocity = Vector2.ZERO
	SFX.play("goal")
	# star calc: 1 for finish, 1 for >=50% coins, 1 for all coins
	var stars := 1
	if coins_total > 0:
		if coins_got >= coins_total * 0.5:
			stars += 1
		if coins_got == coins_total:
			stars += 1
	else:
		stars = 3
	var elapsed := Time.get_ticks_msec() / 1000.0 - start_time
	Game.record_result(level_index, coins_got, stars, elapsed)
	await get_tree().create_timer(0.9).timeout
	_show_win(stars, elapsed)


# ==================================================================
# Juice — particles, shake, afterimage, floating text
# ==================================================================
func _screen_shake(amount: float, dur: float) -> void:
	shake_amt = maxf(shake_amt, amount)
	shake_t = maxf(shake_t, dur)

func _spawn_dust(pos: Vector2, count: int) -> void:
	for i in range(count):
		var n := Node2D.new()
		n.global_position = pos + Vector2(randf_range(-10, 10), randf_range(-2, 4))
		n.z_index = 6
		var vel := Vector2(randf_range(-80, 80), randf_range(-120, -30))
		n.set_meta("vel", vel)
		n.set_meta("life", 0.32)
		n.set_script(_dust_script())
		entities.add_child(n)
		var tw := n.create_tween()
		tw.tween_callback(func(): pass)

func _dust_script() -> GDScript:
	var s := GDScript.new()
	s.source_code = """
extends Node2D
var _t: float = 0.0
func _process(delta: float) -> void:
\t_t += delta
\tvar life: float = get_meta("life")
\tif _t > life:
\t\tqueue_free()
\t\treturn
\tposition += get_meta("vel") * delta
\tget_meta("vel").y += 420.0 * delta
\tmodulate.a = 1.0 - _t / life
\tqueue_redraw()
func _draw() -> void:
\tdraw_circle(Vector2.ZERO, 2.5, Color(1,1,1,0.65))
"""
	s.reload()
	return s

func _spawn_confetti(pos: Vector2, col: Color, count: int) -> void:
	for i in range(count):
		var n := Node2D.new()
		n.global_position = pos
		n.z_index = 20
		var ang := randf() * TAU
		var spd := randf_range(90, 260)
		var vel := Vector2(cos(ang), sin(ang)) * spd + Vector2(0, -80)
		n.set_meta("vel", vel)
		n.set_meta("life", randf_range(0.35, 0.65))
		n.set_meta("col", col)
		n.set_meta("sz", randf_range(2.5, 5.0))
		n.set_script(_confetti_script())
		get_tree().current_scene.add_child(n)

func _confetti_script() -> GDScript:
	var s := GDScript.new()
	s.source_code = """
extends Node2D
var _t: float = 0.0
func _process(delta: float) -> void:
\t_t += delta
\tvar life: float = get_meta("life")
\tif _t > life:
\t\tqueue_free()
\t\treturn
\tposition += get_meta("vel") * delta
\tget_meta("vel").y += 900.0 * delta
\tget_meta("vel").x *= 1.0 - delta * 1.5
\trotation += delta * 8.0
\tmodulate.a = 1.0 - _t / life
\tqueue_redraw()
func _draw() -> void:
\tvar col: Color = get_meta("col")
\tvar sz: float = get_meta("sz")
\tdraw_rect(Rect2(Vector2(-sz, -sz*0.4), Vector2(sz*2, sz*0.8)), col)
"""
	s.reload()
	return s

func _spawn_dash_afterimage(dir: float) -> void:
	if not player:
		return
	for i in range(3):
		var a := Node2D.new()
		a.global_position = player.global_position - Vector2(dir * i * 18.0, 0)
		a.z_index = 4
		a.modulate = Color(1, 1, 1, 0.55 - i * 0.15)
		a.set_meta("life", 0.18 - i * 0.04)
		# copy player visual via simple circle
		a.set_script(_afterimage_script())
		get_tree().current_scene.add_child(a)
		# auto free
		var timer := Timer.new()
		timer.wait_time = 0.2
		timer.one_shot = true
		timer.timeout.connect(a.queue_free)
		a.add_child(timer)
		timer.start()

func _afterimage_script() -> GDScript:
	var s := GDScript.new()
	s.source_code = """
extends Node2D
var _t: float = 0.0
func _process(delta: float) -> void:
\t_t += delta
\tmodulate.a = maxf(0.0, modulate.a - delta * 3.0)
\tif _t > get_meta("life"):
\t\tqueue_free()
\tqueue_redraw()
func _draw() -> void:
\tdraw_circle(Vector2.ZERO, 18, Color(1, 0.84, 0.4, 0.25))
"""
	s.reload()
	return s

func _spawn_floating_text(pos: Vector2, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.global_position = pos + Vector2(-12, -28)
	l.z_index = 50
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", Color("#fff3b0"))
	l.add_theme_color_override("font_outline_color", Color(0,0,0,0.7))
	l.add_theme_constant_override("outline_size", 6)
	get_tree().current_scene.add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "global_position:y", l.global_position.y - 36.0, 0.7).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.7)
	tw.chain().tween_callback(l.queue_free)


# ==================================================================
# Overlays — pause / win / lose (built via code)
# ==================================================================
func _build_overlays() -> void:
	pause_overlay = _make_overlay("ТОҚТАТЫЛДЫ", Color(0.07, 0.08, 0.16, 0.88))
	win_overlay = _make_overlay("ЖЕҢІС!", Color(0.09, 0.18, 0.12, 0.92))
	lose_overlay = _make_overlay("ОЙ, ҚАП!", Color(0.18, 0.08, 0.10, 0.92))
	for o in [pause_overlay, win_overlay, lose_overlay]:
		o.visible = false
		ui_layer.add_child(o)

	# pause buttons
	_add_button(pause_overlay, "Жалғастыру", _resume_game)
	_add_button(pause_overlay, "Қайта ойнау", _retry_level)
	_add_button(pause_overlay, "Мәзір", func(): Game.goto_menu())

	# lose buttons
	_add_button(lose_overlay, "Қайта көру", _retry_level)
	_add_button(lose_overlay, "Мәзір", func(): Game.goto_menu())

	# win buttons added dynamically in _show_win


func _make_overlay(title: String, bg: Color) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg_rect := ColorRect.new()
	bg_rect.color = bg
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg_rect)
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(520, 0)
	vbox.position = Vector2(-260, -200)
	root.add_child(vbox)
	var label := Label.new()
	label.name = "Title"
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 56)
	label.add_theme_color_override("font_color", Color("#ffd166"))
	label.add_theme_color_override("font_outline_color", Color(0,0,0,0.8))
	label.add_theme_constant_override("outline_size", 8)
	vbox.add_child(label)
	var sub := Label.new()
	sub.name = "Subtitle"
	sub.text = ""
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(1,1,1,0.85))
	vbox.add_child(sub)
	vbox.add_child(Control.new()) # spacer
	return root

func _add_button(overlay: Control, text: String, cb: Callable) -> void:
	var vbox: VBoxContainer = overlay.get_child(2) as VBoxContainer
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(320, 52)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color("#1a1a2e"))
	btn.add_theme_color_override("font_hover_color", Color("#1a1a2e"))
	btn.add_theme_stylebox_override("normal", _btn_style(Color("#ffd166")))
	btn.add_theme_stylebox_override("hover", _btn_style(Color("#fff3b0")))
	btn.add_theme_stylebox_override("pressed", _btn_style(Color("#e8a33d")))
	btn.pressed.connect(func(): SFX.play("click"); cb.call())
	vbox.add_child(btn)

func _btn_style(col: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.corner_radius_top_left = 12
	s.corner_radius_top_right = 12
	s.corner_radius_bottom_left = 12
	s.corner_radius_bottom_right = 12
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s

func _pause_game() -> void:
	if paused or level_done:
		return
	paused = true
	get_tree().paused = true
	pause_overlay.visible = true

func _resume_game() -> void:
	paused = false
	get_tree().paused = false
	pause_overlay.visible = false
	win_overlay.visible = false
	lose_overlay.visible = false

func _retry_level() -> void:
	get_tree().paused = false
	Game.start_level(level_index)

func _show_win(stars: int, elapsed: float) -> void:
	# update win overlay content
	var vbox: VBoxContainer = win_overlay.get_child(2) as VBoxContainer
	var subtitle: Label = vbox.get_child(1) as Label
	var mins := int(elapsed) / 60
	var secs := int(elapsed) % 60
	subtitle.text = "%s  •  %02d:%02d  •  %d/%d тиын" % [level_data.get("name",""), mins, secs, coins_got, coins_total]
	# stars row — find or create
	var stars_row: HBoxContainer = null
	for c in vbox.get_children():
		if c is HBoxContainer and c.name == "StarsRow":
			stars_row = c
			break
	if stars_row == null:
		stars_row = HBoxContainer.new()
		stars_row.name = "StarsRow"
		stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
		stars_row.add_theme_constant_override("separation", 16)
		# insert after subtitle (index 2)
		vbox.add_child(stars_row)
		vbox.move_child(stars_row, 2)
	else:
		for c in stars_row.get_children():
			c.queue_free()
	for i in range(3):
		var star := Label.new()
		star.text = "★" if i < stars else "☆"
		star.add_theme_font_size_override("font_size", 48)
		star.add_theme_color_override("font_color", Color("#ffd166") if i < stars else Color(1,1,1,0.25))
		stars_row.add_child(star)
	# buttons — clear old win buttons
	for c in vbox.get_children():
		if c is Button:
			c.queue_free()
	_add_button(win_overlay, "Келесі деңгей", func():
		var nxt := level_index + 1
		if nxt < Levels.level_count():
			Game.start_level(nxt)
		else:
			Game.goto_menu()
	)
	_add_button(win_overlay, "Қайта ойнау", _retry_level)
	_add_button(win_overlay, "Мәзір", func(): Game.goto_menu())
	# next level text tweak
	var next_btn: Button = vbox.get_child(vbox.get_child_count()-3) as Button
	if level_index + 1 >= Levels.level_count():
		next_btn.text = "Мәзірге оралу"

	win_overlay.visible = true
	SFX.play("win")
	# confetti explosion
	for i in range(18):
		_spawn_confetti(player.global_position if player else Vector2(WORLD_W*0.5, WORLD_H*0.5), Color("#ffd166"), 1)
	get_tree().paused = false

func _show_lose() -> void:
	var vbox: VBoxContainer = lose_overlay.get_child(2) as VBoxContainer
	var subtitle: Label = vbox.get_child(1) as Label
	subtitle.text = "Жүректер бітті — қайтадан байқап көр!"
	lose_overlay.visible = true
	SFX.play("game_over")
	get_tree().paused = false

# ==================================================================
# Debug draw — optional grid
# ==================================================================
func _draw() -> void:
	# subtle vignette is handled by parallax; nothing here
	pass
