extends BaseLevel

#@onready var tilemap: TileMap = $TileMap

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemaps = [
		$Ground, $Floor, $Walls, $Trails, $Items, $Trees, $BadItems, $GoodItems,
	]
	hero = $Items/Demolitonist
	hero_start_position = Vector2i(11, 10)
	ghosts = [
		{position = Vector2i(5, 6), type = defs.GhostType.MEMORY, mode = defs.UnitType.IMP},
		{position = Vector2i(11, 5), type = defs.GhostType.MEMORY, mode = defs.UnitType.IMP},
		{position = Vector2i(13, 8), type = defs.GhostType.MEMORY, mode = defs.UnitType.IMP},
		{position = Vector2i(18, 6), type = defs.GhostType.MEMORY, mode = defs.UnitType.IMP},
	]
	camera_limit = Rect2i(0, 0, 450, 250)
	move_hero_to_position(hero_start_position)
	init_map()


