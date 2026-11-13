extends Node
## Global state for DALA — Steppe Spirit.
## Holds the current level index, sound toggle, persistent best-results
## and sets up the input map in code (so project.godot stays clean).

signal coins_changed(total: int)

const SAVE_PATH := "user://dala_save.cfg"

var current_level: int = 0
var muted: bool = false
## level_index -> { "coins": int, "stars": int, "time": float, "done": bool }
var best: Dictionary = {}


func _ready() -> void:
	_setup_input()
	load_save()


# ---------------------------------------------------------------- input
func _setup_input() -> void:
	_key_action("move_left", [KEY_A, KEY_LEFT])
	_key_action("move_right", [KEY_D, KEY_RIGHT])
	_key_action("move_up", [KEY_W, KEY_UP])
	_key_action("move_down", [KEY_S, KEY_DOWN])
	_key_action("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_key_action("dash", [KEY_X, KEY_SHIFT, KEY_J])
	_key_action("pause", [KEY_ESCAPE, KEY_P])
	_key_action("confirm", [KEY_ENTER, KEY_SPACE])


func _key_action(action: String, keys: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.5)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


# ---------------------------------------------------------------- save
func load_save() -> void:
	best.clear()
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	muted = bool(cfg.get_value("settings", "muted", false))
	for lvl in range(0, 3):
		var coins: int = int(cfg.get_value("best_%d" % lvl, "coins", 0))
		var stars: int = int(cfg.get_value("best_%d" % lvl, "stars", 0))
		var time: float = float(cfg.get_value("best_%d" % lvl, "time", 0.0))
		var done: bool = bool(cfg.get_value("best_%d" % lvl, "done", false))
		best[lvl] = {"coins": coins, "stars": stars, "time": time, "done": done}


func save_save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "muted", muted)
	for lvl in best.keys():
		var b: Dictionary = best[lvl]
		cfg.set_value("best_%d" % lvl, "coins", b.get("coins", 0))
		cfg.set_value("best_%d" % lvl, "stars", b.get("stars", 0))
		cfg.set_value("best_%d" % lvl, "time", b.get("time", 0.0))
		cfg.set_value("best_%d" % lvl, "done", b.get("done", false))
	cfg.save(SAVE_PATH)


func record_result(level: int, coins: int, stars: int, time: float) -> void:
	var prev: Dictionary = best.get(level, {"coins": 0, "stars": 0, "time": 0.0, "done": false})
	var prev_time: float = prev.get("time", 0.0)
	if prev_time <= 0.0 or time < prev_time:
		prev_time = time
	best[level] = {
		"coins": maxi(int(prev.get("coins", 0)), coins),
		"stars": maxi(int(prev.get("stars", 0)), stars),
		"time": prev_time,
		"done": true,
	}
	save_save()


func is_level_unlocked(level: int) -> bool:
	if level <= 0:
		return true
	var prev: Dictionary = best.get(level - 1, {})
	return bool(prev.get("done", false))


func total_stars() -> int:
	var s := 0
	for lvl in best.keys():
		s += int(best[lvl].get("stars", 0))
	return s


func toggle_mute() -> void:
	muted = not muted
	save_save()


# ---------------------------------------------------------------- flow
func start_level(index: int) -> void:
	current_level = index
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func goto_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func quit_game() -> void:
	get_tree().quit()
