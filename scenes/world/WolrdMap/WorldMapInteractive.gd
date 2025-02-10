extends Node2D

@onready var scene_transaction = $UiLayer/SceneTransition
@onready var hero = $Hero

var next_location: StringName = "sawmill"

var positions = {
	"tavern": Vector2i(300, -120),
	"sawmill": Vector2i(420, -145),
}

var start_positions = {
	"sawmill": positions["tavern"],
	"tavern": positions["sawmill"],
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if SceneSwitcher.get_param("next_location") != null:
		next_location = SceneSwitcher.get_param("next_location")
	hero.position = start_positions[next_location]
	scene_transaction.fade_in()
	$TouchCamera.position = hero.position
	$TouchCamera.set_target(hero)
	#await get_tree().create_timer(10).timeout
	AudioController.play_music("olaf_world")
	$City.input_event.connect(func(viewport, event, shapeidx):
		if (event is InputEventMouseButton && event.pressed):
			pass
			#$Hero.navigate_to($Path2D, Vector2i(-53, -30))
	)
	#
	get_tree().create_timer(3).timeout.connect(func():
		if next_location == "sawmill":
			go_to_sawmill()
		elif next_location == "tavern":
			go_to_tavern()
		#scene_transaction.change_scene("res://scenes/game/AdventurePlayground/AdventurePlayground.tscn", {
		#	levels = ["StartTavern"],
		#	#levels = ["Tutorial0", "Kitchen", "Library", "Cellar", "Tavern"],
		#})
	)

func go_to_sawmill():
	hero.navigate_to($Path2Sawmill, positions["sawmill"])
	await hero.follow_comlete
	await get_tree().create_timer(1).timeout
	scene_transaction.change_scene("res://scenes/game/Playground/Playground.tscn", {
		levels = ["SawmillYard"],
	})

func go_to_tavern():
	hero.navigate_to($Path2Sawmill, positions["tavern"])
	await $Hero.follow_comlete
	await get_tree().create_timer(1).timeout
	scene_transaction.change_scene("res://scenes/game/AdventurePlayground/AdventurePlayground.tscn", {
		levels = ["RepairedTavern"],
	})
