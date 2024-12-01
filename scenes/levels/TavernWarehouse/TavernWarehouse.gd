extends BaseLevel

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemaps = [
		$Ground, $Floor, $Walls, $Trails, $Items, $Trees, $BadItems, $GoodItems, $MovingItems,
	]
	hero = $Items/Demolitonist
	hero_start_position = Vector2i(-2, -2)
	ghosts = [
		{position = Vector2i(-2, 4), type = defs.GhostType.MEMORY, mode = defs.UnitType.WORKER},
	]
	teleports = [
	]
	camera_limit = Rect2i(-96, -80, 250, 200)
	move_hero_to_position(hero_start_position)
	level_type = defs.LevelType.FORWARD
	init_map()
	next_scene = ["res://scenes/game/AdventurePlayground/AdventurePlayground.tscn", {levels = ["RepairedTavern"]}]
