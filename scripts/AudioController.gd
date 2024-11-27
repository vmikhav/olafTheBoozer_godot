extends Node

var current_music: AudioStreamPlayer
var current_music_name: String
var music_positions: Dictionary[String, float] = {}
var music_stop_times: Dictionary[String, int] = {}

var music: Dictionary[String, Array] = {
	"knights": [Audio.new("res://assets/music/Tournier of the Knights.mp3")],
	"fairies": [Audio.new("res://assets/music/A Dance With Fairies.mp3", 0.3)],
	"olaf_fast": [Audio.new("res://assets/music/Olaf The Boozer Theme.mp3")],
	"olaf_world": [Audio.new("res://assets/music/Olaf The Boozer World.mp3")],
	"olaf_gameplay": [
		Audio.new("res://assets/music/Olaf The Boozer Gameplay Theme.mp3"),
		Audio.new("res://assets/music/Olaf The Boozer Gameplay Theme V2.mp3"),
		Audio.new("res://assets/music/Olaf The Boozer Gameplay Theme V3.mp3"),
	],
}

var sfx: Dictionary[String, Array] = {
	"burp": [
		Audio.new("res://assets/sfx/Burp_9.wav", 0.4),
		Audio.new("res://assets/sfx/Burp_13.wav", 0.4),
		Audio.new("res://assets/sfx/Burp_15.wav", 0.4),
		Audio.new("res://assets/sfx/Burp_16.wav", 0.4),
		Audio.new("res://assets/sfx/Burp_17.wav", 0.4),
		Audio.new("res://assets/sfx/Burp_18.wav", 0.4),
		Audio.new("res://assets/sfx/Burp_19.wav", 0.4),
		Audio.new("res://assets/sfx/Burp_20.wav", 0.4),
	],
	"book_shelf": [
		Audio.new("res://assets/sfx/as_pr_so_book_shelf_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_book_shelf_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_book_shelf_3.wav"),
		Audio.new("res://assets/sfx/as_pr_so_book_shelf_4.wav")
	],
	"vomit": [
		Audio.new("res://assets/sfx/as_pr_so_bucket_womit_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_bucket_womit_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_bucket_womit_3.wav"),
		Audio.new("res://assets/sfx/as_pr_so_bucket_womit_4.wav")
	],
	"cabinet_ceramics": [
		Audio.new("res://assets/sfx/as_pr_so_cabinet_ceramics_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_cabinet_ceramics_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_cabinet_ceramics_3.wav")
	],
	"chair": [
		Audio.new("res://assets/sfx/as_pr_so_chair_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_chair_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_chair_3.wav")
	],
	"clock": [
		Audio.new("res://assets/sfx/as_pr_so_clock_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_clock_2.wav")
	],
	"door": [
		Audio.new("res://assets/sfx/as_pr_so_door_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_door_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_door_3.wav"),
		Audio.new("res://assets/sfx/as_pr_so_door_4.wav")
	],
	"grain": [
		Audio.new("res://assets/sfx/as_pr_so_grain_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_grain_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_grain_3.wav")
	],
	"hammer_1": [
		Audio.new("res://assets/sfx/as_pr_so_hammer_1_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_hammer_1_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_hammer_1_3.wav"),
		Audio.new("res://assets/sfx/as_pr_so_hammer_1_4.wav"),
		Audio.new("res://assets/sfx/as_pr_so_hammer_1_5.wav")
	],
	"hammer_2": [
		Audio.new("res://assets/sfx/as_pr_so_hammer_2_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_hammer_2_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_hammer_2_3.wav")
	],
	"hammer_double": [
		Audio.new("res://assets/sfx/as_pr_so_hammer_double_1_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_hammer_double_1_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_hammer_double_1_3.wav"),
		Audio.new("res://assets/sfx/as_pr_so_hammer_double_1_4.wav"),
		Audio.new("res://assets/sfx/as_pr_so_hammer_double_2_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_hammer_double_2_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_hammer_double_2_3.wav"),
	],
	"hammer_table": [
		Audio.new("res://assets/sfx/as_pr_so_hammer_2_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_hammer_2_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_hammer_2_3.wav"),
		Audio.new("res://assets/sfx/as_pr_so_table_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_table_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_table_3.wav"),
		Audio.new("res://assets/sfx/as_pr_so_table_4.wav")
	],
	"hammer_complex": [
		Audio.new("res://assets/sfx/as_pr_so_hammer_1_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_hammer_1_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_hammer_1_3.wav"),
		Audio.new("res://assets/sfx/as_pr_so_hammer_1_4.wav"),
		Audio.new("res://assets/sfx/as_pr_so_hammer_1_5.wav"),
		Audio.new("res://assets/sfx/as_pr_so_hammer_double_1_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_hammer_double_1_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_hammer_double_1_3.wav"),
		Audio.new("res://assets/sfx/as_pr_so_hammer_double_1_4.wav")
	],
	"mirror": [
		Audio.new("res://assets/sfx/as_pr_so_mirror_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_mirror_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_mirror_3.wav"),
		Audio.new("res://assets/sfx/as_pr_so_mirror_4.wav")
	],
	"pot": [
		Audio.new("res://assets/sfx/as_pr_so_pot_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_pot_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_pot_3.wav"),
		Audio.new("res://assets/sfx/as_pr_so_pot_4.wav")
	],
	"shelf_orange": [
		Audio.new("res://assets/sfx/as_pr_so_shelf_orange_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_shelf_orange_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_shelf_orange_3.wav"),
		Audio.new("res://assets/sfx/as_pr_so_shelf_orange_4.wav")
	],
	"shelf_violet": [
		Audio.new("res://assets/sfx/as_pr_so_shelf_violet_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_shelf_violet_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_shelf_violet_3.wav"),
		Audio.new("res://assets/sfx/as_pr_so_shelf_violet_4.wav")
	],
	"statue": [
		Audio.new("res://assets/sfx/as_pr_so_statue_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_statue_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_statue_3.wav")
	],
	"table": [
		Audio.new("res://assets/sfx/as_pr_so_table_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_table_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_table_3.wav"),
		Audio.new("res://assets/sfx/as_pr_so_table_4.wav")
	],
	"tub_drink": [
		Audio.new("res://assets/sfx/as_pr_so_tub_drink_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_tub_drink_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_tub_drink_3.wav"),
		Audio.new("res://assets/sfx/as_pr_so_tub_drink_4.wav"),
		Audio.new("res://assets/sfx/as_pr_so_tub_drink_5.wav")
	],
	"window": [
		Audio.new("res://assets/sfx/as_pr_so_window_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_window_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_window_3.wav"),
		Audio.new("res://assets/sfx/as_pr_so_window_4.wav")
	],
	"bump": [
		Audio.new("res://assets/sfx/as_pс_so_olaf_blocked_step.wav")
	],
	"step": [
		Audio.new("res://assets/sfx/as_pс_so_olaf_footstep_1.wav"),
		Audio.new("res://assets/sfx/as_pс_so_olaf_footstep_2.wav")
	],
	"olaf_hiccup_idle": [
		Audio.new("res://assets/sfx/as_pс_so_olaf_hiccup_idle_1.wav"),
		Audio.new("res://assets/sfx/as_pс_so_olaf_hiccup_idle_2.wav"),
		Audio.new("res://assets/sfx/as_pс_so_olaf_hiccup_idle_3.wav"),
		Audio.new("res://assets/sfx/as_pс_so_olaf_hiccup_idle_4.wav"),
		Audio.new("res://assets/sfx/as_pс_so_olaf_hiccup_idle_5.wav")
	],
	"footprints": [
		Audio.new("res://assets/sfx/as_pс_so_olaf_footprints_1.wav"),
		Audio.new("res://assets/sfx/as_pс_so_olaf_footprints_2.wav"),
		Audio.new("res://assets/sfx/as_pс_so_olaf_footprints_3.wav"),
		Audio.new("res://assets/sfx/as_pс_so_olaf_footprints_4.wav"),
		Audio.new("res://assets/sfx/as_pс_so_olaf_footprints_5.wav"),
		Audio.new("res://assets/sfx/as_pс_so_olaf_footprints_6.wav"),
	],
	"wood_impact": [
		Audio.new("res://assets/sfx/as_pr_so_wood_impact_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_wood_impact_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_wood_impact_3.wav"),
		Audio.new("res://assets/sfx/as_pr_so_wood_impact_4.wav"),
		Audio.new("res://assets/sfx/as_pr_so_wood_impact_5.wav"),
		Audio.new("res://assets/sfx/as_pr_so_wood_impact_6.wav")
	],
	"rock_impact": [
		Audio.new("res://assets/sfx/as_pr_so_rock_impact_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_rock_impact_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_rock_impact_3.wav"),
		Audio.new("res://assets/sfx/as_pr_so_rock_impact_4.wav")
	],
	"glass_impact": [
		Audio.new("res://assets/sfx/as_pr_so_glass_impact_1.wav"),
		Audio.new("res://assets/sfx/as_pr_so_glass_impact_2.wav"),
		Audio.new("res://assets/sfx/as_pr_so_glass_impact_3.wav"),
		Audio.new("res://assets/sfx/as_pr_so_glass_impact_4.wav")
	],
	"pickup": [
		Audio.new("res://assets/sfx/as_pс_so_olaf_soul_1.wav"),
		Audio.new("res://assets/sfx/as_pс_so_olaf_soul_2.wav"),
		Audio.new("res://assets/sfx/as_pс_so_olaf_soul_3.wav"),
		Audio.new("res://assets/sfx/as_pс_so_olaf_soul_4.wav"),
		Audio.new("res://assets/sfx/as_pс_so_olaf_soul_5.wav"),
		Audio.new("res://assets/sfx/as_pс_so_olaf_soul_6.wav"),
		Audio.new("res://assets/sfx/as_pс_so_olaf_soul_7.wav"),
		Audio.new("res://assets/sfx/as_pс_so_olaf_soul_8.wav"),
	],
	"mouse_moving": [
		Audio.new("res://assets/sfx/as_ui_so_mouse_moving_1.wav"),
		Audio.new("res://assets/sfx/as_ui_so_mouse_moving_2.wav")
	],
	"mouse_click": [
		Audio.new("res://assets/sfx/as_ui_so_mouse_click.wav")
	],
	"dropdown_menu": [
		Audio.new("res://assets/sfx/as_ui_so_dropdown_menu.wav")
	],
	"dropdown_menu_drink": [
		Audio.new("res://assets/sfx/as_ui_so_dropdown_menu_drinking_beer.wav")
	],
}

