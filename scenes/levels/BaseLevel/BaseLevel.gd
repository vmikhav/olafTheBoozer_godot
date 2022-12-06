class_name BaseLevel
extends Node2D

const TILE_SIZE = 16
const TILE_OFFSET = Vector2i(8, 18)

enum Layer {
	GROUND, FLOOR, WALLS, ITEMS, TREES, BAD_ITEMS, GOOD_ITEMS
}

@onready var sounds_map = SoundsMap.new() as SoundsMap

var hero_position: Vector2i
var hero_start_position: Vector2i
var tilemap: TileMap
var hero: Node2D
var allow_input: bool
var level_items_count: int
var level_progress: int
var ghosts = []
var teleports = []
var ghosts_count: int
var ghosts_progress: int
var history = []
var is_history_replay: bool = false

signal items_progress_signal(items_count: int)
signal ghosts_progress_signal(ghosts_count: int)
signal level_finished
signal playback_finished

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func init_map(source: Layer = Layer.BAD_ITEMS):
	tilemap.clear_layer(Layer.ITEMS)
	tilemap.set_layer_enabled(Layer.BAD_ITEMS, false)
	tilemap.set_layer_enabled(Layer.GOOD_ITEMS, false)
	var bad_items = tilemap.get_used_cells(source)
	if source == Layer.BAD_ITEMS:
		allow_input = true
		is_history_replay = false
		history = [{position = hero_position}]
		level_progress = 0
		level_items_count = bad_items.size()
		ghosts_progress = 0
		ghosts_count = ghosts.size()
		for i in ghosts.size():
			if "unit" in ghosts[i] and ghosts[i].unit:
				ghosts[i].unit.queue_free()
			ghosts[i].unit = hero.duplicate()
			tilemap.add_child(ghosts[i].unit)
			ghosts[i].unit.make_ghost()
			move_unit_to_position(ghosts[i].unit, ghosts[i].position)
	for pos in bad_items:
		tilemap.set_cell(Layer.ITEMS, pos, 0, tilemap.get_cell_atlas_coords(source, pos))

func restart():
	is_history_replay = false
	allow_input = true
	while history.size() > 1:
		step_back()
	ghosts_progress_signal.emit(ghosts_progress)
	items_progress_signal.emit(level_progress)

func move_unit_to_position(unit: Node2D, position: Vector2i):
	unit.position = position * TILE_SIZE + TILE_OFFSET

func move_hero_to_position(position: Vector2i):
	hero_position = position
	move_unit_to_position(hero, position)

func is_empty_cell(layer: Layer, position: Vector2i) -> bool:
	var atlas_pos = tilemap.get_cell_atlas_coords(layer, position)
	return atlas_pos.x == -1

func skip_step():
	hero.hit()
	play_sfx("bump")

func update_cell(pos: Vector2i, new_value: Vector2i):
	if new_value.x == -1:
		tilemap.erase_cell(Layer.ITEMS, pos)
	else:
		tilemap.set_cell(Layer.ITEMS, pos, 0, new_value)

