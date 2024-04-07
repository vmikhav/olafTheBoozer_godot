class_name CellHistory
extends RefCounted

var layer: LevelDefinitions.Layers
var coords: Vector2i 
var old: CellData
var new: CellData


func is_valid() -> bool:
	return !!old and !!new and (new.source_id != old.source_id or
		not is_same(new.atlas_coords, old.atlas_coords) or new.alternative_tile != old.source_id)
