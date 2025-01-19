extends Node

var sounds := Dictionary()
var types = {
	"High_1": 22, "High_2": 58, "High_3": 20, "High_4": 20, "High_5": 32,
	"Mid_1": 43, "Mid_2": 16, "Mid_3": 23, "Mid_4": 33,
	"Low_v2_15_1": 27, "Low_v2_15_2": 26, "Low_v2_15_3": 21, "Low_v2_15_4": 35,
}
var char2skip = [" ", "-", ".", ",", ":", "!", "?", "\n", "\t", "'"]

var characters = {
	"": {
		"voice_type": "Mid_4",
		"volume": 1.0,
		"delay": 3
	},
	"Олаф": {
		"voice_type": "Mid_3",
		"volume": 1.0,
		"delay": 2
	},
	"Торвін Круторіг": {
		"voice_type": "Low_v2_15_1",
		"volume": 1.0,
		"delay": 2
	},
	"Клім": {
		"voice_type": "High_4",
		"volume": 1.0,
		"delay": 2
	},
}

var character: String
var voice_type: String
var volume: float = 1.0
var delay_chars: int = 0
var chars_since_last_sound: int = 0

# Sound management
var current_player: AudioStreamPlayer = null
var is_playing: bool = false
var last_used_indexes: Array[int] = []
const FADE_TIME: float = 0.015

func _init() -> void:
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
	volume = char_data.volume
	delay_chars = char_data.delay
	chars_since_last_sound = 100
	last_used_indexes = []

func speak(_char: String) -> void:
	if char2skip.has(_char):
		return
	
	if not sounds.has(voice_type) or sounds[voice_type].is_empty():
		push_warning("No sounds available for voice type: " + voice_type)
		return
		
	chars_since_last_sound += 1
	if chars_since_last_sound <= delay_chars:
		return
	
	if is_playing:
		return
	
	await _play_sound_with_fade(_char)
	
	chars_since_last_sound = 0

func _play_sound_with_fade(_char: String) -> void:
	is_playing = true
	var player = AudioStreamPlayer.new()
	add_child(player)
	current_player = player
	
	# Get sound index based on character code
	var available_sounds = sounds[voice_type].size()
	var char_code: int
	var sound_index: int
	while true:
		char_code = _char.to_utf8_buffer()[0] * 3 + randi_range(0, 4)
		sound_index = char_code % available_sounds
		if !last_used_indexes.has(sound_index):
			break
	#print(sound_index)
	
	last_used_indexes.append(sound_index)
	if last_used_indexes.size() > 2:
		last_used_indexes.pop_front()
	player.stream = sounds[voice_type][sound_index]
	player.volume_db = -60  # Start silent
	player.bus = "Voices"
	
	# Start playing
	player.play()
	
	# Fade in
	var tween = create_tween()
	tween.tween_property(player, "volume_db", linear_to_db(volume), FADE_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	# Wait until near the end of the sound
	var duration = player.stream.get_length()
	var pause = duration - FADE_TIME * 2
	if pause > 0:
		await get_tree().create_timer(pause).timeout
	is_playing = false
	
	# Fade out
	tween = create_tween()
	tween.tween_property(player, "volume_db", -60, FADE_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	
	player.queue_free()
	current_player = null

func _exit_tree() -> void:
	if current_player:
		current_player.queue_free()
