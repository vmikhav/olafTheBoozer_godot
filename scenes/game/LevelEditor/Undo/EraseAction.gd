# Scripts/Editor/Undo/EraseAction.gd
extends EditorAction
class_name EraseAction

## Undo/redo action for erasing tiles

var layer: BaseLevel.Layer
var positions: Array[Vector2i] = []
var old_cells: Dictionary = {}  # pos -> {source, atlas, alt}

func execute():
	"""Erase tiles and save old state"""
	var tilemap = editor.tilemaps[layer]
	
	# Store what was there
	for pos in positions:
		old_cells[pos] = {
			"source": tilemap.get_cell_source_id(pos),
			"atlas": tilemap.get_cell_atlas_coords(pos),
			"alt": tilemap.get_cell_alternative_tile(pos)
		}
	
	# Erase
	for pos in positions:
		tilemap.set_cell(pos, -1, Vector2i(-1, -1))

func undo():
	"""Restore erased tiles"""
	var tilemap = editor.tilemaps[layer]
	
	for pos in positions:
		var old = old_cells[pos]
		if old.source != -1:
			tilemap.set_cell(pos, old.source, old.atlas, old.alt)
