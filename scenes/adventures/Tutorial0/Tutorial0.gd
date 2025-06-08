extends BaseAdventure

var first_dialogue = preload("res://scenes/adventures/StartTavern/start_tavern.dialogue")

# Called when the node enters the scene tree for the first time.
func _ready():
	music_key = "olaf_gameplay"
	need_stop_music = false
	tilemaps = [
		$Ground, $Floor, $Walls, $Trails, $Items, $Trees,
	]
	hero = $Items/Demolitonist
	hero_start_position = Vector2i(1, 1)
	characters = [
	]
	teleports = [
	]
	interactive_zones = [
	]
	camera_limit = Rect2i(-50, -50, 150, 150)
	move_hero_to_position(hero_start_position)
	init_map()
	
	if !StoryProgress.intro:
		get_tree().create_timer(1.75).connect("timeout", intro)
	next_scene = [
		"res://scenes/game/Playground/Playground.tscn",
		 {levels = ["Tutorial0", "Tutorial1"],
			next_scene = ["res://scenes/game/AdventurePlayground/AdventurePlayground.tscn", {levels = ["StartTavern"]}]
		}
	]


func intro():
	allow_input = false
	DialogueManager.show_dialogue_balloon(first_dialogue, "intro")
	await DialogueManager.dialogue_ended
	finish_level()
