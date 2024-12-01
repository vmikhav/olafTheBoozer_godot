extends BaseAdventure

var first_dialogue = preload("res://scenes/adventures/StartTavern/start_tavern.dialogue")

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemaps = [
		$Ground, $Floor, $Walls, $Trails, $Items, $Trees,
	]
	hero = $Items/Demolitonist
	hero_start_position = Vector2i(-1, -2)
	characters = [
		{position = Vector2i(1, -2), mode = defs.UnitType.BLACKSMITH_B},
		{position = Vector2i(-5, 2), mode = defs.UnitType.PEASANT},
	]
	teleports = [
	]
	interactive_zones = [
	]
	camera_limit = Rect2i(-304, -192, 608, 352)
	move_hero_to_position(hero_start_position)
	init_map()
	next_scene = ["res://trailer/WishlistDemo.tscn", {}]
	outro()


func outro():
	allow_input = false
	DialogueManager.show_dialogue_balloon(first_dialogue, "host_counter_quest")
	await DialogueManager.dialogue_ended
	finish_level()
	allow_input = true
