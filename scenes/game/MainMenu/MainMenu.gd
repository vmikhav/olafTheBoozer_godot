extends Node2D

@onready var play_button = %Play as Button
@onready var exit_button = %Exit as Button
@onready var scene_transition = $UiLayer/SceneTransition

# Called when the node enters the scene tree for the first time.
func _ready():
	AudioController.play_music('workshop')
	scene_transition.fade_in()
	play_button.grab_focus.call_deferred()
	play_button.pressed.connect(start_game)
	exit_button.pressed.connect(exit)
	if OS.has_feature("web"):
		exit_button.hide()
	else:
		get_window().grab_focus()


func start_game():
	StoryProgress.clear_progress()
	#scene_transition.change_scene("res://scenes/game/Intro/Intro.tscn")
	#scene_transition.change_scene("res://scenes/world/WolrdMap/WorldMapInteractive.tscn")
	scene_transition.change_scene("res://scenes/game/AdventurePlayground/AdventurePlayground.tscn", {
		levels = ["Tutorial0"],
		#levels = ["Tutorial0", "Kitchen", "Library", "Cellar", "Tavern"],
	})

func exit():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
