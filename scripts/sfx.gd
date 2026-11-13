extends Node
## Procedural sound effects — every sound is synthesized at runtime,
## so the game ships with zero audio assets.

const RATE := 22050

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	_build_all()
	for i in range(6):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)


func play(sound_name: String) -> void:
	if Game.muted:
		return
	var stream: AudioStreamWAV = _streams.get(sound_name)
	if stream == null:
		return
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	_players[0].stream = stream
	_players[0].play()


# ==================================================================
# Synthesis helpers
# ==================================================================

class Note:
	var freq: float
	var dur: float
	var shape: String
	var vol: float
	func _init(f: float, d: float, s: String = "square", v: float = 0.5) -> void:
		freq = f
		dur = d
		shape = s
		vol = v


func _build_all() -> void:
	_streams["jump"] = _render([Note.new(520.0, 0.09, "square", 0.35), Note.new(760.0, 0.12, "square", 0.3)])
	_streams["double_jump"] = _render([Note.new(660.0, 0.07, "square", 0.3), Note.new(990.0, 0.12, "square", 0.3)])
	_streams["dash"] = _render([Note.new(180.0, 0.05, "sawtooth", 0.35), Note.new(320.0, 0.05, "sawtooth", 0.3), Note.new(520.0, 0.09, "sawtooth", 0.25)])
	_streams["coin"] = _render([Note.new(988.0, 0.06, "sine", 0.4), Note.new(1319.0, 0.22, "sine", 0.4)])
	_streams["heart"] = _render([Note.new(784.0, 0.08, "sine", 0.4), Note.new(1047.0, 0.08, "sine", 0.4), Note.new(1568.0, 0.18, "sine", 0.35)])
	_streams["hurt"] = _render([Note.new(220.0, 0.12, "sawtooth", 0.45), Note.new(147.0, 0.22, "sawtooth", 0.4)])
	_streams["stomp"] = _render([Note.new(392.0, 0.06, "triangle", 0.5), Note.new(196.0, 0.16, "triangle", 0.5)])
	_streams["spring"] = _render([Note.new(262.0, 0.05, "square", 0.35), Note.new(392.0, 0.05, "square", 0.35), Note.new(523.0, 0.05, "square", 0.35), Note.new(784.0, 0.14, "square", 0.35)])
	_streams["checkpoint"] = _render([Note.new(659.0, 0.09, "sine", 0.4), Note.new(880.0, 0.2, "sine", 0.4)])
	_streams["click"] = _render([Note.new(1200.0, 0.03, "square", 0.2)])
	_streams["goal"] = _render([
		Note.new(523.0, 0.12, "square", 0.35), Note.new(659.0, 0.12, "square", 0.35),
		Note.new(784.0, 0.12, "square", 0.35), Note.new(1047.0, 0.32, "square", 0.4),
	])
	_streams["game_over"] = _render([
		Note.new(392.0, 0.18, "triangle", 0.4), Note.new(330.0, 0.18, "triangle", 0.4),
		Note.new(262.0, 0.34, "triangle", 0.45),
	])
	_streams["win"] = _render([
		Note.new(523.0, 0.12, "square", 0.35), Note.new(587.0, 0.12, "square", 0.35),
		Note.new(659.0, 0.12, "square", 0.35), Note.new(784.0, 0.12, "square", 0.35),
		Note.new(1047.0, 0.4, "square", 0.42),
	])


func _render(notes: Array) -> AudioStreamWAV:
	var total := 0.0
	for n in notes:
		total += n.dur
	var frame_count := int(total * RATE)
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	var t := 0.0
	var idx := 0
	for n in notes:
		var frames: int = int(n.dur * RATE)
		for i in range(frames):
			var env := 1.0 - float(i) / maxf(1.0, float(frames))
			env = pow(env, 1.6)
			var sample := _wave(n.shape, n.freq, t) * n.vol * env
			var s := int(clampf(sample, -1.0, 1.0) * 32767.0)
			bytes.encode_s16(idx * 2, s)
			idx += 1
			t += 1.0 / RATE
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	return wav


func _wave(shape: String, freq: float, t: float) -> float:
	var phase := fmod(t * freq, 1.0)
	match shape:
		"sine":
			return sin(TAU * phase)
		"square":
			return 1.0 if phase < 0.5 else -1.0
		"triangle":
			return 4.0 * absf(phase - 0.5) - 1.0
		"sawtooth":
			return 2.0 * phase - 1.0
		_:
			return sin(TAU * phase)