var last_played_variations = {}

const sounds_map: Dictionary[String, String] = {
	"31,17": "clock",
	"9,20": "mirror",
	"4,11": "door",
	"5,10": "door",
	"6,10": "window",
	"6,11": "window",
	"15,16": "hammer_table",
	"16,16": "hammer_table",
	"15,18": "hammer_table",
	"16,18": "hammer_table",
	"8,10": "hammer_table",
	"9,10": "hammer_table",
	"10,10": "hammer_table",
	"11,10": "hammer_table",
	"12,10": "hammer_table",
	"13,10": "hammer_table",
	"14,10": "hammer_table",
	"15,10": "hammer_table",
	"8,11": "hammer_table",
	"9,11": "hammer_table",
	"10,11": "hammer_table",
	"11,11": "hammer_table",
	"12,11": "hammer_table",
	"13,11": "hammer_table",
	"14,11": "hammer_table",
	"15,11": "hammer_table",
	"8,12": "hammer_table",
	"9,12": "hammer_table",
	"10,12": "hammer_table",
	"11,12": "hammer_table",
	"12,12": "hammer_table",
	"13,12": "hammer_table",
	"14,12": "hammer_table",
	"15,12": "hammer_table",
	"8,13": "hammer_table",
	"9,13": "hammer_table",
	"10,13": "hammer_table",
	"11,13": "hammer_table",
	"12,13": "hammer_table",
	"13,13": "hammer_table",
	"14,14": "hammer_complex",
	"15,14": "hammer_complex",
	"16,14": "hammer_complex",
	"17,14": "hammer_complex",
	"18,14": "hammer_complex",
	"14,16": "hammer_complex",
	"19,17": "hammer_complex",
	"20,17": "hammer_complex",
	"27,20": "hammer_complex",
	"10,19": "hammer_complex",
	"14,18": "chair",
	"12,20": "chair",
	"8,16": "book_shelf",
	"9,16": "book_shelf",
	"10,16": "book_shelf",
	"11,16": "book_shelf",
	"18,8": "cabinet_ceramics",
	"19,8": "cabinet_ceramics",
	"13,21": "cabinet_ceramics",
	"14,21": "cabinet_ceramics",
	"16,10": "shelf_orange",
	"17,10": "shelf_orange",
	"18,10": "shelf_orange",
	"19,10": "shelf_orange",
	"16,12": "shelf_orange",
	"17,12": "shelf_orange",
	"18,12": "shelf_orange",
	"21,17": "shelf_violet",
	"22,17": "shelf_violet",
	"23,17": "shelf_violet",
	"24,17": "shelf_violet",
	"25,17": "shelf_violet",
	"7,19": "statue",
	"15,19": "statue",
	"16,19": "statue",
	"15,20": "statue",
	"16,20": "statue",
	"11,15": "pot",
	"23,19": "pot",
	"28,19": "pot",
	"29,19": "pot",
	"30,19": "pot",
	"31,19": "pot",
	"8,14": "vomit",
	"12,16": "tub_drink",
	"13,16": "tub_drink",
	"12,18": "tub_drink",
	"13,14": "grain",
	"5,19": "footprints",
	"6,19": "footprints",
	"5,20": "footprints",
	"6,20": "footprints",
}

