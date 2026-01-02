# Scripts/Editor/Tools/EditorTool.gd
extends RefCounted
class_name EditorTool

var editor: LevelEditor
var is_active: bool = false

func _init(p_editor: LevelEditor):
	editor = p_editor

func activate():
	is_active = true

func deactivate():
	is_active = false

func handle_input(event: InputEvent, grid_pos: Vector2i):
	pass  # Override in subclasses
