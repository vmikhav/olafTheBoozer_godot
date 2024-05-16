class_name BaseLevel
extends Node2D

const TILE_SIZE = 16
const TILE_OFFSET = Vector2i(8, 18)

enum Layer {
	GROUND, FLOOR, WALLS, ITEMS, TREES, BAD_ITEMS, GOOD_ITEMS
}

var defs = LevelDefinitions

# parameters from an implemented scene
var tilemap: TileMap
var hero: Node2D
var hero_play_type: Array = ["worker", true]
var hero_replay_type: Array = ["worker", true]
var hero_start_position: Vector2i
var ghosts = []
var teleports = []

# local variables
var hero_position: Vector2i
var allow_input: bool
var level_items_count: int
var level_items_progress: int
var ghosts_count: int
var ghosts_progress: int
var tail = []
var history = []
var is_history_replay: bool = false
var progress_report: LevelProgressReport

signal items_progress_signal(items_count: int)
signal ghosts_progress_signal(ghosts_count: int)
signal level_finished


func init_map(source: Layer = Layer.BAD_ITEMS):
	tilemap.clear_layer(Layer.ITEMS)
	tilemap.set_layer_enabled(Layer.BAD_ITEMS, false)
	tilemap.set_layer_enabled(Layer.GOOD_ITEMS, false)
	var bad_items = tilemap.get_used_cells(source)
	if source == Layer.BAD_ITEMS:
		allow_input = true
		is_history_replay = false
		hero.set_mode(hero_play_type)
		history = [{position = hero_position}]
		level_items_progress = 0
		level_items_count = bad_items.size()
		ghosts_progress = 0
		ghosts_count = ghosts.size()
		init_progress_report()
		for item in tail:
			item.unit.queue_free()
		tail = []
		for i in ghosts.size():
			if "unit" in ghosts[i] and ghosts[i].unit:
				ghosts[i].unit.queue_free()
			ghosts[i].unit = hero.duplicate()
			tilemap.add_child(ghosts[i].unit)
			ghosts[i].unit.set_mode([defs.UnitTypeName[ghosts[i].mode], false])
			ghosts[i].unit.make_ghost(ghosts[i].type)
			move_unit_to_position(ghosts[i].unit, ghosts[i].position)
	for pos in bad_items:
		update_cell(pos, tilemap.get_cell_atlas_coords(source, pos), tilemap.get_cell_alternative_tile(source, pos))

func restart():
	is_history_replay = false
	allow_input = true
	init_progress_report()
	while history.size() > 1:
		step_back()
	hero.set_mode(hero_play_type)
	ghosts_progress_signal.emit(ghosts_progress)
	items_progress_signal.emit(level_items_progress)

func move_unit_to_position(unit: Node2D, new_position: Vector2i):
	unit.position = new_position * TILE_SIZE + TILE_OFFSET

func move_oriented_unit_to_position(unit: Node2D, new_position: Vector2i):
	var new_absolute_position := new_position * TILE_SIZE + TILE_OFFSET
	if new_absolute_position.x > unit.position.x:
		unit.set_orientation('right')
	if new_absolute_position.x < unit.position.x:
		unit.set_orientation('left')
	unit.position = new_absolute_position

func move_hero_to_position(new_position: Vector2i):
	hero_position = new_position
	move_oriented_unit_to_position(hero, new_position)

func is_empty_cell(layer: Layer, cell_position: Vector2i) -> bool:
	var atlas_pos = tilemap.get_cell_atlas_coords(layer, cell_position)
	return atlas_pos.x == -1

func skip_step():
	hero.hit()
	AudioController.play_sfx("bump")

func update_cell(pos: Vector2i, new_value: Vector2i, alternative: int):
	if new_value.x == -1:
		tilemap.erase_cell(Layer.ITEMS, pos)
	else:
		tilemap.set_cell(Layer.ITEMS, pos, 0, new_value, alternative)

