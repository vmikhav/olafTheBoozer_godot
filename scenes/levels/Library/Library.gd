extends BaseLevel

#@onready var tilemap: TileMap = $TileMap

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemaps = [
		$Ground, $Floor, $PressPlates, $Liquids, $Walls, $Trails, $Items, $Trees, $BadItems, $GoodItems, $MovingItems,
	]
	hero = $Items/Demolitonist
	hero_start_position = Vector2i(6, 5)
	ghosts = [
		{position = Vector2i(16, 6), type = defs.GhostType.MEMORY, mode = defs.UnitType.WORKER},
		{position = Vector2i(16, 4), type = defs.GhostType.MEMORY, mode = defs.UnitType.WORKER},
		{position = Vector2i(19, 7), type = defs.GhostType.MEMORY, mode = defs.UnitType.WORKER},
		{position = Vector2i(6, 11), type = defs.GhostType.MEMORY, mode = defs.UnitType.WORKER},
	]
	move_hero_to_position(hero_start_position)
	camera_limit = Rect2i(40, 0, 350, 280)
	init_map()
	next_scene = ["res://scenes/game/AdventurePlayground/AdventurePlayground.tscn", {levels = ["StartTavern"]}]
