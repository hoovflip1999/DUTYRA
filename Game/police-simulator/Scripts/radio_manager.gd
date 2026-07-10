extends Node

signal radio_message_sent(message_text: String)

const SAMPLE_RATE: int = 44100

var radio_audio_player: AudioStreamPlayer
var radio_stream: AudioStreamGenerator
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var transmission_id: int = 0

func _ready() -> void:
	rng.randomize()

	radio_audio_player = AudioStreamPlayer.new()
	add_child(radio_audio_player)

	radio_stream = AudioStreamGenerator.new()
	radio_stream.mix_rate = SAMPLE_RATE
	radio_stream.buffer_length = 0.9

	radio_audio_player.stream = radio_stream

func send_radio_message(message_text: String) -> void:
	print("RADIO: " + message_text)

	transmission_id += 1
	var current_transmission_id: int = transmission_id

	radio_message_sent.emit(message_text)
	play_radio_transmission(message_text, current_transmission_id)

func play_radio_transmission(message_text: String, current_transmission_id: int) -> void:
	play_start_static()

	await get_tree().create_timer(0.25).timeout

	if current_transmission_id != transmission_id:
		return

	speak_radio_message(message_text)

	var estimated_voice_time: float = maxf(1.4, float(message_text.length()) * 0.065)

	await get_tree().create_timer(estimated_voice_time).timeout

	if current_transmission_id != transmission_id:
		return

	play_end_beep()

func speak_radio_message(message_text: String) -> void:
	var voice_id: String = get_default_voice_id()

	if voice_id == "":
		print("No system text-to-speech voice found.")
		return

	var voice_volume: int = 85
	var voice_pitch: float = 1.0
	var voice_rate: float = 0.95

	DisplayServer.tts_speak(message_text, voice_id, voice_volume, voice_pitch, voice_rate, transmission_id, true)

func get_default_voice_id() -> String:
	var voices: Array = DisplayServer.tts_get_voices()

	for voice_data: Variant in voices:
		if voice_data is Dictionary:
			var voice_dictionary: Dictionary = voice_data

			if voice_dictionary.has("id"):
				return str(voice_dictionary["id"])

	return ""

func play_start_static() -> void:
	if radio_audio_player == null:
		return

	radio_audio_player.stop()
	radio_audio_player.play()

	var playback: AudioStreamGeneratorPlayback = radio_audio_player.get_stream_playback() as AudioStreamGeneratorPlayback

	if playback == null:
		return

	playback.clear_buffer()

	var static_duration: float = 0.22
	var volume: float = 0.17
	var frame_count: int = int(SAMPLE_RATE * static_duration)

	var frames: PackedVector2Array = PackedVector2Array()
	frames.resize(frame_count)

	var previous_noise: float = 0.0

	for i in range(frame_count):
		var t: float = float(i) / float(SAMPLE_RATE)

		var raw_noise: float = rng.randf_range(-1.0, 1.0)
		var sharp_noise: float = raw_noise - previous_noise
		previous_noise = raw_noise

		var tone_a: float = sin(TAU * 2100.0 * t)
		var tone_b: float = sin(TAU * 3200.0 * t)
		var warble: float = 0.5 + 0.5 * sin(TAU * 35.0 * t)
		var electronic_gate: float = 0.65 + 0.35 * sin(TAU * 90.0 * t)

		var electronic_static: float = 0.0
		electronic_static += sharp_noise * 0.45
		electronic_static += tone_a * 0.25 * warble
		electronic_static += tone_b * 0.12
		electronic_static *= electronic_gate

		var fade: float = 1.0
		var fade_frames: int = 900

		if i < fade_frames:
			fade = float(i) / float(fade_frames)
		elif i > frame_count - fade_frames:
			fade = float(frame_count - i) / float(fade_frames)

		var sample: float = clampf(electronic_static * volume * fade, -1.0, 1.0)
		frames[i] = Vector2(sample, sample)

	playback.push_buffer(frames)

func play_end_beep() -> void:
	if radio_audio_player == null:
		return

	radio_audio_player.stop()
	radio_audio_player.play()

	var playback: AudioStreamGeneratorPlayback = radio_audio_player.get_stream_playback() as AudioStreamGeneratorPlayback

	if playback == null:
		return

	playback.clear_buffer()

	var beep_duration: float = 0.12
	var frequency: float = 1450.0
	var volume: float = 0.16
	var frame_count: int = int(SAMPLE_RATE * beep_duration)

	var frames: PackedVector2Array = PackedVector2Array()
	frames.resize(frame_count)

	for i in range(frame_count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var fade: float = 1.0
		var fade_frames: int = 400

		if i < fade_frames:
			fade = float(i) / float(fade_frames)
		elif i > frame_count - fade_frames:
			fade = float(frame_count - i) / float(fade_frames)

		var sample: float = sin(TAU * frequency * t) * volume * fade
		frames[i] = Vector2(sample, sample)

	playback.push_buffer(frames)
