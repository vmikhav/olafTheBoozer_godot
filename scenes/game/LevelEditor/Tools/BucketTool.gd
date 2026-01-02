# Scripts/Editor/Tools/BucketTool.gd
extends EditorTool
class_name BucketTool

func handle_input(event: InputEvent, grid_pos: Vector2i):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		flood_fill(grid_pos)

func flood_fill(start_pos: Vector2i):
	if not editor.current_tile:
		return
	
	var tilemap = editor.tilemaps[editor.active_layer]
	
	# Get what's at start position
	var start_atlas = tilemap.get_cell_atlas_coords(start_pos)
	var start_alt = tilemap.get_cell_alternative_tile(start_pos)
	
	# Don't fill if trying to fill with same tile
	if start_atlas == editor.current_tile.atlas_coords and start_alt == editor.current_tile.alt_tile:
		return
	
	# Flood fill algorithm
	var to_fill: Array[Vector2i] = []
	var queue: Array[Vector2i] = [start_pos]
	var visited: Dictionary = {}
	
	while queue.size() > 0:
		var pos = queue.pop_front()
		
		if visited.has(pos):
			continue
		visited[pos] = true
		
		var atlas = tilemap.get_cell_atlas_coords(pos)
		var alt = tilemap.get_cell_alternative_tile(pos)
		
		if atlas != start_atlas or alt != start_alt:
			continue
		
		to_fill.append(pos)
		
		# Add neighbors
		queue.append(pos + Vector2i(1, 0))
		queue.append(pos + Vector2i(-1, 0))
		queue.append(pos + Vector2i(0, 1))
		queue.append(pos + Vector2i(0, -1))
	
	# Paint all filled positions
	if to_fill.size() > 0:
		var action = PaintAction.new()
		action.editor = editor
		action.layer = editor.active_layer
		action.tile_info = editor.current_tile
		action.positions = to_fill
		action.execute()
		editor.add_undo_action(action)
 
