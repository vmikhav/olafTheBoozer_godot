extends Node2D

@onready var play_button = $UiLayer/MarginContainer/VBoxContainer/MarginContainer/Button as Button
@onready var exit_button = $UiLayer/MarginContainer/VBoxContainer/MarginContainer2/Button as Button
@onready var scene_transaction = $UiLayer/SceneTransition

# Called when the node enters the scene tree for the first time.
func _ready():
	scene_transaction.fade_in()
	play_button.pressed.connect(start_game)
	exit_button.pressed.connect(exit)


func start_game():
	#scene_transaction.change_scene("res://scenes/game/Intro/Intro.tscn")
	#scene_transaction.change_scene("res://scenes/world/WolrdMap/WorldMapInteractive.tscn")
	scene_transaction.change_scene("res://scenes/game/AdventurePlayground/AdventurePlayground.tscn", {
		levels = ["StartTavern"],
		#levels = ["Tutorial0", "Kitchen", "Library", "Cellar", "Tavern"],
	})

func exit():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
