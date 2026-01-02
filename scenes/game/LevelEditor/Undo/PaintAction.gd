# Scripts/Editor/Undo/PaintAction.gd
extends EditorAction
class_name PaintAction

## Undo/redo action for painting tiles

var layer: BaseLevel.Layer
var tile_info: TileInfo
var positions: Array[Vector2i] = []
var old_cells: Dictionary = {}  # pos -> {source, atlas, alt}

func execute():
	"""Paint tiles and save old state"""
	var tilemap = editor.tilemaps[layer]
	
	# Store what was there before
	for pos in positions:
		old_cells[pos] = {
			"source": tilemap.get_cell_source_id(pos),
			"atlas": tilemap.get_cell_atlas_coords(pos),
			"alt": tilemap.get_cell_alternative_tile(pos)
		}
	
	# Paint new tiles
	for pos in positions:
		tilemap.set_cell(pos, 0, tile_info.atlas_coords, tile_info.alt_tile)

func undo():
	"""Restore old tiles"""
	var tilemap = editor.tilemaps[layer]
	
	for pos in positions:
		var old = old_cells[pos]
		if old.source == -1:
			# Was empty
			tilemap.set_cell(pos, -1, Vector2i(-1, -1))
		else:
			# Restore old tile
			tilemap.set_cell(pos, old.source, old.atlas, old.alt)
