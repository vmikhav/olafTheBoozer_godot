extends BaseLevel

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemaps = [
		$Ground, $Floor, $Walls, $Trails, $Items, $Trees, $BadItems, $GoodItems,
	]
	hero = $Items/Demolitonist
	hero_start_position = Vector2i(3, 2)
	ghosts = [
		{position = Vector2i(7, 4), type = defs.GhostType.MEMORY, mode = defs.UnitType.WORKER},
	]
	teleports = [
	]
	camera_limit = Rect2i(-100, -50, 400, 250)
	move_hero_to_position(hero_start_position)
	init_map()
