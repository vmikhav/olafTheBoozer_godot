extends BaseLevel

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemaps = [
		$Ground, $Floor, $Walls, $Trails, $Items, $Trees, $BadItems, $GoodItems, $MovingItems,
	]
	hero = $Items/Demolitonist
	hero_start_position = Vector2i(-2, 4)
	ghosts = [
		{position = Vector2i(-2, 3), type = defs.GhostType.ENEMY, mode = defs.UnitType.IMP},
		{position = Vector2i(1, -2), type = defs.GhostType.ENEMY, mode = defs.UnitType.IMP},
		{position = Vector2i(-2, -1), type = defs.GhostType.ENEMY_SPAWN, mode = defs.UnitType.IMP},
		{position = Vector2i(1, 3), type = defs.GhostType.ENEMY_SPAWN, mode = defs.UnitType.IMP},
	]
	teleports = [
		{start = Vector2i(-4, 3), end = Vector2i(-3, -4)},
		{start = Vector2i(-4, -4), end = Vector2i(2, -4)},
		{start = Vector2i(3, -4), end = Vector2i(2, 3)},
		{start = Vector2i(3, 3), end = Vector2i(-3, 3)},
	]
	camera_limit = Rect2i(-100, -128, 200, 250)
	move_hero_to_position(hero_start_position)
	level_type = defs.LevelType.FORWARD
	init_map()
	next_scene = ["res://scenes/game/AdventurePlayground/AdventurePlayground.tscn", {levels = ["RepairedSawmillBackyard"]}]
