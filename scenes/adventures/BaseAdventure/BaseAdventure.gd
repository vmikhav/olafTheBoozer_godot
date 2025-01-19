class_name BaseAdventure
extends Node2D

const TILE_SIZE = 16
const TILE_OFFSET = Vector2i(8, 18)

enum Layer {
	GROUND, FLOOR, WALLS, TRAILS, ITEMS, TREES
}

var defs = LevelDefinitions

var hint_scene: PackedScene = preload("res://scenes/sprites/QuestHint/QuestHint.tscn")

# parameters from an implemented scene
var music_key: String = "fairies"
var need_stop_music: bool = true
var tilemaps: Array[TileMapLayer]
var hero: Node2D
var hero_play_type: Array = ["worker", true]
var hero_start_position: Vector2i
var characters = []
var teleports = []
var interactive_zones = []
var camera_limit := Rect2i(-1000000, -1000000, 2000000, 2000000)
var next_scene = ["res://scenes/game/Playground/Playground.tscn", {levels = ["Tutorial0"]}]

# local variables
var hero_position: Vector2i
var allow_input: bool

signal level_finished


func init_map():
	allow_input = true
	hero.set_mode(hero_play_type)
	for i in characters.size():
		if "unit" in characters[i] and characters[i].unit:
			characters[i].unit.queue_free()
		characters[i].unit = hero.duplicate()
		tilemaps[Layer.ITEMS].add_child(characters[i].unit)
		characters[i].unit.set_mode([defs.UnitTypeName[characters[i].mode], false])
		move_unit_to_position(characters[i].unit, characters[i].position)
	for i in interactive_zones.size():
		if "hint_position" in interactive_zones[i]:
			var hint = hint_scene.instantiate()
			hint.position = ((Vector2(interactive_zones[i].hint_position) + Vector2(0.5, -0.85)) * TILE_SIZE).ceil()
			tilemaps[Layer.TREES].add_child(hint)
			hint.set_icon(interactive_zones[i].hint_type)
			hint.z_index = 50
			hint.scale = Vector2(0.5, 0.5)
			interactive_zones[i].hint = hint
			if !interactive_zones[i].active:
				hint.visible = false
	AudioController.play_music(music_key)

func activate_zone(index: int) -> void:
	interactive_zones[index].active = true
	if "hint" in interactive_zones[index]:
		interactive_zones[index].hint.visible = true

func deactivate_zone(index: int) -> void:
	interactive_zones[index].active = false
	deactivate_hint(index)

func deactivate_hint(index: int) -> void:
	if "hint" in interactive_zones[index]:
		interactive_zones[index].hint.visible = false

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
	
	for i in interactive_zones.size():
		if interactive_zones[i].active:
			for pos in interactive_zones[i].positions:
				if  pos == neighbor_pos:
					allow_input = false
					interactive_zones[i].callback.call(i)
					return

	var can_move_result = can_move_to(neighbor_pos)
	if not can_move_result.can_move:
		return
	
	# Update neighbor_pos if teleportation occurred
	neighbor_pos = can_move_result.new_position


	process_item_collection(neighbor_pos)

	move_hero_to_position(neighbor_pos)
	play_sfx_by_history(null)

	check_level_completion()

func can_move_to(neighbor_pos: Vector2i) -> Dictionary:
	if is_empty_cell(Layer.GROUND, neighbor_pos):
		skip_step()
		return {can_move = false, new_position = neighbor_pos}

	if not is_empty_cell(Layer.WALLS, neighbor_pos):
		return handle_teleport(neighbor_pos)

	var neighbor_cell = tilemaps[Layer.ITEMS].get_cell_atlas_coords(neighbor_pos)
	
	if neighbor_cell.x != -1:
		skip_step()
		return {can_move = false, new_position = neighbor_pos}

	return {can_move = true, new_position = neighbor_pos}

func handle_teleport(neighbor_pos: Vector2i) -> Dictionary:
	for teleport in teleports:
		if teleport.start == neighbor_pos:
			return {can_move = true, new_position = teleport.end}

	skip_step()
	return {can_move = false, new_position = neighbor_pos}

func process_item_collection(neighbor_pos: Vector2i):
	pass
	#var neighbor_cell = tilemaps[Layer.ITEMS].get_cell_atlas_coords(neighbor_pos)


func check_level_completion():
	if true == false:
		finish_level()

func finish_level():
	allow_input = false
	level_finished.emit()


func play_sfx_by_history(history_item):
	AudioController.play_sfx("step")


func is_simple_step(history_item) -> bool:
	return not "bad_item" in history_item and not "ghost" in history_item and not history_item.trails.size() and not "dragged_item" in history_item
