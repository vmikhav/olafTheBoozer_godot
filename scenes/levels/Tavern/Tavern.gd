extends BaseLevel

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemaps = [
		$Ground, $Floor, $PressPlates, $Liquids, $Walls, $Trails, $Items, $Trees, $BadItems, $GoodItems, $MovingItems
	]
	hero = $Items/Demolitonist
	hero_start_position = Vector2i(7, 5)
	ghosts = [
		{position = Vector2i(7, 4), type = defs.GhostType.MEMORY, mode = defs.UnitType.WORKER},
		{position = Vector2i(-2, 8), type = defs.GhostType.MEMORY, mode = defs.UnitType.WORKER},
	]
	teleports = [
		{start = Vector2i(2, 6), end = Vector2i(-15, -3)},
	]
	camera_limit = Rect2i(-304, -128, 608, 288)
	move_hero_to_position(hero_start_position, null)
	init_map()

func get_level_item_trigers() -> Array:
	return [
		{
			"id": "barrel_1",
			"position": Vector2i(8, 2),
			"changesets": ["drain_puddles"]
		}
	]

func get_level_changesets() -> Array:
	return [
		{
			"id": "drain_puddles",
			"description": "Drain puddles",
			"changes": [
				{
					"position": Vector2i(7, 1),
					"layer": BaseLevel.Layer.LIQUIDS,
					"old_coords": null,
					"new_coords": Vector2i(-1, -1)
				},
				{
					"position": Vector2i(8, 1),
					"layer": BaseLevel.Layer.LIQUIDS,
					"old_coords": null,
					"new_coords": Vector2i(-1, -1)
				},
				{
					"position": Vector2i(9, 1),
					"layer": BaseLevel.Layer.LIQUIDS,
					"old_coords": null,
					"new_coords": Vector2i(-1, -1)
				},
				{
					"position": Vector2i(6, 2),
					"layer": BaseLevel.Layer.LIQUIDS,
					"old_coords": null,
					"new_coords": Vector2i(-1, -1)
				},
				{
					"position": Vector2i(7, 2),
					"layer": BaseLevel.Layer.LIQUIDS,
					"old_coords": null,
					"new_coords": Vector2i(-1, -1)
				},
				{
					"position": Vector2i(8, 2),
					"layer": BaseLevel.Layer.LIQUIDS,
					"old_coords": null,
					"new_coords": Vector2i(-1, -1)
				},
				{
					"position": Vector2i(9, 2),
					"layer": BaseLevel.Layer.LIQUIDS,
					"old_coords": null,
					"new_coords": Vector2i(-1, -1)
				},
				{
					"position": Vector2i(6, 3),
					"layer": BaseLevel.Layer.LIQUIDS,
					"old_coords": null,
					"new_coords": Vector2i(-1, -1)
				},
				{
					"position": Vector2i(7, 3),
					"layer": BaseLevel.Layer.LIQUIDS,
					"old_coords": null,
					"new_coords": Vector2i(-1, -1)
				},
				{
					"position": Vector2i(8, 3),
					"layer": BaseLevel.Layer.LIQUIDS,
					"old_coords": null,
					"new_coords": Vector2i(-1, -1)
				},
				{
					"position": Vector2i(9, 3),
					"layer": BaseLevel.Layer.LIQUIDS,
					"old_coords": null,
					"new_coords": Vector2i(-1, -1)
				},
			]
		}
	]
