extends Node
const WIND = preload("res://assets/island/audio/wind.wav")
const SOUNDS := {
	"step": preload("res://assets/island/audio/step.wav"),
	"collect": preload("res://assets/island/audio/collect.wav"),
	"craft": preload("res://assets/island/audio/craft.wav"),
	"crash": preload("res://assets/island/audio/crash.wav"),
}
var ambient: AudioStreamPlayer
var players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ambient = AudioStreamPlayer.new()
	var loop: AudioStreamWAV = WIND.duplicate()
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin = 0
	loop.loop_end = loop.data.size() / 2
	ambient.stream = loop
	ambient.volume_db = -7
	add_child(ambient)
	ambient.play()
	for i in range(4):
		var player := AudioStreamPlayer.new()
		add_child(player)
		players.append(player)

func play(sound: String) -> void:
	if not SOUNDS.has(sound):
		return
	for player in players:
		if not player.playing:
			player.stream = SOUNDS[sound]
			player.play()
			return
