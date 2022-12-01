extends BaseLevel

#@onready var tilemap: TileMap = $TileMap

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemap = $TileMap as TileMap
	hero = $TileMap/Demolitonist
	hero_start_position = Vector2i(11, 10)
	ghosts = [
		{position = Vector2i(5, 6)},
		{position = Vector2i(11, 5)},
		{position = Vector2i(13, 8)},
		{position = Vector2i(18, 6)},
	]
	move_hero_to_position(hero_start_position)
	init_map()


