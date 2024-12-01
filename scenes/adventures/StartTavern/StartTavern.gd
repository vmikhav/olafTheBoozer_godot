extends BaseAdventure

var first_dialogue = preload("res://scenes/adventures/StartTavern/start_tavern.dialogue")

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemaps = [
		$Ground, $Floor, $Walls, $Trails, $Items, $Trees,
	]
	hero = $Items/Demolitonist
	hero_start_position = Vector2i(-3, 3)
	characters = [
		{position = Vector2i(1, -2), mode = defs.UnitType.BLACKSMITH_B},
		{position = Vector2i(-2, -6), mode = defs.UnitType.PEASANT},
	]
	teleports = [
	]
	interactive_zones = [
		{positions = [Vector2i(0, -2),Vector2i(1, -2),Vector2i(0, -1),Vector2i(1, -1)], active = !StoryProgress.tavern_flashback, callback = first_dialog},
		{positions = [Vector2i(-1, 1)], active = !StoryProgress.drunk_leftovers, callback = drink_proposal},
		{positions = [Vector2i(-5, 0),Vector2i(-4, 0)], active = !StoryProgress.read_fireplace_note, callback = fireplace_note},
		{positions = [Vector2i(0, -2),Vector2i(1, -2),Vector2i(0, -1),Vector2i(1, -1)], active = !StoryProgress.janitor_resqued, callback = janitor_quest},
		{positions = [Vector2i(-3, -6)], active = !StoryProgress.janitor_resque_stage1, callback = kitchen_door_label},
	]
	camera_limit = Rect2i(-304, -192, 608, 352)
	move_hero_to_position(hero_start_position)
	init_map()
	
	if !StoryProgress.intro:
		get_tree().create_timer(1.75).connect("timeout", intro)
	if !StoryProgress.tavern_flashback:
		next_scene = ["res://scenes/game/Playground/Playground.tscn", {levels = ["TavernTutorial"]}]
	elif !StoryProgress.janitor_resque_requested:
		janitor_quest(3)
		hero_start_position = Vector2i(-1, -2)
		move_hero_to_position(hero_start_position)
		next_scene = ["res://scenes/game/Playground/Playground.tscn", {levels = ["Kitchen"]}]
	elif !StoryProgress.janitor_resque_stage2:
		kitchen_door_key()
		hero_start_position = Vector2i(-4, -6)
		move_hero_to_position(hero_start_position)
		hero.set_orientation('right')
		next_scene = ["res://scenes/game/Playground/Playground.tscn", {levels = ["Library"]}]
	elif !StoryProgress.janitor_resqued:
		kitchen_door_lockpick()
		hero_start_position = Vector2i(-4, -6)
		move_hero_to_position(hero_start_position)
		hero.set_orientation('right')
		next_scene = ["res://scenes/game/AdventurePlayground/AdventurePlayground.tscn", {levels = ["CleanedTavern"]}]


func intro():
	allow_input = false
	DialogueManager.show_dialogue_balloon(first_dialogue, "intro")
	await DialogueManager.dialogue_ended
	allow_input = true

func first_dialog(index: int):
	interactive_zones[index].active = false
	DialogueManager.show_dialogue_balloon(first_dialogue, "first_host_dialogue")
	await DialogueManager.dialogue_ended
	allow_input = true
	finish_level()

func drink_proposal(index: int):
	DialogueManager.show_dialogue_balloon(first_dialogue, "leftovers_drink_proposal")
	await DialogueManager.dialogue_ended
	if StoryProgress.drunk_leftovers:
		interactive_zones[index].active = false
	allow_input = true

func fireplace_note(index: int):
	interactive_zones[index].active = false
	DialogueManager.show_dialogue_balloon(first_dialogue, "fireplace_note")
	await DialogueManager.dialogue_ended
	allow_input = true


func janitor_quest(index: int):
	var dialog = "host_janitor_quest" if !StoryProgress.janitor_resque_requested else "host_janitor_quest_reminder"
	DialogueManager.show_dialogue_balloon(first_dialogue, dialog)
	await DialogueManager.dialogue_ended
	#interactive_zones[4].active = true
	allow_input = true


func kitchen_door_label(index: int):
	allow_input = false
	var dialog = "tavern_kitchen_door_label" if !StoryProgress.janitor_resque_requested else "tavern_kitchen_door_start_quest"
	DialogueManager.show_dialogue_balloon(first_dialogue, dialog)
	await DialogueManager.dialogue_ended
	if StoryProgress.janitor_resque_stage1:
		finish_level()
	allow_input = true

func kitchen_door_key():
	allow_input = false
	DialogueManager.show_dialogue_balloon(first_dialogue, "tavern_kitchen_door_key")
	await DialogueManager.dialogue_ended
	finish_level()
	allow_input = true

func kitchen_door_lockpick():
	allow_input = false
	DialogueManager.show_dialogue_balloon(first_dialogue, "tavern_kitchen_door_unlock")
	await DialogueManager.dialogue_ended
	allow_input = true
	finish_level()