func get_sound(bad_item: Vector2i, good_item: Vector2i) -> String:
	var result = "wood_impact"
	var bad_item_key = str(bad_item.x) + ',' + str(bad_item.y)
	var good_item_key = str(good_item.x) + ',' + str(good_item.y)
	if sounds_map.has(good_item_key):
		result = sounds_map[good_item_key]
	elif sounds_map.has(bad_item_key):
		result = sounds_map[bad_item_key]
	return result

func play_sfx_by_tiles(bad_item: Vector2i, good_item: Vector2i = Vector2i(-1, -1)):
	var sfx_key = get_sound(bad_item, good_item)
	play_sfx(sfx_key)

func play_sfx_audio(audio: Audio, sfx_name: String = ""):
	var player = AudioStreamPlayer.new()
	var position = 0
	player.stream = audio.stream
	player.bus = "SFX"
	player.volume_db = linear_to_db(audio.volume)
	if sfx_name == "vomit":
		if SettingsManager.settings.burps_muted:
			position = 0.15
	add_child(player)
	player.play(position)
	await player.finished
	player.queue_free()

func play_sfx(sfx_key: String):
	if not sfx.has(sfx_key):
		push_error("SFX key not found: ", sfx_key)
		return
	var variations = sfx[sfx_key]
	var num_variations = variations.size()

	if num_variations == 0:
		push_error("No variations found for SFX key: ", sfx_key)
		return
	elif num_variations == 1:
		play_sfx_audio(variations[0], sfx_key)
		return

	var last_played_index = last_played_variations.get(sfx_key, -1)
	var weights = []

	for i in range(num_variations):
		weights.append(1.0 if i != last_played_index else 0.5)
	var total_weight = weights.reduce(func(accum, weight): return accum + weight)
	var random_value = randf() * total_weight
	var cumulative_weight = 0.0
	var selected_index = 0
	for i in range(num_variations):
		cumulative_weight += weights[i]
		if random_value <= cumulative_weight:
			selected_index = i
			break
	last_played_variations[sfx_key] = selected_index
	play_sfx_audio(variations[selected_index], sfx_key)


