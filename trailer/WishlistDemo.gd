extends Node2D

@onready var exit_button: Button = $CanvasLayer/MarginContainer2/MarginContainer2/Button
@onready var scene_transition = $CanvasLayer/SceneTransition


func _ready():
	scene_transition.fade_in()
	exit_button.pressed.connect(exit)
	if OS.has_feature("wasm"):
		exit_button.hide()

func exit():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()