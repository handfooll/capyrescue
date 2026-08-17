extends Node

## Persisted player settings: music/SFX volume and haptics. Autoloaded as
## "Settings". Owns the "Music"/"SFX" audio buses (created here at runtime
## rather than via a checked-in bus layout resource, so nothing breaks if the
## project is opened somewhere without one) - AudioManager plays into them,
## this script only controls their volume.

const SAVE_PATH := "user://settings.cfg"

signal changed

var music_volume: float = 0.8
var sfx_volume: float = 0.8
var haptics_enabled: bool = true

func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_load()
	_apply_audio_buses()

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_audio_buses()
	_save()
	changed.emit()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_audio_buses()
	_save()
	changed.emit()

func set_haptics_enabled(value: bool) -> void:
	haptics_enabled = value
	_save()
	changed.emit()

func reset_to_defaults() -> void:
	music_volume = 0.8
	sfx_volume = 0.8
	haptics_enabled = true
	_apply_audio_buses()
	_save()
	changed.emit()

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	var index := AudioServer.bus_count
	AudioServer.add_bus(index)
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")

func _apply_audio_buses() -> void:
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("SFX", sfx_volume)

func _set_bus_volume(bus_name: String, linear_volume: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear_volume, 0.0001)) if linear_volume > 0.0 else -80.0)
	AudioServer.set_bus_mute(index, linear_volume <= 0.0)

func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	music_volume = config.get_value("settings", "music_volume", music_volume)
	sfx_volume = config.get_value("settings", "sfx_volume", sfx_volume)
	haptics_enabled = config.get_value("settings", "haptics_enabled", haptics_enabled)

func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("settings", "music_volume", music_volume)
	config.set_value("settings", "sfx_volume", sfx_volume)
	config.set_value("settings", "haptics_enabled", haptics_enabled)
	config.save(SAVE_PATH)
