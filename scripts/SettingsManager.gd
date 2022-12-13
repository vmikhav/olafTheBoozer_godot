extends Node

var settings: SettingsResource = SettingsResource.new()
var game_progress: GameProgressResource = GameProgressResource.new()
var skip_save: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	game_progress.load_from_file(game_progress._filename)
	if not FileAccess.file_exists(settings._filename):
		settings.uid = generate_uuid()
		save_settings()
	else:
		settings.load_from_file(settings._filename)
		save_settings()
	skip_save = true
	update_sfx_volume(settings.sfx_volume)
	update_music_volume(settings.music_volume)
	update_sfx_mute(settings.sfx_muted)
	update_music_mute(settings.music_muted)
	skip_save = false

func update_sfx_mute(value: bool):
	settings.sfx_muted = value
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), settings.sfx_muted)
	save_settings()

func update_music_mute(value: bool):
	settings.music_muted = value
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), settings.music_muted)
	save_settings()

func update_sfx_volume(value: float):
	settings.sfx_volume = clampf(value, -48, -0.1)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), settings.sfx_volume)
	save_settings()

func update_music_volume(value: float):
	settings.music_volume = clampf(value, -48, -0.1)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), settings.music_volume)
	save_settings()

func get_highscore(level: String) -> Dictionary:
	if level in game_progress.levels:
		return game_progress.levels[level]
	else:
		return game_progress._highscore_stub

func is_new_highscore(level: String, report: LevelProgressReport):
	var old = game_progress.levels[level] if (level in game_progress.levels) else game_progress._highscore_stub
	return old.score < report.score or (old.score == report.score and old.steps < report.steps)

func update_highscore(level: String, report: LevelProgressReport):
	if is_new_highscore(level, report):
		game_progress.levels[level] = {
			score = report.score,
			time = report.duration,
			steps = report.steps
		}
		save_progress()

func save_settings():
	if skip_save:
		return
	settings.save_to_file(settings._filename)

func save_progress():
	if skip_save:
		return
	game_progress.save_to_file(game_progress._filename)

func generate_uuid():
	return "5"
