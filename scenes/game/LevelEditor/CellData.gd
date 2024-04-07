class_name CellData
extends RefCounted

var source_id: int = 0
var atlas_coords: Vector2i = Vector2i(-1, -1)
var alternative_tile: int = 0

func _init(source_id: int = 0, atlas_coords: Vector2i = Vector2i(-1, -1), alternative_tile: int = 0) -> void:
	self.source_id = source_id
	self.atlas_coords = atlas_coords
	self.alternative_tile = alternative_tile
