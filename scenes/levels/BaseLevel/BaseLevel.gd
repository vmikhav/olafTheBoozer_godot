class_name BaseLevel
extends Node2D

const TILE_SIZE = 16
const TILE_OFFSET = Vector2i(8, 18)

enum Layer {
	GROUND, FLOOR, WALLS, ITEMS, TREES, BAD_ITEMS, GOOD_ITEMS
}

var hero_position: Vector2i
var tilemap: TileMap
var hero: Node2D
var allow_input: bool
var level_items_count: int
var level_progress: int
var ghosts = []
var ghosts_count: int
var ghosts_progress: int
var history = []

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
	print('blocked')

func update_cell(pos: Vector2i, new_value: Vector2i):
	if new_value.x == -1:
		tilemap.erase_cell(Layer.ITEMS, pos)
	else:
		tilemap.set_cell(Layer.ITEMS, pos, 0, new_value)

func navigate(direction: TileSet.CellNeighbor):
	if not allow_input:
		return

	if direction == TileSet.CELL_NEIGHBOR_RIGHT_SIDE:
		hero.set_orientation('right')
	if direction == TileSet.CELL_NEIGHBOR_LEFT_SIDE:
		hero.set_orientation('left')
	
	var neighbor_pos = tilemap.get_neighbor_cell(hero_position, direction)
	if is_empty_cell(Layer.GROUND, neighbor_pos):
		skip_step()
		return
	if not is_empty_cell(Layer.WALLS, neighbor_pos):
		skip_step()
		return
	
	var history_item = {position = neighbor_pos}
	var neighbor_cell = tilemap.get_cell_atlas_coords(Layer.ITEMS, neighbor_pos) 
	var bad_neighbor_cell = tilemap.get_cell_atlas_coords(Layer.BAD_ITEMS, neighbor_pos) 
	var good_neighbor_cell = tilemap.get_cell_atlas_coords(Layer.GOOD_ITEMS, neighbor_pos) 
	if neighbor_cell.x != -1:
		if neighbor_cell != bad_neighbor_cell:
			skip_step()
			return
		update_cell(neighbor_pos, good_neighbor_cell)
		history_item.bad_item = bad_neighbor_cell
		history_item.good_item = good_neighbor_cell
		level_progress += 1
	for i in ghosts.size():
		if neighbor_pos == ghosts[i].position:
			ghosts_progress += 1
			ghosts[i].unit.visible = false
			history_item.ghost = ghosts[i].unit
			ghosts.remove_at(i)
			break
	move_hero_to_position(neighbor_pos)
	history.push_back(history_item)
	if ghosts_progress == ghosts_count:
		replay()
	

func replay():
	history.reverse()
	for history_item in history:
		if history_item.position.x > hero_position.x:
			hero.set_orientation('right')
		if history_item.position.x < hero_position.x:
			hero.set_orientation('left')
		move_hero_to_position(history_item.position)
		if "bad_item" in history_item:
			update_cell(history_item.position, history_item.bad_item)
			level_progress -= 1
		if "ghost" in history_item:
			history_item.ghost.visible = true
			ghosts.push_back({position = history_item.position, unit = history_item.ghost})
			ghosts_progress -= 1
	history = [{position = hero_position}]
