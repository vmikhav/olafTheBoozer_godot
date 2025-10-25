extends BaseLevel

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemaps = [
		$Ground, $Floor, $PressPlates, $Liquids, $Walls, $Trails, $Items, $Trees, $BadItems, $GoodItems, $MovingItems,
	]
	hero = $Items/Demolitonist
	hero_start_position = Vector2i(1, 2)
	ghosts = [
		{position = Vector2i(0, 0), type = defs.GhostType.MEMORY, mode = defs.UnitType.WORKER},
	]
	teleports = [
	]
	camera_limit = Rect2i(-120, -80, 300, 200)
	move_hero_to_position(hero_start_position)
	level_type = defs.LevelType.FORWARD
	init_map()
	next_scene = ["res://scenes/game/AdventurePlayground/AdventurePlayground.tscn", {levels = ["RepairedSawmillBackyard"]}]
