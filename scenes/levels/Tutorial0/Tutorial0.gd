extends BaseLevel

#@onready var tilemap: TileMap = $TileMap

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemap = $TileMap as TileMap
	hero = $TileMap/Demolitonist
	hero_start_position = Vector2i(3, 2)
	ghosts = [
		{position = Vector2i(7, 4), type = defs.GhostType.MEMORY, mode = defs.UnitType.SUCCUB},
		{position = Vector2i(1, 4), type = defs.GhostType.ENEMY, mode = defs.UnitType.VILLAGER_WOMAN},
		{position = Vector2i(6, 5), type = defs.GhostType.ENEMY_SPAWN, mode = defs.UnitType.VILLAGER_WOMAN},
	]
	teleports = [
		{start = Vector2i(0, 2), end = Vector2i(1, 4)},
		{start = Vector2i(0, 4), end = Vector2i(1, 2)},
	]
	move_hero_to_position(hero_start_position)
	init_map()


