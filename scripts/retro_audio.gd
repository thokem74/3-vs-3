class_name RetroAudio
extends Node

## Generates compact retro sounds in memory. A filtered-noise loop creates the
## stadium crowd, while gameplay actions use simple arcade-style waveforms.

@onready var crowd_player: AudioStreamPlayer = $Crowd
@onready var effect_player: AudioStreamPlayer = $Effect


func _ready() -> void:
	crowd_player.stream = _create_crowd_loop()
	crowd_player.play()


func play_shot() -> void:
	_play_effect([330.0, 220.0], 0.055, 0.28)


func play_goal() -> void:
	effect_player.stream = _create_goal_celebration()
	effect_player.play()


func play_button() -> void:
	_play_effect([440.0, 660.0], 0.045, 0.22)


func play_bump() -> void:
	_play_effect([120.0], 0.025, 0.12)


func _play_effect(notes: Array[float], note_length: float, volume: float) -> void:
	effect_player.stream = _create_square_wave(notes, note_length, volume, false)
	effect_player.play()


func _create_crowd_loop() -> AudioStreamWAV:
	const SAMPLE_RATE := 22050
	const LOOP_SECONDS := 4.0
	var random := RandomNumberGenerator.new()
	var audio_data := PackedByteArray()
	var filtered_noise := 0.0
	var total_samples := int(SAMPLE_RATE * LOOP_SECONDS)
	random.seed = 1986

	for sample_index in total_samples:
		var time := float(sample_index) / SAMPLE_RATE
		var white_noise := random.randf_range(-1.0, 1.0)
		filtered_noise = filtered_noise * 0.94 + white_noise * 0.06

		# Slow volume waves suggest groups of spectators reacting in the stands.
		var crowd_wave := 0.72 + sin(time * TAU * 0.45) * 0.16
		crowd_wave += sin(time * TAU * 0.23) * 0.1
		var low_murmur := sin(time * TAU * 92.0) * 0.018
		var sample := filtered_noise * 0.23 * crowd_wave + low_murmur
		_append_sample(audio_data, sample)

	return _build_stream(audio_data, SAMPLE_RATE, true)


func _create_goal_celebration() -> AudioStreamWAV:
	const SAMPLE_RATE := 22050
	const CELEBRATION_SECONDS := 2.4
	const NOTE_LENGTH := 0.13
	var fanfare_notes: Array[float] = [523.25, 659.25, 783.99, 1046.5, 783.99]
	var random := RandomNumberGenerator.new()
	var audio_data := PackedByteArray()
	var filtered_cheer := 0.0
	var total_samples := int(SAMPLE_RATE * CELEBRATION_SECONDS)
	random.seed = 1994

	for sample_index in total_samples:
		var time := float(sample_index) / SAMPLE_RATE
		var sample := 0.0

		# A short rising arcade fanfare makes the scoring moment unmistakable.
		var note_index := int(time / NOTE_LENGTH)
		if note_index < fanfare_notes.size():
			var note_time := fmod(time, NOTE_LENGTH)
			var phase := fmod(note_time * fanfare_notes[note_index], 1.0)
			var note_envelope := 1.0 - note_time / NOTE_LENGTH * 0.35
			sample += (1.0 if phase < 0.5 else -1.0) * 0.22 * note_envelope

		# Filtered noise swells quickly and fades like a small cheering crowd.
		if time >= 0.25:
			var white_noise := random.randf_range(-1.0, 1.0)
			filtered_cheer = filtered_cheer * 0.82 + white_noise * 0.18
			var cheer_time := time - 0.25
			var cheer_envelope := minf(1.0, cheer_time / 0.18)
			cheer_envelope *= 1.0 - cheer_time / (CELEBRATION_SECONDS - 0.25) * 0.55
			var cheer_pulse := 0.78 + sin(time * TAU * 5.0) * 0.22
			sample += filtered_cheer * 0.42 * cheer_envelope * cheer_pulse

		_append_sample(audio_data, sample)

	return _build_stream(audio_data, SAMPLE_RATE, false)


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
			_append_sample(audio_data, wave * envelope * volume)

	return _build_stream(audio_data, SAMPLE_RATE, should_loop)


func _append_sample(audio_data: PackedByteArray, sample: float) -> void:
	var sample_value := int(clampf(sample, -1.0, 1.0) * 32767.0)
	audio_data.append(sample_value & 0xff)
	audio_data.append((sample_value >> 8) & 0xff)


func _build_stream(
		audio_data: PackedByteArray,
		sample_rate: int,
		should_loop: bool
	) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = audio_data
	if should_loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = audio_data.size() / 2
	return stream
