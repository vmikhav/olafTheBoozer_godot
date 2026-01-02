extends BaseAdventure

var first_dialogue = preload("res://scenes/adventures/Demo/StartTavern/start_tavern.dialogue")
@onready var olaf: Unit = $Items/Demolitonist
@onready var reaper: DemolitonistSprite = $Items/Reaper

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
	hero.set_orientation("left")
	reaper.set_mode([defs.UnitTypeName[defs.UnitType.REAPER], false])
	set_reaper_transparancy(0)
	init_map()
	
	if !StoryProgress.intro:
		get_tree().create_timer(1.75).connect("timeout", intro)
	next_scene = [
		"res://scenes/game/Playground/Playground.tscn",
		 {levels = ["Demo/Tutorial0", "Demo/Tutorial1"],
			next_scene = ["res://scenes/game/AdventurePlayground/AdventurePlayground.tscn", {levels = ["Demo/StartTavern"]}]
		}
	]


func intro():
	allow_input = false
	DialogueManager.show_dialogue_balloon(first_dialogue, "intro")
	await DialogueManager.dialogue_ended
	var tween = create_tween()
	tween.tween_method(set_reaper_transparancy, 0.0, 1.0, .25);
	await tween.finished
	await get_tree().create_timer(0.5).timeout
	DialogueManager.show_dialogue_balloon(first_dialogue, "death_speech")
	await DialogueManager.dialogue_ended
	tween = create_tween()
	tween.tween_method(set_reaper_transparancy, 1.0, 0.0, .25);
	await tween.finished
	await get_tree().create_timer(0.5).timeout
	finish_level()

func get_characters() -> Dictionary[String, Unit]:
	return {"olaf": olaf}

func set_reaper_transparancy(value: float):
	reaper.sprite.material.set_shader_parameter("transparency", value);
