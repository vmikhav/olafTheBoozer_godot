extends Node2D

@onready var scene_transaction = $UiLayer/SceneTransition

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scene_transaction.fade_in()
	$TouchCamera.position = $Hero.position
	$TouchCamera.set_target($Hero)
	#await get_tree().create_timer(10).timeout
	AudioController.play_music("olaf_world")
	$City.input_event.connect(func(viewport, event, shapeidx):
		if (event is InputEventMouseButton && event.pressed):
			pass
			#$Hero.navigate_to($Path2D, Vector2i(-53, -30))
	)
	#
	get_tree().create_timer(7).timeout.connect(func():
		scene_transaction.change_scene("res://scenes/game/Playground/Playground.tscn", {
			levels = ["Tutorial0", "Kitchen", "Library", "Cellar", "Tavern"],
			#levels = ["Tavern", "Tutorial0", "Kitchen", "Library", "Cellar"],
		})
	)
