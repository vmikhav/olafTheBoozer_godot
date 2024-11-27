class_name BaseAdventure
extends Node2D

const TILE_SIZE = 16
const TILE_OFFSET = Vector2i(8, 18)

enum Layer {
	GROUND, FLOOR, WALLS, TRAILS, ITEMS, TREES
}

var defs = LevelDefinitions

# parameters from an implemented scene
var music_key: String = "fairies"
var tilemaps: Array[TileMapLayer]
var hero: Node2D
var hero_play_type: Array = ["worker", true]
var hero_replay_type: Array = ["worker", true]
var hero_start_position: Vector2i
var ghosts = []
var teleports = []
var camera_limit := Rect2i(-1000000, -1000000, 2000000, 2000000)

# local variables
var hero_position: Vector2i
var allow_input: bool

signal level_finished


func init_map():
	allow_input = true
	hero.set_mode(hero_play_type)
	AudioController.play_music(music_key)

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
	var atlas_pos = tilemaps[layer].get_cell_atlas_coords(cell_position)
	return atlas_pos.x == -1

func skip_step():
	hero.hit()
	AudioController.play_sfx("bump")

func update_cell(pos: Vector2i, new_value: Vector2i, alternative: int, layer: Layer = Layer.ITEMS):
	if new_value.x == -1:
		tilemaps[layer].erase_cell(pos)
	else:
		tilemaps[layer].set_cell(pos, 0, new_value, alternative)

func navigate(direction: TileSet.CellNeighbor, skip_check = false):
	if not allow_input and not skip_check:
		return

	if direction == TileSet.CELL_NEIGHBOR_RIGHT_SIDE:
		hero.set_orientation('right')
	if direction == TileSet.CELL_NEIGHBOR_LEFT_SIDE:
		hero.set_orientation('left')

	var neighbor_pos = tilemaps[Layer.ITEMS].get_neighbor_cell(hero_position, direction)
	var history_item = {position = neighbor_pos, direction = direction, trails = []}

	var can_move_result = can_move_to(neighbor_pos, history_item)
	if not can_move_result.can_move:
		return
	
	# Update neighbor_pos if teleportation occurred
	neighbor_pos = can_move_result.new_position


	process_item_collection(neighbor_pos, history_item)

	move_hero_to_position(neighbor_pos)
	play_sfx_by_history(history_item)

	check_level_completion()

func can_move_to(neighbor_pos: Vector2i, history_item: Dictionary) -> Dictionary:
	if is_empty_cell(Layer.GROUND, neighbor_pos):
		skip_step()
		return {can_move = false, new_position = neighbor_pos}

	if not is_empty_cell(Layer.WALLS, neighbor_pos):
		return handle_teleport(neighbor_pos, history_item)

	var neighbor_cell = tilemaps[Layer.ITEMS].get_cell_atlas_coords(neighbor_pos)
	
	if neighbor_cell.x != -1:
		skip_step()
		return {can_move = false, new_position = neighbor_pos}

	return {can_move = true, new_position = neighbor_pos}

func handle_teleport(neighbor_pos: Vector2i, history_item: Dictionary) -> Dictionary:
	for teleport in teleports:
		if teleport.start == neighbor_pos:
			process_teleport(teleport, history_item)
			return {can_move = true, new_position = teleport.end}

	skip_step()
	return {can_move = false, new_position = neighbor_pos}

func process_teleport(teleport, history_item: Dictionary):
	if not is_empty_cell(Layer.TRAILS, teleport.start):
		allow_input = true
		history_item.trails.push_back({
			position = teleport.start,
			cell = tilemaps[Layer.TRAILS].get_cell_atlas_coords(teleport.start)
		})
	history_item.teleported = true
	history_item.position = teleport.end

func process_item_collection(neighbor_pos: Vector2i, history_item: Dictionary):
	var neighbor_cell = tilemaps[Layer.ITEMS].get_cell_atlas_coords(neighbor_pos)


func check_level_completion():
	if true == false:
		finish_level()

func finish_level():
	allow_input = false
	level_finished.emit()


func play_sfx_by_history(history_item):
	if "ghost" in history_item:
		AudioController.play_sfx("pickup")
		return
	if "bad_item" in history_item:
		AudioController.play_sfx_by_tiles(history_item.bad_item, history_item.good_item)
		return
	if history_item.trails.size():
		AudioController.play_sfx_by_tiles(history_item.trails[0].cell)
		return
	AudioController.play_sfx("step")


func is_simple_step(history_item) -> bool:
	return not "bad_item" in history_item and not "ghost" in history_item and not history_item.trails.size() and not "dragged_item" in history_item
