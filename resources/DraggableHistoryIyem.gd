class_name DraggableHistoryItem
extends Resource

@export var from: Vector2i
@export var to: Vector2i

func _init(_from: Vector2i, _to: Vector2i) -> void:
	from = _from
	to = _to
