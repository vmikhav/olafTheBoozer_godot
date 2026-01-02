# Scripts/Editor/Tools/EyedropperTool.gd
extends EditorTool
class_name EyedropperTool

func handle_input(event: InputEvent, grid_pos: Vector2i):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pick_tile(grid_pos)

func pick_tile(grid_pos: Vector2i):
	var tilemap = editor.tilemaps[editor.active_layer]
	
	var atlas = tilemap.get_cell_atlas_coords(grid_pos)
	var alt = tilemap.get_cell_alternative_tile(grid_pos)
	
	if atlas == Vector2i(-1, -1):
		editor.status_label.text = "No tile at position"
		return
	
	# Find matching tile in catalog
	for tile in editor.tile_catalog.tiles:
		if tile.atlas_coords == atlas and tile.alt_tile == alt:
			editor.select_tile(tile)
			editor.select_tool("pencil")
			return
	
	editor.status_label.text = "Tile not found in catalog" 