func play_music(music_name: String, switch_duration: float = .75):
	if current_music_name == music_name:
		return
	stop_music(switch_duration)
	if not music.has(music_name):
		push_error("Music key not found: ", music_name)
		return
	current_music_name = music_name
	var player = AudioStreamPlayer.new()
	var position = 0
	var current_time = Time.get_ticks_msec()
	if music_positions.has(music_name) and music_stop_times.has(music_name):
		var time_since_stop = (current_time - music_stop_times[music_name]) / 1000.0  # Convert to seconds
		if time_since_stop <= 300:
			position = music_positions[music_name]
		music_positions.erase(music_name)
		music_stop_times.erase(music_name)
	current_music = player
	player.bus = "Music"
	var item: Audio = music[music_name].pick_random()
	player.stream = item.stream
	add_child(player)
	player.volume_db = -60
	var new_tween = get_tree().create_tween()
	new_tween.tween_property(player, 'volume_db', linear_to_db(item.volume), switch_duration).set_trans(Tween.TRANS_CIRC)
	player.play(position)
	player.finished.connect(func():
		player.play()
	)

func stop_music(switch_duration: float = 1):
	var old_stream = current_music
	if is_instance_valid(old_stream):
		music_positions[current_music_name] = old_stream.get_playback_position()
		music_stop_times[current_music_name] = Time.get_ticks_msec()
		var old_tween = get_tree().create_tween()
		old_tween.tween_property(old_stream, 'volume_db', -60, switch_duration).set_trans(Tween.TRANS_EXPO)
		old_tween.tween_callback(func ():
			if is_instance_valid(old_stream):
				old_stream.queue_free()
		)
	current_music = null
	current_music_name = ''
