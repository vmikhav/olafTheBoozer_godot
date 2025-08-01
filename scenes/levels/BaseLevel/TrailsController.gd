extends Resource
class_name TrailsController

var defs = LevelDefinitions
var hint_scene: PackedScene = preload("res://scenes/sprites/QuestHint/QuestHint.tscn")

var trails_layer: TileMapLayer
var hints_layer: TileMapLayer
var level: BaseLevel

var active_trail_hints = []
var waiting_for_trail_choice: bool = false
var available_trail_directions = []


func process_trails(neighbor_pos: Vector2i, history_item: Dictionary) -> bool:
	var trail_neighbor_cell = trails_layer.get_cell_atlas_coords(neighbor_pos)
	var came_from_direction = defs.get_opposite_direction(history_item.direction)
	if trail_neighbor_cell.x != -1:
		if not check_trail(neighbor_pos, history_item.direction):
			level.skip_step()
			return false
		history_item.trails.push_back({
			position = neighbor_pos,
			cell = trail_neighbor_cell
		})
		process_trail(neighbor_pos, came_from_direction)

	for trail in history_item.trails:
		var trail_cell_value = str(trail.cell.x) + "," + str(trail.cell.y)
		var directions = defs.TrailDirections.directions[trail_cell_value]
		
		if history_item.direction in directions:
			directions = directions.filter(func(dir): return dir != history_item.direction)
		else:
			for direction in directions:
				var checking_direction = defs.get_opposite_direction(direction)
				var neighbor2_pos = trails_layer.get_neighbor_cell(trail.position, checking_direction)
				var neighbor2_cell = trails_layer.get_cell_atlas_coords(neighbor2_pos)
				if neighbor2_cell.x == -1:
					directions = directions.filter(func(dir): return dir != direction)
					break
				
		level.update_cell(trail.position, get_tile_coords_for_directions(directions), 0, BaseLevel.Layer.TRAILS)

	return true


func handle_trails_reversal(history_item: Dictionary, next_history_item: Dictionary, hero_position: Vector2i, manual: bool):
	clear_trail_choices()
	if history_item.trails.size():
		restore_trails(history_item.trails)
		
		# Check if this was a choice point and we're doing manual rollback
		if manual and history_item.has("is_trail_choice_point") and history_item.is_trail_choice_point:
			# Stop rollback here and show choices again if it's a multi-direction tile
			var came_from_direction = defs.get_opposite_direction(next_history_item.direction)
			var available_directions = []
			for direction in defs.TrailDirections.sides:
				if direction == came_from_direction:
					continue
				var neighbor_pos = trails_layer.get_neighbor_cell(hero_position, direction)
				var neighbor_cell = trails_layer.get_cell_atlas_coords(neighbor_pos)
				var neighbor_value = str(neighbor_cell.x) + "," + str(neighbor_cell.y)
				
				# Check if neighbor is a trail tile that could lead to this position
				if defs.TrailDirections.directions.has(neighbor_value) and direction in defs.TrailDirections.directions[neighbor_value]:
					available_directions.append(direction)
			if available_directions.size() > 1:
				show_trail_choices(hero_position, available_directions)
				return
		
		if manual and next_history_item.trails.size():
			level.schedule_next_step_back(manual)

func restore_trails(trails: Array):
	for trail in trails:
		level.update_cell(trail.position, trail.cell, 0, BaseLevel.Layer.TRAILS)

func check_trail(trail_position: Vector2i, step_direction: TileSet.CellNeighbor) -> bool:
	var cell = trails_layer.get_cell_atlas_coords(trail_position)
	var cell_value = str(cell.x) + "," + str(cell.y)
	
	# Check if it's a trail tile
	if not defs.TrailDirections.directions.has(cell_value):
		return true # not a trail
	
	var directions = defs.TrailDirections.directions[cell_value]
	
	# Check how many directions have valid predecessors
	var predecessor_count = 0
	for direction in directions:
		var checking_direction = defs.get_opposite_direction(direction)
		#if checking_direction == came_from_direction:
		if direction == step_direction:
			continue
		var neighbor_pos = trails_layer.get_neighbor_cell(trail_position, checking_direction)
		var neighbor_cell = trails_layer.get_cell_atlas_coords(neighbor_pos)
		var neighbor_value = str(neighbor_cell.x) + "," + str(neighbor_cell.y)
		
		# Check if neighbor is a trail tile that could lead to this position
		if defs.TrailDirections.directions.has(neighbor_value):
			predecessor_count += 1
	
	# Can start if there are no predecessors, or if coming from a trail sequence
	return predecessor_count < directions.size()

func process_trail(trail_position: Vector2i, came_from_direction: TileSet.CellNeighbor) -> void:
	var available_directions = []
	
	for direction in defs.TrailDirections.sides:
		if direction == came_from_direction:
			continue
		var neighbor_pos = trails_layer.get_neighbor_cell(trail_position, direction)
		var neighbor_cell = trails_layer.get_cell_atlas_coords(neighbor_pos)
		var neighbor_value = str(neighbor_cell.x) + "," + str(neighbor_cell.y)
		
		# Check if neighbor is a trail tile that could lead to this position
		if defs.TrailDirections.directions.has(neighbor_value) and direction in defs.TrailDirections.directions[neighbor_value]:
			available_directions.append(direction)
	
	# Check if we need to continue automatically or wait for choice
	if available_directions.size() == 1:
		# Continue automatically in the only available direction (includes original single-direction behavior)
		var next_direction = available_directions[0]
		level.schedule_next_step(next_direction, 0.125 + randf_range(0, 0.075))
	else:
		if available_directions.size() > 1:
			show_trail_choices(trail_position, available_directions)

func get_tile_coords_for_directions(directions: Array) -> Vector2i:
	if directions.is_empty():
		return Vector2i(-1, -1)
	
	# Create sorted key from direction names
	var dir_names = []
	for direction in directions:
		dir_names.append(defs.get_direction_key(direction))
	dir_names.sort()
	var key = ",".join(dir_names)
	
	if defs.TrailDirections.tiles.has(key):
		var coords_str = defs.TrailDirections.tiles[key]
		var coords = coords_str.split(",")
		return Vector2i(int(coords[0]), int(coords[1]))
	
	return Vector2i(-1, -1)

func show_trail_choices(start_position: Vector2i, directions: Array):
	waiting_for_trail_choice = true
	available_trail_directions = directions
	level.allow_input = true
	
	# Create quest hints for each available direction
	for direction in directions:
		var target_pos = trails_layer.get_neighbor_cell(start_position, direction)
		var hint = hint_scene.instantiate()
		hints_layer.add_child(hint)
		hint.z_index = 100
		hint.position = target_pos * BaseLevel.TILE_SIZE + Vector2i(8, 12)
		match direction:
			TileSet.CELL_NEIGHBOR_RIGHT_SIDE:
				hint.set_icon(31)
			TileSet.CELL_NEIGHBOR_LEFT_SIDE:
				hint.set_icon(30)
			TileSet.CELL_NEIGHBOR_TOP_SIDE:
				hint.set_icon(32)
			TileSet.CELL_NEIGHBOR_BOTTOM_SIDE:
				hint.set_icon(33)
		active_trail_hints.append(hint)

func clear_trail_choices():
	waiting_for_trail_choice = false
	available_trail_directions.clear()
	for hint in active_trail_hints:
		hint.queue_free()
	active_trail_hints.clear()
