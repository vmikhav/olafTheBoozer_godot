extends Node

var music = {
	"knights": load("res://assets/music/Tournier of the Knights.mp3")
}

var sounds = {
	"drink": load("res://assets/sounds/drink.wav"),
	"glass": load("res://assets/sounds/glass.wav"),
	"step": load("res://assets/sounds/step.wav"),
	"smash": load("res://assets/sounds/smash.wav"),
	"break": load("res://assets/sounds/break.wav"),
	"break05": load("res://assets/sounds/Wood Impact 7_05.wav"),
	"break11": load("res://assets/sounds/Wood Impact 7_11.wav"),
	"vomit": load("res://assets/sounds/vomit.wav"),
	"bump": load("res://assets/sounds/bump.wav"),
	"pickup": load("res://assets/sounds/pickup.wav"),
	"water_step": load("res://assets/sounds/water-step.wav"),
	"fanfare": load("res://assets/sounds/fanfare.mp3"),
	"hrrng": load("res://assets/sounds/hrrng.wav"),
	"hiccup": load("res://assets/sounds/hiccup.wav"),
	"groan": load("res://assets/sounds/groan.wav"),
	"burp_9": load("res://assets/sounds/Burp_9.wav"),
	"burp_13": load("res://assets/sounds/Burp_13.wav"),
	"burp_15": load("res://assets/sounds/Burp_15.wav"),
	"burp_16": load("res://assets/sounds/Burp_16.wav"),
	"burp_17": load("res://assets/sounds/Burp_17.wav"),
	"burp_18": load("res://assets/sounds/Burp_18.wav"),
	"burp_19": load("res://assets/sounds/Burp_19.wav"),
	"burp_20": load("res://assets/sounds/Burp_20.wav"),	
}

const sounds_map = {
	"8,14": "vomit",
	"6,12": "glass",
	"9,18": "glass",
	"12,16": "drink",
	"13,16": "drink",
	"12,18": "drink",
	"5,19": "water_step",
	"6,19": "water_step",
	"5,20": "water_step",
	"6,20": "water_step",
	"23,19": "smash",
	"30,19": "smash",
	"13,21": "smash",
	"14,21": "smash",
	"11,15": "smash",
	"18,8": "smash",
	"19,8": "smash",
}

func get_sound(bad_item: Vector2i, good_item: Vector2i) -> String:
	var result = "break11"
	var bad_item_key = str(bad_item.x) + ',' + str(bad_item.y)
	var good_item_key = str(good_item.x) + ',' + str(good_item.y)
	if sounds_map.has(good_item_key):
		result = sounds_map[good_item_key]
	elif sounds_map.has(bad_item_key):
		result = sounds_map[bad_item_key]
	return result

func play_sfx_by_tiles(bad_item: Vector2i, good_item: Vector2i = Vector2i(-1, -1)):
	play_sfx(get_sound(bad_item, good_item))

func play_sfx(sfx_name: String):
	var player = AudioStreamPlayer.new()
	var position = 0
	player.bus = "SFX"
	if sfx_name == "vomit":
		player.volume_db = -1.5
		if SettingsManager.settings.burps_muted:
			position = 0.5
	player.stream = sounds[sfx_name]
	add_child(player)
	player.play(position)
	await player.finished
	player.queue_free()

func play_music(music_name: String):
	var player = AudioStreamPlayer.new()
	var position = 0
	player.bus = "Music"
	player.stream = music[music_name]
	add_child(player)
	player.play(position)
	await player.finished
	player.queue_free()
