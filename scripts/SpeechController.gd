extends Node

var sounds := Dictionary()
var types = {
	"High_1": 22, "High_2": 58, "High_3": 20, "High_4": 20, "High_5": 32,
	"Mid_1": 43, "Mid_2": 16, "Mid_3": 23, "Mid_4": 33,
	"Low_1": 27, "Low_2": 26, "Low_3": 21, "Low_4": 35,
}
var char2skip = [" ", "-", ".", ",", ":", "!", "?", "\n", "\t", "'"]

var characters = {
	"": {
		"voice_type": "Mid_4",
		"pitch": 0.95,
		"volume": 1.0,
		"delay": 4
	},
	"Олаф": {
		"voice_type": "Mid_4",
		"pitch": 1.0,
		"volume": 1.0,
		"delay": 3
	},
	"Торвін Круторіг": {
		"voice_type": "Mid_1",
		"pitch": 0.95,
		"volume": 0.8,
		"delay": 5
	},
	"Клім": {
		"voice_type": "High_2",
		"pitch": 0.9,
		"volume": 1.0,
		"delay": 3
	},
}

var character: String
var voice_type: String
var pitch_scale: float = 1.0
var volume_db: float = 1.0
var delay_chars: int = 0
var chars_since_last_sound: int = 0

var effect = AudioEffectPitchShift.new()

func _init() -> void:
	var bus = AudioServer.get_bus_index("Voices")
	#AudioServer.set_bus_volume_db(bus, linear_to_db(0.3))
	AudioServer.add_bus_effect(bus, effect)
	for type in types.keys():
		sounds[type] = []
		for i in types[type]:
			var path = "res://assets/sfx/Voices/%s/%s_%d.wav" % [type, type, i + 1]
			var sound = load(path)
			if sound:
				sounds[type].append(sound)
			else:
				push_warning("Failed to load sound: " + path)


func set_character(_character: String) -> void:
	character = _character
	if not characters.has(_character):
		return
	
	var char_data = characters[character]
	voice_type = char_data.voice_type
	pitch_scale = char_data.pitch
	effect.pitch_scale = pitch_scale
	volume_db = char_data.volume
	delay_chars = char_data.delay
	chars_since_last_sound = 100

func speak(char: String) -> void:
	if char2skip.has(char):
		return
	
	if not sounds.has(voice_type) or sounds[voice_type].is_empty():
		push_warning("No sounds available for voice type: " + voice_type)
		return
		
	chars_since_last_sound += 1
	if chars_since_last_sound <= delay_chars:
		return
	
	var player = AudioStreamPlayer.new()
	add_child(player)
	
	# Get sound index based on character code
	var char_code = char.to_utf8_buffer()[0] * 3 + randi_range(0, 3)
	var available_sounds = sounds[voice_type].size()
	var sound_index = char_code % available_sounds
	
	player.stream = sounds[voice_type][sound_index]
	
	# Apply character-specific settings
	player.pitch_scale = pitch_scale
	player.volume_db = volume_db
	player.bus = "Voices"
	
	
	player.play()
	await player.finished
	player.queue_free()
	
	# Reset delay counter after playing sound
	chars_since_last_sound = 0
