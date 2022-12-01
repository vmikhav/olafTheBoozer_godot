extends BaseLevel

#@onready var tilemap: TileMap = $TileMap

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemap = $TileMap as TileMap
	hero = $TileMap/Demolitonist
	hero_start_position = Vector2i(6, 5)
	ghosts = [
		{position = Vector2i(16, 6)},
		{position = Vector2i(16, 4)},
		{position = Vector2i(19, 7)},
		{position = Vector2i(6, 11)},
	]
	move_hero_to_position(hero_start_position)
	init_map()