func navigate(direction: TileSet.CellNeighbor, skip_check = false):
	if not allow_input and not skip_check:
		return

	if direction == TileSet.CELL_NEIGHBOR_RIGHT_SIDE:
		hero.set_orientation('right')
	if direction == TileSet.CELL_NEIGHBOR_LEFT_SIDE:
		hero.set_orientation('left')
	
	var neighbor_pos = tilemap.get_neighbor_cell(hero_position, direction)
	var history_item = {position = neighbor_pos, direction = direction}
	# no floor
	if is_empty_cell(Layer.GROUND, neighbor_pos):
		skip_step()
		return
	# check teleports and walls
	if not is_empty_cell(Layer.WALLS, neighbor_pos):
		for teleport in teleports:
			if teleport.start == neighbor_pos:
				history_item.teleported = true
				neighbor_pos = teleport.end
				history_item.position = neighbor_pos
				break
		if not 'teleported' in history_item:
			skip_step()
			return
	
	# avoid bots from tail
	for item in tail:
		if item.position == neighbor_pos:
			skip_step()
			return
	
	var neighbor_cell = tilemap.get_cell_atlas_coords(Layer.ITEMS, neighbor_pos)
	var bad_neighbor_cell = tilemap.get_cell_atlas_coords(Layer.BAD_ITEMS, neighbor_pos)
	var bad_neighbor_alt = tilemap.get_cell_alternative_tile(Layer.BAD_ITEMS, neighbor_pos)
	var good_neighbor_cell = tilemap.get_cell_atlas_coords(Layer.GOOD_ITEMS, neighbor_pos)
	var good_neighbor_alt = tilemap.get_cell_alternative_tile(Layer.GOOD_ITEMS, neighbor_pos)
	# check and update item status
	if neighbor_cell.x != -1: # if cell is set
		if neighbor_cell != bad_neighbor_cell or not process_trail(neighbor_pos):
			skip_step()
			return
		update_cell(neighbor_pos, good_neighbor_cell, good_neighbor_alt)
		history_item.bad_item = bad_neighbor_cell
		history_item.bad_item_alt = bad_neighbor_alt
		history_item.good_item = good_neighbor_cell
		history_item.good_item_alt = good_neighbor_alt
		level_items_progress += 1
		items_progress_signal.emit(level_items_progress)
	# add bot to tail
	if history.size() and "ghost_type" in history[-1] and history[-1].ghost_type == LevelDefinitions.GhostType.ENEMY:
		var unit = hero.duplicate()
		tilemap.add_child(unit)
		unit.set_mode([defs.UnitTypeName[history[-1].ghost_mode], false])
		move_unit_to_position(unit, history[-1].position)
		unit.make_follower()
		tail.push_front({
			unit = unit,
			unit_mode = history[-1].ghost_mode,
			position = history[-1].position,
			history_position = history.size() - 1,
			movement_mode = "follow",
		})
		history_item.tail_changed = true
		for item in tail:
			if item.movement_mode == "follow":
				item.history_position -= 1
	# make tail follow a hero
	for item in tail:
		if item.movement_mode == "follow":
			item.history_position += 1
			item.position = history[item.history_position].position
			move_oriented_unit_to_position(item.unit, item.position)
	for i in ghosts.size():
		var _can_consume_ghost = false
		if ghosts[i].type == LevelDefinitions.GhostType.ENEMY_SPAWN:
			for item in tail:
				if (item.movement_mode == "follow"
					and item.unit_mode == ghosts[i].mode
					and item.position == ghosts[i].position):
					item.movement_mode = "chill"
					_can_consume_ghost = true
					break
		elif neighbor_pos == ghosts[i].position:
			_can_consume_ghost = true
		if _can_consume_ghost:
			ghosts_progress += 1
			ghosts_progress_signal.emit(ghosts_progress)
			ghosts[i].unit.visible = false
			history_item.ghost = ghosts[i].unit
			history_item.ghost_position = ghosts[i].position
			history_item.ghost_type = ghosts[i].type
			history_item.ghost_mode = ghosts[i].mode
			ghosts.remove_at(i)
			break
	move_hero_to_position(neighbor_pos)
	save_history_item(history_item)
	play_sfx_by_history(history_item)
	if ghosts_progress == ghosts_count:
		finish_level()

func finish_level():
	allow_input = false
	level_finished.emit()
	get_tree().create_timer(0.5).timeout.connect(func():
		AudioController.play_sfx("fanfare")
		hero.set_mode(hero_replay_type)
	)

