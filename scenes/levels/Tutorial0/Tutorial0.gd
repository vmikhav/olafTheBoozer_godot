extends BaseLevel

#@onready var tilemap: TileMap = $TileMap

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemap = $TileMap as TileMap
	hero = $TileMap/Demolitonist
	hero_start_position = Vector2i(3, 2)
	ghosts = [
		{position = Vector2i(7, 4)}
	]
	teleports = [
		{start = Vector2i(2, 2), end = Vector2i(3, 4)},
		{start = Vector2i(2, 4), end = Vector2i(3, 2)},
	]
	move_hero_to_position(hero_start_position)
	init_map()


