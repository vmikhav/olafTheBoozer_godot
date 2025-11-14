extends Resource
class_name Changeset

## Represents a reversible change to the level state
## Changes are organized by layer and position for efficient undo/redo

class CellChange:
	var position: Vector2i
	var layer: int
	var old_coords: Vector2i
	var new_coords: Vector2i
	var old_alt: int
	var new_alt: int
	
	func _init(pos: Vector2i, lyr: int, old_c: Vector2i, new_c: Vector2i, old_a: int, new_a: int):
		position = pos
		layer = lyr
		old_coords = old_c
		new_coords = new_c
		old_alt = old_a
		new_alt = new_a

var id: String
var description: String
var cell_changes: Array[CellChange] = []
var applied: bool = false

func _init(p_id: String = "", p_description: String = "", changes: Array[CellChange] = []):
	id = p_id
	description = p_description
	cell_changes = changes

## Add a cell change to this changeset
func add_cell_change(pos: Vector2i, layer: int, old_coords: Vector2i, new_coords: Vector2i, old_alt: int = 0, new_alt: int = 0):
	cell_changes.append(CellChange.new(pos, layer, old_coords, new_coords, old_alt, new_alt))

## Apply all changes to the level
func apply(level: BaseLevel):
	for change in cell_changes:
		level.update_cell(change.position, change.new_coords, change.new_alt, change.layer)
	applied = true

## Rollback all changes
func rollback(level: BaseLevel):
	for change in cell_changes:
		level.update_cell(change.position, change.old_coords, change.old_alt, change.layer)
	applied = false
