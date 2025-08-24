extends Node2D

@onready var menu_button: Button = $CanvasLayer/MarginContainer2/MarginContainer2/Button
@onready var scene_transition = $CanvasLayer/SceneTransition

func _ready():
	AudioController.play_music('workshop')
	scene_transition.fade_in()
	menu_button.grab_focus.call_deferred()
	menu_button.pressed.connect(open_menu)

func open_menu():
	scene_transition.change_scene("res://scenes/game/MainMenu/MainMenu.tscn", {})
