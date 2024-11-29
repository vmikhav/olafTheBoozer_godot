extends BaseAdventure

var first_dialogue = preload("res://scenes/adventures/StartTavern/first_host_dialogue.dialogue")

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemaps = [
		$Ground, $Floor, $Walls, $Trails, $Items, $Trees,
	]
	hero = $Items/Demolitonist
	hero_start_position = Vector2i(7, 5)
	characters = [
		{position = Vector2i(7, 4), mode = defs.UnitType.OLD_MAN},
		{position = Vector2i(-2, 8), mode = defs.UnitType.BLACKSMITH_B},
	]
	teleports = [
		{start = Vector2i(2, 6), end = Vector2i(-15, -3)},
	]
	interactive_zones = [
		{position = Vector2i(7, 4), active = true, callback = first_dialog}
	]
	camera_limit = Rect2i(-304, -128, 608, 288)
	move_hero_to_position(hero_start_position)
	init_map()

func first_dialog(index: int):
	interactive_zones[index].active = false
	DialogueManager.show_dialogue_balloon(first_dialogue)
	await DialogueManager.dialogue_ended
	allow_input = true
