class_name LabAudio
extends Node

var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var next_voice: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	for index in 8:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	sounds["revolver"] = _synthesize(0.13, 120.0, 0.7, 1)
	sounds["shotgun"] = _synthesize(0.23, 68.0, 0.8, 2)
	sounds["smg"] = _synthesize(0.07, 190.0, 0.65, 3)
	sounds["hit"] = _synthesize(0.08, 720.0, 0.2, 4)
	sounds["weak"] = _synthesize(0.18, 280.0, 0.2, 5)
	sounds["reload"] = _synthesize(0.08, 960.0, 0.4, 6)

func _synthesize(duration: float, frequency: float, noise: float, seed_value: int) -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	for index in count:
		var t := float(index) / sample_rate
		var envelope := exp(-t * 35.0) * minf(t * 2500, 1)
		var value := (sin(TAU * frequency * t * (1 - t * 0.8)) * (1 - noise) + random.randf_range(-1, 1) * noise) * envelope
		data.encode_s16(index * 2, int(clampf(value, -1, 1) * 22000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func play(key: String) -> void:
	if not sounds.has(key) or voices.is_empty():
		return
	var voice := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stream = sounds[key]
	voice.volume_db = -22 if key == "smg" else -16
	voice.play()

func stop_all() -> void:
	for voice in voices:
		voice.stop()
