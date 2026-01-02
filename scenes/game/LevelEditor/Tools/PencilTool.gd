extends EditorTool
class_name PencilTool

var is_painting: bool = false
var last_painted_pos: Vector2i = Vector2i(-999, -999)

func handle_input(event: InputEvent, grid_pos: Vector2i):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_painting = true
				paint_at(grid_pos)
			else:
				is_painting = false
				last_painted_pos = Vector2i(-999, -999)
	
	elif event is InputEventMouseMotion:
		if is_painting and grid_pos != last_painted_pos:
			paint_at(grid_pos)

func paint_at(grid_pos: Vector2i):
	editor.paint_tile(grid_pos)
	last_painted_pos = grid_pos 
