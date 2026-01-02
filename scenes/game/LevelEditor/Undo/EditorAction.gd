# Scripts/Editor/Undo/EditorAction.gd
extends RefCounted
class_name EditorAction

var editor: LevelEditor

func execute():
	pass  # Override

func undo():
	pass  # Override
