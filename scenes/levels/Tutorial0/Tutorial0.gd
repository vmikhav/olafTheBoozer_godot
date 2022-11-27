extends BaseLevel

#@onready var tilemap: TileMap = $TileMap

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemap = $TileMap as TileMap
	hero = $TileMap/Demolitonist
	hero_position = Vector2i(2, 2)
	ghosts = [
		{position = Vector2i(7, 4)}
	]
	move_hero_to_position(hero_position)
	init_map()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event is InputEventKey: 
		if event.is_action_released("ui_left"):
			navigate(TileSet.CELL_NEIGHBOR_LEFT_SIDE)
		if event.is_action_released("ui_right"):
			navigate(TileSet.CELL_NEIGHBOR_RIGHT_SIDE)
		if event.is_action_released("ui_up"):
			navigate(TileSet.CELL_NEIGHBOR_TOP_SIDE)
		if event.is_action_released("ui_down"):
			navigate(TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)
		
