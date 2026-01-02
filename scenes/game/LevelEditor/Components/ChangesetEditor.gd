# Scripts/Editor/ChangesetEditor.gd
extends Node
class_name ChangesetEditor

## Tool for creating and editing changesets
## Records what tiles changed from their original state

signal changeset_created(changeset: Changeset)
signal changeset_modified(changeset: Changeset)

var editor: LevelEditor
var current_changeset: Changeset
var is_recording: bool = false
var recorded_changes: Array[CellChange] = []

# Visual feedback
var highlight_overlay: Node2D

func _init(p_editor: LevelEditor):
	editor = p_editor

func start_new_changeset(id: String, description: String = "", mode: int = 0):
	"""Begin recording a new changeset"""
	current_changeset = Changeset.new()
	current_changeset.id = id
	current_changeset.description = description
	current_changeset.mode = mode
	
	is_recording = true
	recorded_changes.clear()
	
	editor.status_label.text = "Recording changeset: %s (click tiles to mark changes)" % id
	show_recording_indicator()

func record_cell_change(layer: BaseLevel.Layer, position: Vector2i, change_mode: String):
	"""
	Record a cell change
	change_mode: "remove", "change", "add"
	"""
	var tilemap = editor.tilemaps[layer]
	
	# Get current state
	var current_source = tilemap.get_cell_source_id(position)
	var current_atlas = tilemap.get_cell_atlas_coords(position)
	var current_alt = tilemap.get_cell_alternative_tile(position)
	
	var cell_change = CellChange.new()
	cell_change.position = position
	cell_change.layer = layer
	
	match change_mode:
		"remove":
			# Mark for removal
			cell_change.old_coords = current_atlas
			cell_change.old_alt = current_alt
			cell_change.new_coords = Vector2i(-1, -1)  # Remove
			cell_change.new_alt = 0
		
		"change":
			# Will change to different tile (user selects what)
			cell_change.old_coords = current_atlas
			cell_change.old_alt = current_alt
			# new_coords will be set when user selects target tile
			cell_change.new_coords = Vector2i(-2, -2)  # Marker for "needs selection"
		
		"add":
			# Add new tile (currently empty)
			cell_change.old_coords = Vector2i(-1, -1)  # Was empty
			cell_change.new_coords = Vector2i(-2, -2)  # Will set target
	
	recorded_changes.append(cell_change)
	highlight_cell(position, layer)
	
	editor.status_label.text = "Recorded %d changes" % recorded_changes.size()

func set_target_tile(change_index: int, tile_info: TileInfo):
	"""Set what tile a change should become"""
	if change_index < 0 or change_index >= recorded_changes.size():
		return
	
	var change = recorded_changes[change_index]
	change.new_coords = tile_info.atlas_coords
	change.new_alt = tile_info.alt_tile

func finish_changeset():
	"""Complete the current changeset"""
	if not is_recording:
		return
	
	# Add all recorded changes to changeset
	for change in recorded_changes:
		current_changeset.add_cell_change(
			change.position,
			change.layer,
			change.old_coords,
			change.new_coords,
			change.old_alt,
			change.new_alt
		)
	
	is_recording = false
	hide_recording_indicator()
	
	changeset_created.emit(current_changeset)
	editor.status_label.text = "Changeset created: %s (%d changes)" % [
		current_changeset.id,
		current_changeset.cell_changes.size()
	]
	
	return current_changeset

func cancel_recording():
	"""Cancel current changeset recording"""
	is_recording = false
	recorded_changes.clear()
	hide_recording_indicator()
	editor.status_label.text = "Changeset recording cancelled"

func show_recording_indicator():
	"""Visual feedback that recording is active"""
	# TODO: Show UI indicator
	pass

func hide_recording_indicator():
	"""Hide recording indicator"""
	# TODO: Hide UI indicator
	pass

func highlight_cell(position: Vector2i, layer: BaseLevel.Layer):
	"""Highlight a cell that's been marked for change"""
	# TODO: Draw highlight overlay
	# For now, just print
	print("Marked cell at %s on layer %s" % [position, BaseLevel.Layer.keys()[layer]])

## Quick changeset creation methods

func create_removal_changeset(id: String, positions: Array[Vector2i], layer: BaseLevel.Layer) -> Changeset:
	"""Create a changeset that removes tiles"""
	var changeset = Changeset.new()
	changeset.id = id
	changeset.description = "Remove tiles"
	changeset.mode = 0
	
	var tilemap = editor.tilemaps[layer]
	
	for pos in positions:
		var atlas = tilemap.get_cell_atlas_coords(pos)
		var alt = tilemap.get_cell_alternative_tile(pos)
		
		changeset.add_cell_change(
			pos,
			layer,
			atlas,  # old
			Vector2i(-1, -1),  # new = removed
			alt,
			0
		)
	
	return changeset

func create_addition_changeset(id: String, positions: Array[Vector2i], layer: BaseLevel.Layer, tile_info: TileInfo) -> Changeset:
	"""Create a changeset that adds tiles"""
	var changeset = Changeset.new()
	changeset.id = id
	changeset.description = "Add tiles"
	changeset.mode = 0
	
	for pos in positions:
		changeset.add_cell_change(
			pos,
			layer,
			Vector2i(-1, -1),  # old = empty
			tile_info.atlas_coords,  # new tile
			0,
			tile_info.alt_tile
		)
	
	return changeset

func create_swap_changeset(id: String, positions: Array[Vector2i], layer: BaseLevel.Layer, from_tile: TileInfo, to_tile: TileInfo) -> Changeset:
	"""Create a changeset that swaps one tile type for another"""
	var changeset = Changeset.new()
	changeset.id = id
	changeset.description = "Swap tiles"
	changeset.mode = 0
	
	for pos in positions:
		changeset.add_cell_change(
			pos,
			layer,
			from_tile.atlas_coords,
			to_tile.atlas_coords,
			from_tile.alt_tile,
			to_tile.alt_tile
		)
	
	return changeset