func step_back():
	if history.size() <= 1:
		is_history_replay = false
		return
	var history_item = history.pop_back()
	if is_history_replay:
		play_sfx_by_history(history_item)
	var history_position_item = history[-1]
	move_hero_to_position(history_position_item.position)
	if "bad_item" in history_item:
		update_cell(history_item.position, history_item.bad_item, history_item.bad_item_alt)
		level_items_progress -= 1
	if "ghost" in history_item:
		if history_item.ghost_type == LevelDefinitions.GhostType.ENEMY_SPAWN:
			for item in tail:
				if item.position == history_item.ghost_position:
					item.movement_mode = "follow"
					break
		history_item.ghost.make_ghost(history_item.ghost_type)
		history_item.ghost.visible = true
		ghosts.push_back({
			position = history_item.ghost_position,
			type = history_item.ghost_type,
			mode = history_item.ghost_mode,
			unit = history_item.ghost,
		})
		ghosts_progress -= 1
	if "tail_changed" in history_item:
		tail.pop_front().unit.die(is_history_replay)
	else:
		for item in tail:
			if item.movement_mode == "follow":
				item.history_position -= 1
				item.position = history[item.history_position].position
				move_oriented_unit_to_position(item.unit, item.position)
	if not is_history_replay:
		ghosts_progress_signal.emit(ghosts_progress)
		items_progress_signal.emit(level_items_progress)

func replay():
	allow_input = false
	is_history_replay = true
	step_back()
	while is_history_replay and history.size() > 1:
		await get_tree().create_timer(0.15 + randf_range(0, 0.075)).timeout
		if is_history_replay:
			step_back()

func play_sfx_by_history(history_item):
	if "ghost" in history_item:
		AudioController.play_sfx("pickup")
		return
	if "bad_item" in history_item:
		AudioController.play_sfx_by_tiles(history_item.bad_item, history_item.good_item)
		return
	AudioController.play_sfx("step")

func save_history_item(item):
	var size = history.size()
	if is_simple_step(item) and size >= 2:
		if is_simple_step(history[size-1]) and history[size-2].position == item.position:
			history.pop_back()
			return
	history.push_back(item)

func is_simple_step(history_item) -> bool:
	return not "bad_item" in history_item and not "ghost" in history_item

func process_trail(trail_position: Vector2i) -> bool:
	var directions = {
		side = [
			TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
			TileSet.CELL_NEIGHBOR_TOP_SIDE,
			TileSet.CELL_NEIGHBOR_LEFT_SIDE,
			TileSet.CELL_NEIGHBOR_RIGHT_SIDE
		],
		#5,19 up 6,19 down 5,20 right 6,20 left
		backward_tile = ["5,19", "6,19", "5,20", "6,20"],
		forward_tile = ["6,19", "5,19", "6,20", "5,20"],
	}
	var cell = tilemap.get_cell_atlas_coords(Layer.ITEMS, trail_position)
	var cell_value = str(cell.x) + "," + str(cell.y)
	var cell_index = directions.forward_tile.find(cell_value)
	if cell_index == -1:
		# not trail
		return true
	
	cell = tilemap.get_cell_atlas_coords(
		Layer.ITEMS,
		tilemap.get_neighbor_cell(trail_position, directions.side[cell_index])
	)
	cell_value = str(cell.x) + "," + str(cell.y)
	if directions.forward_tile.has(cell_value):
		# not first item of trail
		return false
	var next_direction = null
	for i in directions.side.size():
		cell = tilemap.get_cell_atlas_coords(
			Layer.ITEMS,
			tilemap.get_neighbor_cell(trail_position, directions.side[i])
		)
		cell_value = str(cell.x) + "," + str(cell.y)
		if directions.backward_tile[i] == cell_value:
			next_direction = directions.side[i]
			break
	
	if next_direction != null:
		allow_input = false
		var timer = get_tree().create_timer(0.175 + randf_range(0, 0.075))
		timer.timeout.connect(func():
			navigate(next_direction, true)
		)
	else:
		allow_input = true
	return true

func init_progress_report():
	progress_report = LevelProgressReport.new()
	progress_report.total_items = level_items_count
	progress_report.total_ghosts = ghosts_count

func fill_progress_report() -> LevelProgressReport:
	progress_report.mark_as_filled(history)
	progress_report.progress_items = level_items_progress
	progress_report.progress_ghosts = ghosts_progress
	progress_report.finished = ghosts_progress == ghosts_count
	progress_report.score = calc_score()
	return progress_report

func calc_score() -> int:
	return ceili((progress_report.progress_items * 1.0 / progress_report.total_items) * 100)
