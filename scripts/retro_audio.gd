class_name RetroAudio
extends Node

## Generates tiny square-wave sounds in memory. This keeps the prototype
## self-contained while still giving shots, goals, and menus a retro identity.

@onready var music_player: AudioStreamPlayer = $Music
@onready var effect_player: AudioStreamPlayer = $Effect


func _ready() -> void:
	music_player.stream = _create_music_loop()
	music_player.play()


func play_shot() -> void:
	_play_effect([330.0, 220.0], 0.055, 0.28)


func play_goal() -> void:
	_play_effect([523.25, 659.25, 783.99, 1046.5], 0.11, 0.32)


func play_button() -> void:
	_play_effect([440.0, 660.0], 0.045, 0.22)


func play_bump() -> void:
	_play_effect([120.0], 0.025, 0.12)


func _play_effect(notes: Array[float], note_length: float, volume: float) -> void:
	effect_player.stream = _create_square_wave(notes, note_length, volume, false)
	effect_player.play()


func _create_music_loop() -> AudioStreamWAV:
	var notes: Array[float] = [
		130.81, 164.81, 196.00, 261.63,
		146.83, 174.61, 220.00, 293.66,
	]
	return _create_square_wave(notes, 0.18, 0.08, true)


func _create_square_wave(
		notes: Array[float],
		note_length: float,
		volume: float,
		should_loop: bool
	) -> AudioStreamWAV:
	const SAMPLE_RATE := 22050
	var samples_per_note := int(SAMPLE_RATE * note_length)
	var audio_data := PackedByteArray()

	for frequency in notes:
		for sample_index in samples_per_note:
			var phase := fmod(float(sample_index) * frequency / SAMPLE_RATE, 1.0)
			var envelope := 1.0 - (float(sample_index) / samples_per_note) * 0.22
			var wave := 1.0 if phase < 0.5 else -1.0
			var sample_value := int(wave * envelope * volume * 32767.0)
			audio_data.append(sample_value & 0xff)
			audio_data.append((sample_value >> 8) & 0xff)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = audio_data
	if should_loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = audio_data.size() / 2
	return stream
