extends BaseAdventure

var first_dialogue = preload("res://scenes/adventures/SawmillBackyard/sawmill.dialogue")

# Called when the node enters the scene tree for the first time.
func _ready():
	music_key = "sawmill"
	tilemaps = [
		$Ground, $Floor, $Walls, $Trails, $Items, $Trees,
	]
	hero = $Items/Demolitonist
	hero_start_position = Vector2i(-3, 1)
	characters = [
		{position = Vector2i(0, 1), mode = defs.UnitType.ORC_VETERAN},
	]
	teleports = [
	]
	interactive_zones = [
		{positions = [Vector2i(0, 1),Vector2i(0, 1),Vector2i(0, 1),Vector2i(0, 1)], hint_position = Vector2i(0, 2), hint_type = 8, active = !StoryProgress.sawmill_intro, callback = first_dialog},
	]
	camera_limit = Rect2i(-75, -100, 300, 200)
	move_hero_to_position(hero_start_position)
	init_map()
	characters[0].unit.make_dead()
	hero.set_orientation("right")
	next_scene = ["res://scenes/game/AdventurePlayground/Playground.tscn", {levels = ["SawmillWarehouse"]}]
	intro()

func intro():
	allow_input = false
	DialogueManager.show_dialogue_balloon(first_dialogue, "intro")
	await DialogueManager.dialogue_ended
	allow_input = true

func first_dialog(index: int):
	allow_input = false
	deactivate_zone(index)
	DialogueManager.show_dialogue_balloon(first_dialogue, "first_sawmill_dialogue")
	await DialogueManager.dialogue_ended
	finish_level()
	allow_input = true
