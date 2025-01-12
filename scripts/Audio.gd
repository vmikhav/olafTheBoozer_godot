extends RefCounted
class_name Audio

var stream: AudioStream
var volume: float = 1
var start_positions: Array[float] = [0]

func _init(path: String, _volume: float = 1, _start_positions: Array[float] = []) -> void:
	volume = _volume
	stream = load(path)
	if not _start_positions.is_empty():
		start_positions.append_array(_start_positions)
