# Scripts/Editor/Tools/RectangleTool.gd
extends EditorTool
class_name RectangleTool

var start_pos: Vector2i
var is_drawing: bool = false

func handle_input(event: InputEvent, grid_pos: Vector2i):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_pos = grid_pos
			is_drawing = true
		else:
			if is_drawing:
				draw_rectangle_final(start_pos, grid_pos)
			is_drawing = false

func draw_rectangle_final(from: Vector2i, to: Vector2i):
	if not editor.current_tile:
		return
	
	var positions = get_rectangle_positions(from, to)
	if positions.size() > 0:
		var action = PaintAction.new()
		action.editor = editor
		action.layer = editor.active_layer
		action.tile_info = editor.current_tile
		action.positions = positions
		action.execute()
		editor.add_undo_action(action)

func get_rectangle_positions(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	
	var min_x = min(from.x, to.x)
	var max_x = max(from.x, to.x)
	var min_y = min(from.y, to.y)
	var max_y = max(from.y, to.y)
	
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			positions.append(Vector2i(x, y))
	
	return positions 
