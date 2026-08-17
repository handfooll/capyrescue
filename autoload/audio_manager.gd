extends Node

## Procedural sound effects. Autoloaded as "Audio".
##
## The repo ships no audio assets at all (checked: no .wav/.mp3/.ogg anywhere,
## including the archived Unity/Swift attempts), so rather than leave SFX
## silent until someone sources real audio, short tones are synthesized at
## runtime with AudioStreamGenerator - a few sine components with a simple
## envelope is enough for "pop when a cat is placed" / "buzz on a mistake" /
## "chime on solve". Swap for authored audio later without touching callers.

const MIX_RATE := 44100.0

var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = 1.0
	_player.stream = generator
	_player.bus = "SFX"
	add_child(_player)

func play_place() -> void:
	_play_tones([{"freq": 520.0, "duration": 0.07, "gain": 0.5}])

func play_mark() -> void:
	_play_tones([{"freq": 320.0, "duration": 0.05, "gain": 0.3}])

func play_mistake() -> void:
	_play_tones([
		{"freq": 220.0, "duration": 0.12, "gain": 0.5},
		{"freq": 160.0, "duration": 0.16, "gain": 0.5},
	])

func play_win() -> void:
	_play_tones([
		{"freq": 523.25, "duration": 0.12, "gain": 0.4},
		{"freq": 659.25, "duration": 0.12, "gain": 0.4},
		{"freq": 783.99, "duration": 0.22, "gain": 0.45},
	])

func play_game_over() -> void:
	_play_tones([
		{"freq": 300.0, "duration": 0.16, "gain": 0.45},
		{"freq": 220.0, "duration": 0.16, "gain": 0.45},
		{"freq": 140.0, "duration": 0.3, "gain": 0.45},
	])

func play_ui_tap() -> void:
	_play_tones([{"freq": 700.0, "duration": 0.04, "gain": 0.25}])

## Centralizes the haptics-enabled check so callers don't each re-read
## Settings.haptics_enabled. No-op on platforms without a haptics engine
## (desktop) - Input.vibrate_handheld() is documented as such by Godot.
func vibrate_if_enabled(duration_ms: int = 20) -> void:
	if Settings.haptics_enabled:
		Input.vibrate_handheld(duration_ms)

## Plays a sequence of short sine tones back-to-back into one buffer. Each
## tone gets a linear fade-in/out envelope so it doesn't click at the edges.
func _play_tones(tones: Array) -> void:
	_player.stop()
	_player.play()
	var playback: AudioStreamGeneratorPlayback = _player.get_stream_playback()
	if playback == null:
		return
	for tone in tones:
		_push_tone(playback, tone.freq, tone.duration, tone.gain)

func _push_tone(playback: AudioStreamGeneratorPlayback, freq: float, duration: float, gain: float) -> void:
	var frame_count := int(MIX_RATE * duration)
	var fade_frames := int(MIX_RATE * 0.01)
	for i in frame_count:
		var t := i / MIX_RATE
		var envelope := 1.0
		if i < fade_frames:
			envelope = float(i) / fade_frames
		elif i > frame_count - fade_frames:
			envelope = float(frame_count - i) / fade_frames
		var sample := sin(TAU * freq * t) * gain * envelope
		playback.push_frame(Vector2(sample, sample))
