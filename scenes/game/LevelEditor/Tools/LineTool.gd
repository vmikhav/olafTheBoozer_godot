# Scripts/Editor/Tools/LineTool.gd
extends EditorTool
class_name LineTool

var start_pos: Vector2i
var is_drawing: bool = false

func handle_input(event: InputEvent, grid_pos: Vector2i):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_pos = grid_pos
			is_drawing = true
		else:
			if is_drawing:
				draw_line_final(start_pos, grid_pos)
			is_drawing = false

func draw_line_final(from: Vector2i, to: Vector2i):
	if not editor.current_tile:
		return
	
	var positions = get_line_positions(from, to)
	if positions.size() > 0:
		var action = PaintAction.new()
		action.editor = editor
		action.layer = editor.active_layer
		action.tile_info = editor.current_tile
		action.positions = positions
		action.execute()
		editor.add_undo_action(action)

func get_line_positions(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	
	# Bresenham's line algorithm
	var dx = abs(to.x - from.x)
	var dy = abs(to.y - from.y)
	var sx = 1 if to.x > from.x else -1
	var sy = 1 if to.y > from.y else -1
	var err = dx - dy
	
	var current = from
	while true:
		positions.append(current)
		if current == to:
			break
		
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			current.x += sx
		if e2 < dx:
			err += dx
			current.y += sy
	
	return positions
