extends Node
const PATH := "user://ashore_settings.cfg"
var quality := 1 # 0 low, 1 medium, 2 high
var volume := 0.8
var sensitivity := 0.0025

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		quality = clampi(int(config.get_value("graphics", "quality", 1)), 0, 2)
		volume = clampf(float(config.get_value("audio", "volume", 0.8)), 0.0, 1.0)
		sensitivity = clampf(float(config.get_value("input", "sensitivity", 0.0025)), 0.0005, 0.01)
	apply_audio()

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("graphics", "quality", quality)
	config.set_value("audio", "volume", volume)
	config.set_value("input", "sensitivity", sensitivity)
	config.save(PATH)
	apply_audio()

func apply_audio() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.001, volume)))
	AudioServer.set_bus_mute(0, volume <= 0.001)

func apply_graphics(viewport: Viewport, light: DirectionalLight3D, camera: Camera3D) -> void:
	viewport.scaling_3d_scale = [0.7, 0.85, 1.0][quality]
	viewport.msaa_3d = Viewport.MSAA_2X if quality == 2 else Viewport.MSAA_DISABLED
	light.shadow_enabled = quality > 0
	camera.far = [180.0, 260.0, 380.0][quality]
