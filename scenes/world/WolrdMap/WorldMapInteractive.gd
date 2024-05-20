extends Node2D

@onready var scene_transaction = $UiLayer/SceneTransition

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scene_transaction.fade_in()
	$TouchCamera.position = $Hero.position
	$TouchCamera.target = $Hero
	get_tree().create_timer(7).timeout.connect(func():
		#AudioController.play_music("knights")
		scene_transaction.change_scene("res://scenes/game/Playground/Playground.tscn", {
			#levels = ["Tutorial0", "Kitchen", "Library", "Cellar", "Tavern"],
			levels = ["Tavern", "Tutorial0", "Kitchen", "Library", "Cellar"],
		})
	)

