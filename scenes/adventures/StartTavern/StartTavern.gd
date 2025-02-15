extends BaseAdventure

var first_dialogue = preload("res://scenes/adventures/StartTavern/start_tavern.dialogue")

# Called when the node enters the scene tree for the first time.
func _ready():
	music_key = "tavern"
	$Hints.visible = false
	tilemaps = [
		$Ground, $Floor, $Walls, $Trails, $Items, $Trees,
	]
	hero = $Items/Demolitonist
	hero_start_position = Vector2i(-3, 3)
	characters = [
		{position = Vector2i(1, -2), mode = defs.UnitType.BLACKSMITH_B},
	]
	teleports = [
	]
	interactive_zones = [
		{positions = [Vector2i(0, -2),Vector2i(1, -2),Vector2i(0, -1),Vector2i(1, -1)], hint_position = Vector2i(1, -1), hint_type = 8, active = !StoryProgress.tavern_flashback, callback = first_dialog},
		{positions = [Vector2i(-1, 1)], hint_position = Vector2i(-1, 1), hint_type = 9, active = !StoryProgress.drunk_leftovers, callback = drink_proposal},
		{positions = [Vector2i(-5, 0)], hint_position = Vector2(-5.5, 0.75), hint_type = 9, active = !StoryProgress.read_fireplace_note, callback = fireplace_note},
		{positions = [Vector2i(0, -2),Vector2i(1, -2),Vector2i(0, -1),Vector2i(1, -1)], hint_position = Vector2i(1, -1), hint_type = 8, active = StoryProgress.tavern_flashback and !StoryProgress.janitor_resqued, callback = janitor_quest},
		{positions = [Vector2i(-3, -6)], hint_position = Vector2i(-3, -6), hint_type = 8, active = false, callback = kitchen_door_label},
	]
	camera_limit = Rect2i(-304, -192, 608, 352)
	move_hero_to_position(hero_start_position)
	init_map()
	
	if !StoryProgress.intro:
		$Hints.visible = true
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
		next_scene = ["res://scenes/game/Playground/Playground.tscn", {levels = ["TavernKitchen"]}]


func intro():
	allow_input = false
	DialogueManager.show_dialogue_balloon(first_dialogue, "intro")
	await DialogueManager.dialogue_ended
	allow_input = true

func first_dialog(index: int):
	allow_input = false
	deactivate_zone(index)
	DialogueManager.show_dialogue_balloon(first_dialogue, "first_host_dialogue")
	await DialogueManager.dialogue_ended
	allow_input = true
	finish_level()

func drink_proposal(index: int):
	allow_input = false
	deactivate_hint(index)
	DialogueManager.show_dialogue_balloon(first_dialogue, "leftovers_drink_proposal")
	await DialogueManager.dialogue_ended
	if StoryProgress.drunk_leftovers:
		deactivate_zone(index)
	allow_input = true

func fireplace_note(index: int):
	allow_input = false
	deactivate_zone(index)
	DialogueManager.show_dialogue_balloon(first_dialogue, "fireplace_note")
	await DialogueManager.dialogue_ended
	allow_input = true


func janitor_quest(index: int):
	allow_input = false
	deactivate_hint(index)
	var dialog = "host_janitor_quest" if !StoryProgress.janitor_resque_requested else "host_janitor_quest_reminder"
	DialogueManager.show_dialogue_balloon(first_dialogue, dialog)
	await DialogueManager.dialogue_ended
	activate_zone(4)
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
	need_stop_music = false
	finish_level()
