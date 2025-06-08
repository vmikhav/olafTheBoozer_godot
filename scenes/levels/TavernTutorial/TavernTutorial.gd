extends BaseLevel

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemaps = [
		$Ground, $Floor, $Walls, $Trails, $Items, $Trees, $BadItems, $GoodItems, $MovingItems,
	]
	hero = $Items/Demolitonist
	hero_start_position = Vector2i(-2, 0)
	ghosts = [
		{position = Vector2i(3, 1), type = defs.GhostType.MEMORY, mode = defs.UnitType.DEMOLITONIST},
		{position = Vector2i(-7, 1), type = defs.GhostType.MEMORY, mode = defs.UnitType.GRENADIER},
		{position = Vector2i(1, -2), type = defs.GhostType.MEMORY, mode = defs.UnitType.WORKER},
	]
	teleports = [
	]
	camera_limit = Rect2i(-304, -192, 608, 352)
	move_hero_to_position(hero_start_position)
	init_map()
	next_scene = ["res://scenes/game/AdventurePlayground/AdventurePlayground.tscn", {levels = ["StartTavern"]}]
