extends BaseLevel

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemaps = [
		$Ground, $Floor, $Walls, $Trails, $Items, $Trees, $BadItems, $GoodItems,
	]
	hero = $Items/Demolitonist
	hero_start_position = Vector2i(7, 5)
	ghosts = [
		{position = Vector2i(7, 4), type = defs.GhostType.MEMORY, mode = defs.UnitType.WORKER},
		{position = Vector2i(-2, 8), type = defs.GhostType.MEMORY, mode = defs.UnitType.WORKER},
	]
	teleports = [
		{start = Vector2i(2, 6), end = Vector2i(-15, -3)},
	]
	camera_limit = Rect2i(-304, -128, 608, 288)
	move_hero_to_position(hero_start_position)
	init_map()
