class_name RetroAudio
extends Node

## Generates compact retro gameplay sounds in memory using arcade-style
## waveforms, avoiding the need to bundle external audio files.

const SAMPLE_RATE := 22050

@onready var effect_player: AudioStreamPlayer = $Effect

var shot_stream: AudioStreamWAV
var goal_stream: AudioStreamWAV
var button_stream: AudioStreamWAV
var bump_stream: AudioStreamWAV


func _ready() -> void:
	shot_stream = _create_square_wave([330.0, 220.0], 0.055, 0.28)
	goal_stream = _create_square_wave(
		[523.25, 659.25, 783.99, 1046.5, 783.99],
		0.13,
		0.22
	)
	button_stream = _create_square_wave([440.0, 660.0], 0.045, 0.22)
	bump_stream = _create_square_wave([120.0], 0.025, 0.12)


func play_shot() -> void:
	_play_effect(shot_stream)


func play_goal() -> void:
	_play_effect(goal_stream)


func play_button() -> void:
	_play_effect(button_stream)


func play_bump() -> void:
	_play_effect(bump_stream)


func _play_effect(stream: AudioStreamWAV) -> void:
	effect_player.stream = stream
	effect_player.play()


func _create_square_wave(
		notes: Array[float],
		note_length: float,
		volume: float
	) -> AudioStreamWAV:
	var samples_per_note := int(SAMPLE_RATE * note_length)
	var audio_data := PackedByteArray()

	for frequency in notes:
		for sample_index in samples_per_note:
			var phase := fmod(float(sample_index) * frequency / SAMPLE_RATE, 1.0)
			var envelope := 1.0 - (float(sample_index) / samples_per_note) * 0.22
			var wave := 1.0 if phase < 0.5 else -1.0
			_append_sample(audio_data, wave * envelope * volume)

	return _build_stream(audio_data, SAMPLE_RATE)


func _append_sample(audio_data: PackedByteArray, sample: float) -> void:
	var sample_value := int(clampf(sample, -1.0, 1.0) * 32767.0)
	audio_data.append(sample_value & 0xff)
	audio_data.append((sample_value >> 8) & 0xff)


func _build_stream(
		audio_data: PackedByteArray,
		sample_rate: int
	) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = audio_data
	return stream
