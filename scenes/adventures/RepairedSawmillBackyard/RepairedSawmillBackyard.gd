extends BaseAdventure

var first_dialogue = preload("res://scenes/adventures/SawmillBackyard/sawmill.dialogue")

# Called when the node enters the scene tree for the first time.
func _ready():
	music_key = "sawmill"
	tilemaps = [
		$Ground, $Floor, $Walls, $Trails, $Items, $Trees,
	]
	hero = $Items/Demolitonist
	hero_start_position = Vector2i(-1, 1)
	characters = [
		{position = Vector2i(0, 1), mode = defs.UnitType.ORC_VETERAN},
	]
	teleports = [
	]
	interactive_zones = [
	]
	camera_limit = Rect2i(-75, -100, 300, 200)
	move_hero_to_position(hero_start_position)
	init_map()
	hero.set_orientation("right")
	if !StoryProgress.sawmill_demon_captured:
		next_scene = ["res://scenes/game/Playground/Playground.tscn", {levels = ["SawmillDemon"]}]
		intro()
	elif !StoryProgress.sawmill_warehouse_fixed:
		next_scene = ["res://scenes/game/Playground/Playground.tscn", {levels = ["SawmillWorkshop"]}]
		demon_captured()
	else:
		#next_scene = ["res://trailer/WishlistDemo.tscn", {}]
		next_scene = ["res://scenes/world/WolrdMap/WorldMapInteractive.tscn", {next_location = "tavern"}]
		outro()

func intro():
	allow_input = false
	DialogueManager.show_dialogue_balloon(first_dialogue, "sawmill_log_part2")
	await DialogueManager.dialogue_ended
	finish_level()
	allow_input = true

func demon_captured():
	allow_input = false
	DialogueManager.show_dialogue_balloon(first_dialogue, "demon_captured")
	await DialogueManager.dialogue_ended
	finish_level()
	allow_input = true
	
func outro():
	allow_input = false
	DialogueManager.show_dialogue_balloon(first_dialogue, "counter_fixed")
	await DialogueManager.dialogue_ended
	finish_level()
	allow_input = true
