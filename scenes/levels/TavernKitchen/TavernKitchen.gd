extends BaseLevel

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemaps = [
		$Ground, $Floor, $Walls, $Trails, $Items, $Trees, $BadItems, $GoodItems, $MovingItems,
	]
	hero = $Items/Demolitonist
	hero_start_position = Vector2i(-4, -3)
	ghosts = [
		{position = Vector2i(3, -6), type = defs.GhostType.MEMORY, mode = defs.UnitType.WORKER},
		{position = Vector2i(1, -6), type = defs.GhostType.ENEMY, mode = defs.UnitType.PEASANT},
		{position = Vector2i(-4, -6), type = defs.GhostType.ENEMY_SPAWN, mode = defs.UnitType.PEASANT},
	]
	teleports = [
	]
	camera_limit = Rect2i(-304, -256, 608, 320)
	move_hero_to_position(hero_start_position)
	level_type = defs.LevelType.FORWARD
	init_map()
	next_scene = ["res://scenes/game/AdventurePlayground/AdventurePlayground.tscn", {levels = ["CleanedTavern"]}]
