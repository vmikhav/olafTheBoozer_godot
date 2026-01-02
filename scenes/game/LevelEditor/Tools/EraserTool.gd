# Scripts/Editor/Tools/EraserTool.gd
extends EditorTool
class_name EraserTool

var is_erasing: bool = false
var last_erased_pos: Vector2i = Vector2i(-999, -999)

func handle_input(event: InputEvent, grid_pos: Vector2i):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_erasing = true
				erase_at(grid_pos)
			else:
				is_erasing = false
				last_erased_pos = Vector2i(-999, -999)
	
	elif event is InputEventMouseMotion:
		if is_erasing and grid_pos != last_erased_pos:
			erase_at(grid_pos)

func erase_at(grid_pos: Vector2i):
	editor.erase_tile(grid_pos)
	last_erased_pos = grid_pos 