func navigate(direction: TileSet.CellNeighbor, skip_check = false):
	if not allow_input and not skip_check:
		return

	if direction == TileSet.CELL_NEIGHBOR_RIGHT_SIDE:
		hero.set_orientation('right')
	if direction == TileSet.CELL_NEIGHBOR_LEFT_SIDE:
		hero.set_orientation('left')
	
	var neighbor_pos = tilemap.get_neighbor_cell(hero_position, direction)
	var history_item = {position = neighbor_pos}	
	if is_empty_cell(Layer.GROUND, neighbor_pos):
		skip_step()
		return
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
	
	var neighbor_cell = tilemap.get_cell_atlas_coords(Layer.ITEMS, neighbor_pos) 
	var bad_neighbor_cell = tilemap.get_cell_atlas_coords(Layer.BAD_ITEMS, neighbor_pos) 
	var good_neighbor_cell = tilemap.get_cell_atlas_coords(Layer.GOOD_ITEMS, neighbor_pos) 
	if neighbor_cell.x != -1:
		if neighbor_cell != bad_neighbor_cell or not process_trail(neighbor_pos):
			skip_step()
			return
		update_cell(neighbor_pos, good_neighbor_cell)
		history_item.bad_item = bad_neighbor_cell
		history_item.good_item = good_neighbor_cell
		level_progress += 1
		items_progress_signal.emit(level_progress)
	for i in ghosts.size():
		if neighbor_pos == ghosts[i].position:
			ghosts_progress += 1
			ghosts_progress_signal.emit(ghosts_progress)
			ghosts[i].unit.visible = false
			history_item.ghost = ghosts[i].unit
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
	get_tree().create_timer(0.5).timeout.connect(play_sfx.bind("fanfare"))
	get_tree().create_timer(1.5).timeout.connect(replay)

func step_back():
	if history.size() <= 1:
		is_history_replay = false
		return
	var history_item = history.pop_back()
	if is_history_replay:
		play_sfx_by_history(history_item)
	var history_position_item = history[history.size() - 1]
	if history_position_item.position.x > hero_position.x:
		hero.set_orientation('right')
	if history_position_item.position.x < hero_position.x:
		hero.set_orientation('left')
	move_hero_to_position(history_position_item.position)
	if "bad_item" in history_item:
		update_cell(history_item.position, history_item.bad_item)
		level_progress -= 1
	if "ghost" in history_item:
		history_item.ghost.visible = true
		ghosts.push_back({position = history_item.position, unit = history_item.ghost})
		ghosts_progress -= 1
	if not is_history_replay:
		ghosts_progress_signal.emit(ghosts_progress)
		items_progress_signal.emit(level_progress)

func replay():
	allow_input = false
	is_history_replay = true
	step_back()
	while is_history_replay and history.size() > 1:
		await get_tree().create_timer(0.15 + randf_range(0, 0.075)).timeout
		if is_history_replay:
			step_back()
	await get_tree().create_timer(1.5).timeout
	if is_history_replay:
		playback_finished.emit()

func play_sfx(name: String):
	var player = AudioStreamPlayer.new()
	player.bus = "SFX"
	if name == "vomit":
		player.volume_db = -3
	player.stream = sounds_map.sounds[name]
	add_child(player)
	player.play()
	await player.finished
	player.queue_free()

func play_sfx_by_history(history_item):
	if "ghost" in history_item:
		play_sfx("pickup")
		return
	if "bad_item" in history_item:
		play_sfx(sounds_map.get_sound(history_item.bad_item, history_item.good_item))
		return
	play_sfx("step")

func save_history_item(item):
	var size = history.size()
	if is_simple_step(item) and size >= 2:
		if is_simple_step(history[size-1]) and history[size-2].position == item.position:
			history.pop_back()
			return
	history.push_back(item)

func is_simple_step(history_item) -> bool:
	return not "bad_item" in history_item and not "ghost" in history_item

func process_trail(position: Vector2i) -> bool:
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
	var cell = tilemap.get_cell_atlas_coords(Layer.ITEMS, position)
	var cell_value = str(cell.x) + "," + str(cell.y)
	var cell_index = directions.forward_tile.find(cell_value)
	if cell_index == -1:
		# not trail
		return true
	
	cell = tilemap.get_cell_atlas_coords(
		Layer.ITEMS,
		tilemap.get_neighbor_cell(position, directions.side[cell_index])
	)
	cell_value = str(cell.x) + "," + str(cell.y)
	if directions.forward_tile.has(cell_value):
		# not first item of trail
		return false
	var next_direction = null
	for i in directions.side.size():
		cell = tilemap.get_cell_atlas_coords(
			Layer.ITEMS,
			tilemap.get_neighbor_cell(position, directions.side[i])
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
