extends BaseLevel

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemaps = [
		$Ground, $Floor, $Walls, $Trails, $Items, $Trees, $BadItems, $GoodItems, $MovingItems,
	]
	hero = $Items/Demolitonist
	hero_start_position = Vector2i(2, 2)
	ghosts = [
		{position = Vector2i(7, 5), type = defs.GhostType.MEMORY, mode = defs.UnitType.SUCCUB},
		{position = Vector2i(13, 2), type = defs.GhostType.MEMORY, mode = defs.UnitType.SUCCUB},
	]
	teleports = [
		{start = Vector2i(0, 2), end = Vector2i(1, 4)},
		{start = Vector2i(8, 4), end = Vector2i(2, 2)},
		{start = Vector2i(3, 2), end = Vector2i(7, 4)},
		{start = Vector2i(0, 4), end = Vector2i(6, 1)},
		{start = Vector2i(5, 1), end = Vector2i(1, 4)},
		{start = Vector2i(8, 1), end = Vector2i(12, 4)},
		{start = Vector2i(12, 5), end = Vector2i(7, 1)},
		{start = Vector2i(13, 5), end = Vector2i(7, 1)},
	]
	camera_limit = Rect2i(-100, -50, 450, 250)
	move_hero_to_position(hero_start_position)
	init_map()
	next_scene = ["res://scenes/game/AdventurePlayground/AdventurePlayground.tscn", {levels = ["CleanedTavern"]}]
