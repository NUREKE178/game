extends Node
const WIND = preload("res://assets/island/audio/wind.wav")
const EFFECTS = {"step": preload("res://assets/island/audio/step.wav"), "gather": preload("res://assets/island/audio/collect.wav"), "craft": preload("res://assets/island/audio/craft.wav")}
const MUSIC_FOREST = preload("res://assets/affinix/forest_music.wav")
const MUSIC_CAVE = preload("res://assets/affinix/cave_music.wav")
const RAIN = preload("res://assets/affinix/rain.wav")
var music: AudioStreamPlayer
var rain: AudioStreamPlayer
var music_zone := ""
var ambience: AudioStreamPlayer
var effects: Array[AudioStreamPlayer] = []
var volume := 0.65

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var settings := ConfigFile.new()
	if settings.load("user://affinix_settings.cfg") == OK:
		volume = clampf(float(settings.get_value("audio", "volume", 0.65)), 0.0, 1.0)
	ambience = AudioStreamPlayer.new()
	var stream: AudioStreamWAV = WIND.duplicate()
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / 2
	ambience.stream = stream
	ambience.volume_db = -10
	add_child(ambience)
	ambience.play()
	for i in range(4):
		var p := AudioStreamPlayer.new()
		add_child(p)
		effects.append(p)
	music = AudioStreamPlayer.new()
	music.volume_db = -13
	add_child(music)
	rain = AudioStreamPlayer.new()
	rain.volume_db = -9
	rain.stream = _loop(RAIN)
	add_child(rain)
	set_volume(volume)

func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.001)))
	AudioServer.set_bus_mute(0, volume < 0.001)
	var settings := ConfigFile.new()
	settings.set_value("audio", "volume", volume)
	settings.save("user://affinix_settings.cfg")

func play(effect: String) -> void:
	if not EFFECTS.has(effect):
		return
	for p in effects:
		if not p.playing:
			p.stream = EFFECTS[effect]
			p.play()
			break

func _loop(source: AudioStreamWAV) -> AudioStreamWAV:
	var stream: AudioStreamWAV = source.duplicate()
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / 2
	return stream

func set_environment(region: String, weather: String) -> void:
	var zone := "cave" if region in ["Secret Underground", "Misty Mountains"] else "forest"
	if zone != music_zone:
		music_zone = zone
		music.stream = _loop(MUSIC_CAVE if zone == "cave" else MUSIC_FOREST)
		music.play()
	if weather == "Rain" and not rain.playing:
		rain.play()
	elif weather != "Rain" and rain.playing:
		rain.stop()
