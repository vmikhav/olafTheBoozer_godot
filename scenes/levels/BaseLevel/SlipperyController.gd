extends Resource
class_name SlipperyController

var defs := LevelDefinitions
var level: BaseLevel


## Check if a position has slippery floor
func is_slippery(pos: Vector2i) -> bool:
	if not level:
		return false
	var cell = level.tilemaps[BaseLevel.Layer.LIQUIDS].get_cell_atlas_coords(pos)
	if cell.x == -1:
		return false
	
	# Check if this tile is in the slippery tiles array
	var cell_value = str(cell.x) + "," + str(cell.y)
	for slippery_tile in defs.SlipperyTiles:
		if slippery_tile == cell_value:
			return true
	return false

## Attempt to move on slippery floor
## Returns the final position after sliding, or initial position if can't move
func move_on_slippery(start_pos: Vector2i, direction: TileSet.CellNeighbor, has_tail: bool) -> Dictionary:
	var current_pos = start_pos
	var result = {
		"can_move": true,
		"final_position": start_pos,
		"slid": false,
		"positions_traversed": [start_pos]
	}
	
	# First check if we can enter the slippery tile at all
	var next_pos = level.tilemaps[BaseLevel.Layer.LIQUIDS].get_neighbor_cell(current_pos, direction)
	if !is_slippery(next_pos):
		return result
	
	if has_tail:
		result["can_move"] = false
		return result # Cannot use slippery with tail
	
	# Check basic movement constraints
	if level.is_empty_cell(BaseLevel.Layer.GROUND, next_pos):
		result["can_move"] = false
		return result # No ground
	
	if not level.is_empty_cell(BaseLevel.Layer.WALLS, next_pos):
		result["can_move"] = false
		return result # Wall blocks entry
	
	if level.has_draggable_object_at(next_pos):
		result["can_move"] = false
		return result # Draggable object ahead
	
	if level.has_blocking_item_at(next_pos):
		result["can_move"] = false
		return result # Path is blocked by item
	
	# Keep sliding in the same direction until we hit a non-slippery tile
	while true:
		current_pos = level.tilemaps[BaseLevel.Layer.LIQUIDS].get_neighbor_cell(current_pos, direction)
		
		# Check if we can continue sliding
		if level.is_empty_cell(BaseLevel.Layer.GROUND, current_pos):
			result["can_move"] = false
			return result # No ground ahead
		
		if not level.is_empty_cell(BaseLevel.Layer.WALLS, current_pos):
			result["can_move"] = false
			return result # Wall ahead
		
		if level.has_draggable_object_at(current_pos):
			result["can_move"] = false
			return result # Cannot use slippery with tail
	
		if level.has_blocking_item_at(current_pos):
			result["can_move"] = false
			return result # Path is blocked by item
		
		if !is_slippery(current_pos):
			break
		
		if level.has_broken_item_at(current_pos):
			break
		
		result["positions_traversed"].append(current_pos)
	
	result["positions_traversed"].append(current_pos)	
	result["can_move"] = true
	result["final_position"] = current_pos
	result["slid"] = current_pos != next_pos
	return result
