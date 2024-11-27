extends RefCounted
class_name Audio

var stream: AudioStream
var volume: float = 1

func _init(path: String, _volume: float = 1) -> void:
	volume = _volume
	stream = load(path)
