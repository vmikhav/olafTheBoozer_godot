extends Node2D
enum Layers {GROUND, FLOOR, WALLS, ITEMS, TREES}
#     1
#    2 4
#16|  8  |24
const wood_walls = [
#                0               1               2               3               4               5               6               7
	Vector2i(0, 9), Vector2i(0, 8), Vector2i(3, 9), Vector2i(3, 8), Vector2i(1, 9), Vector2i(1, 8), Vector2i(2, 9), Vector2i(2, 8),
#                8               9              10              11              12              13              14              15
	Vector2i(0, 6), Vector2i(0, 7), Vector2i(3, 6), Vector2i(3, 7), Vector2i(1, 6), Vector2i(1, 7), Vector2i(2, 6), Vector2i(2, 7),
#               16              17              18              19              20              21              22              23
	Vector2i(4, 8), Vector2i(4, 9), Vector2i(7, 8), Vector2i(7, 9), Vector2i(5, 8), Vector2i(5, 9), Vector2i(6, 8), Vector2i(6, 9),
#               24              25              26              27              28              29              30              31
	Vector2i(4, 6), Vector2i(4, 7), Vector2i(7, 6), Vector2i(7, 7), Vector2i(5, 6), Vector2i(5, 7), Vector2i(6, 6), Vector2i(6, 7)
]

@onready var map = $TileMap as TileMap


var start_pos: Vector2i
var end_pos: Vector2i

var rooms: Array = []


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if Input.is_action_just_pressed("editor_click"):
		start_pos = map.local_to_map(get_global_mouse_position())
		get_viewport().set_input_as_handled()
	if Input.is_action_just_released("editor_click"):
		end_pos = map.local_to_map(get_global_mouse_position())
		get_viewport().set_input_as_handled()
		var sector = Rect2i(
			min(start_pos.x, end_pos.x), min(start_pos.y, end_pos.y),
			absi(start_pos.x - end_pos.x) + 1, absi(start_pos.y - end_pos.y) + 1 
		)
		for x in range(sector.position.x, sector.end.x):
			for y in range(sector.position.y, sector.end.y):
				map.set_cell(Layers.GROUND, Vector2i(x, y), 0, Vector2i(21, 1), 0)
				map.set_cell(Layers.FLOOR, Vector2i(x, y), 0, Vector2i(21, 1), 0)
				map.set_cell(Layers.WALLS, Vector2i(x, y), -1)
		var pos: Vector2i
		for y in range(sector.position.y - 1, sector.end.y + 1):
			pos = Vector2i(sector.position.x - 1, y)
			if map.get_cell_source_id(Layers.FLOOR, pos) == -1:
				add_wall(pos)
			pos = Vector2i(sector.end.x, y)
			if map.get_cell_source_id(Layers.FLOOR, pos) == -1:
				add_wall(pos)
		for x in range(sector.position.x - 1, sector.end.x + 1):
			pos = Vector2i(x, sector.position.y - 1)
			if map.get_cell_source_id(Layers.FLOOR, pos) == -1:
				add_wall(pos)
			pos = Vector2i(x, sector.end.y)
			if map.get_cell_source_id(Layers.FLOOR, pos) == -1:
				add_wall(pos)

func update_wall(pos: Vector2i):
	if map.get_cell_source_id(Layers.WALLS, pos) == -1:
		return
	var mask = 0
	if map.get_cell_source_id(Layers.WALLS, pos + Vector2i(0, -1)) != -1:
		mask += 1
	if map.get_cell_source_id(Layers.WALLS, pos + Vector2i(-1, 0)) != -1:
		mask += 2
	if map.get_cell_source_id(Layers.WALLS, pos + Vector2i(1, 0)) != -1:
		mask += 4
	if map.get_cell_source_id(Layers.WALLS, pos + Vector2i(0, 1)) != -1:
		mask += 8
		var y_offset = 0 if mask == 9 else 1
		var left_floor = map.get_cell_source_id(Layers.FLOOR, pos + Vector2i(-1, y_offset)) != -1 or map.get_cell_source_id(Layers.WALLS, pos + Vector2i(-1, y_offset)) != -1
		var right_floor = map.get_cell_source_id(Layers.FLOOR, pos + Vector2i(1, y_offset)) != -1 or map.get_cell_source_id(Layers.WALLS, pos + Vector2i(1, y_offset)) != -1
		if left_floor != right_floor:
			mask += 8 if left_floor else 16 # +8
	map.set_cell(Layers.WALLS, pos, 0, wood_walls[mask], 0)

func add_wall(pos: Vector2i):
	map.set_cell(Layers.WALLS, pos, 0, wood_walls[0], 0)
	update_wall(pos + Vector2i(0, -1))
	update_wall(pos + Vector2i(-1, 0))
	update_wall(pos + Vector2i(1, 0))
	update_wall(pos + Vector2i(0, 1))
	update_wall(pos)
