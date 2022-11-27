extends BaseLevel

#@onready var tilemap: TileMap = $TileMap

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemap = $TileMap as TileMap
	hero = $TileMap/Demolitonist
	hero_position = Vector2i(3, 4)
	move_hero_to_position(hero_position)
	init_map()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event is InputEventKey: 
		if event.is_action_released("ui_left"):
			var dir = [
				TileSet.CELL_NEIGHBOR_TOP_SIDE,
				TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
				TileSet.CELL_NEIGHBOR_LEFT_SIDE,
				TileSet.CELL_NEIGHBOR_RIGHT_SIDE
			]
			navigate(dir[randi_range(0,3)])
		#navigate(TileSet.CELL_NEIGHBOR_RIGHT_SIDE)
