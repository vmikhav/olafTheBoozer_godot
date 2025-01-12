extends BaseAdventure

var first_dialogue = preload("res://scenes/adventures/StartTavern/start_tavern.dialogue")

# Called when the node enters the scene tree for the first time.
func _ready():
	music_key = "tavern"
	tilemaps = [
		$Ground, $Floor, $Walls, $Trails, $Items, $Trees,
	]
	hero = $Items/Demolitonist
	hero_start_position = Vector2i(-1, -2)
	characters = [
		{position = Vector2i(1, -2), mode = defs.UnitType.BLACKSMITH_B},
		{position = Vector2i(-2, 0), mode = defs.UnitType.PEASANT},
	]
	teleports = [
	]
	interactive_zones = [
		{positions = [Vector2i(0, -2),Vector2i(1, -2),Vector2i(0, -1),Vector2i(1, -1)], hint_position = Vector2i(1, -1), hint_type = 8, active = !StoryProgress.cellar_fixed, callback = cellar_quest},
		{positions = [Vector2i(-2, 0)], hint_position = Vector2i(-2, 0), hint_type = 9, active = true, callback = cleme_idle},
	]
	camera_limit = Rect2i(-304, -192, 608, 352)
	move_hero_to_position(hero_start_position)
	init_map()
	
	if !StoryProgress.cellar_fixed:
		intro()
		next_scene = ["res://scenes/game/Playground/Playground.tscn", {levels = ["Cellar"]}]
	elif !StoryProgress.warehouse_fixed:
		warehouse_quest()
		next_scene = ["res://scenes/game/Playground/Playground.tscn", {levels = ["TavernWarehouse"]}]
	

func intro():
	allow_input = false
	DialogueManager.show_dialogue_balloon(first_dialogue, "tavern_cleme_resqued")
	await DialogueManager.dialogue_ended
	allow_input = true

func cleme_idle(index: int):
	deactivate_hint(index)
	allow_input = false
	DialogueManager.show_dialogue_balloon(first_dialogue, "tavern_cleme_idle")
	await DialogueManager.dialogue_ended
	allow_input = true

func cellar_quest(index: int):
	deactivate_zone(index)
	DialogueManager.show_dialogue_balloon(first_dialogue, "host_cellar_quest")
	await DialogueManager.dialogue_ended
	allow_input = true
	finish_level()

func warehouse_quest():
	DialogueManager.show_dialogue_balloon(first_dialogue, "host_warehouse_quest")
	await DialogueManager.dialogue_ended
	allow_input = true
	finish_level()
