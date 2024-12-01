class_name LevelProgressReport
extends JsonResource

var start_time = Time.get_datetime_string_from_system()
var _start_timestamp = Time.get_ticks_msec()
var end_time: String
var duration: int
var level: String
var uid: String
var os_name = OS.get_name()
var filled: bool = false

var total_items: int
var progress_items: int
var total_ghosts: int
var progress_ghosts: int
var steps = []
var steps_count: int
var score: int = 0
var finished: bool

func mark_as_filled(history):
	if filled:
		return
	filled = true
	uid = SettingsManager.settings.uid
	end_time = Time.get_datetime_string_from_system()
	duration = Time.get_ticks_msec() - _start_timestamp
	for item in history:
		if 'direction' in item:
			steps.push_back(item.direction)
	steps_count = steps.size() 


func log_report():
	var text = to_json()
	print(text)
	return text
