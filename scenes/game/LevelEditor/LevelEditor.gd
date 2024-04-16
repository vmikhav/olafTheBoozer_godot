extends Node2D

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

enum Tools {NONE, WALLS}

@onready var camera = $TouchCamera
@onready var map = $TileMap as TileMap
@onready var editor = %Editor
@onready var wallsTileMap = %WallsTileMap as TileMap
@onready var testButton = $UiLayer/MarginContainer/VBoxContainer/MarginContainer/TabContainer/Walls/PanelContainer/MarginContainer/ScrollContainer/HBoxContainer/MarginContainer/Button as Button


var start_pos: Vector2i = Vector2i(-999, -999)
var end_pos: Vector2i = Vector2i(-999, -999)
var is_edit_pressed = false
var is_preview_shown = false

var rooms: Array[Array] = []

var Layers = LevelDefinitions.Layers

var tool: Tools = Tools.NONE
var tool_type = LevelDefinitions.Walls.WOOD

# Called when the node enters the scene tree for the first time.
func _ready():
	editor.map = map
	testButton.toggled.connect(func(_mode):
		if _mode:
			tool = Tools.WALLS
			tool_type = LevelDefinitions.Walls.WOOD
			camera.ignore_input = true
		else:
			tool = Tools.NONE
			camera.ignore_input = false
			if is_preview_shown:
				editor.undo()
				is_preview_shown = false
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _unhandled_input(event: InputEvent) -> void:
	if tool == Tools.WALLS:
		print_debug(event)
		if event is InputEventMouseMotion:
			get_viewport().set_input_as_handled()
			var _tmp_pos = map.local_to_map(get_global_mouse_position())
			if is_edit_pressed:
				if end_pos != _tmp_pos:
					end_pos = _tmp_pos
					if is_preview_shown:
						editor.undo()
					draw_room()
					is_preview_shown = true
			else:
				if start_pos != _tmp_pos:
					start_pos = _tmp_pos
					end_pos = start_pos
					if is_preview_shown:
						editor.undo()
					draw_room()
					is_preview_shown = true
		if Input.is_action_just_pressed("editor_click"):
			get_viewport().set_input_as_handled()
			is_edit_pressed = true
		if Input.is_action_just_released("editor_click"):
			end_pos = map.local_to_map(get_global_mouse_position())
			get_viewport().set_input_as_handled()
			is_edit_pressed = false
			is_preview_shown = false

func draw_room():
	var sector = Rect2i(
		min(start_pos.x, end_pos.x), min(start_pos.y, end_pos.y),
		absi(start_pos.x - end_pos.x) + 1, absi(start_pos.y - end_pos.y) + 1 
	)
	rooms.push_back([sector])
	editor.begin_transaction()
	for x in range(sector.position.x, sector.end.x):
		for y in range(sector.position.y, sector.end.y):
			editor.set_cell(Layers.GROUND, Vector2i(x, y), 0, Vector2i(21, 1), 0)
			editor.set_cell(Layers.FLOOR, Vector2i(x, y), 0, Vector2i(21, 1), 0)
			editor.set_cell(Layers.WALLS, Vector2i(x, y), -1)
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
	editor.commit()

func update_wall(pos: Vector2i):
	if map.get_cell_source_id(Layers.WALLS, pos) == -1:
		return
	var mask = 0
	if has_wall(pos + Vector2i(0, -1)):
		mask += 1
	if has_wall(pos + Vector2i(-1, 0)):
		mask += 2
	if has_wall(pos + Vector2i(1, 0)):
		mask += 4
	if has_wall(pos + Vector2i(0, 1)):
		mask += 8
		var y_offset = 0 if mask == 9 else 1
		var left_floor = map.get_cell_source_id(Layers.FLOOR, pos + Vector2i(-1, y_offset)) != -1 or has_wall(pos + Vector2i(-1, y_offset))
		var right_floor = map.get_cell_source_id(Layers.FLOOR, pos + Vector2i(1, y_offset)) != -1 or has_wall(pos + Vector2i(1, y_offset))
		if left_floor != right_floor:
			mask += 8 if left_floor else 16 # +8
		#if mask & 6:
		#	if has_wall(pos + Vector2i(1, 1)):
		#		mask &= 7
		#elif mask & 1:
		#	if mask & 4 and has_wall(pos + Vector2i(1, 1)):
		#		mask -= 4
		#	if mask & 2 and has_wall(pos + Vector2i(-1, 1)):
		#		mask -= 2
	editor.set_cell(Layers.WALLS, pos, 0, wood_walls[mask], 0)
	map.set_cell

func add_wall(pos: Vector2i):
	editor.set_cell(Layers.GROUND, pos, -1)
	editor.set_cell(Layers.FLOOR, pos, -1)
	editor.set_cell(Layers.WALLS, pos, 0, wood_walls[0], 0)
	update_wall(pos + Vector2i(0, -1))
	update_wall(pos + Vector2i(-1, 0))
	update_wall(pos + Vector2i(1, 0))
	update_wall(pos + Vector2i(0, 1))
	update_wall(pos + Vector2i(-1, -1))
	update_wall(pos + Vector2i(1, -1))
	update_wall(pos + Vector2i(-1, 1))
	update_wall(pos + Vector2i(1, 1))
	update_wall(pos)

func has_wall(coords: Vector2i) -> bool:
	return map.get_cell_source_id(Layers.WALLS, coords) != -1
