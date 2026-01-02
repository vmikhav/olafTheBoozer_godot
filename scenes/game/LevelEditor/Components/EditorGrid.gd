# Scripts/Editor/EditorGrid.gd
extends Node2D
class_name EditorGrid

## Grid overlay for the level editor

@export var grid_color: Color = Color(0.3, 0.3, 0.3, 0.5)
@export var grid_color_major: Color = Color(0.5, 0.5, 0.5, 0.7)
@export var major_line_interval: int = 5
@export var show_coordinates: bool = true
@export var coordinate_interval: int = 5

var tile_size: Vector2i = Vector2i(16, 16)
var tilemap: TileMapLayer
var visible_rect: Rect2i = Rect2i(-10, -10, 40, 30)

func _ready():
	set_process(true)

func _draw():
	if not visible:
		return
	
	# Use visible rect
	var rect = visible_rect.grow(2)
	
	# Draw vertical lines
	for x in range(rect.position.x, rect.end.x + 1):
		var world_x = x * tile_size.x
		var is_major = x % major_line_interval == 0
		var color = grid_color_major if is_major else grid_color
		var width = 2.0 if is_major else 1.0
		
		draw_line(
			Vector2(world_x, rect.position.y * tile_size.y),
			Vector2(world_x, rect.end.y * tile_size.y),
			color,
			width
		)
		
		# Draw coordinate labels
		if show_coordinates and is_major and x % coordinate_interval == 0:
			var font = ThemeDB.fallback_font
			var font_size = 10
			draw_string(
				font,
				Vector2(world_x + 2, rect.position.y * tile_size.y - 4),
				str(x),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				font_size,
				Color(1, 1, 1, 0.7)
			)
	
	# Draw horizontal lines
	for y in range(rect.position.y, rect.end.y + 1):
		var world_y = y * tile_size.y
		var is_major = y % major_line_interval == 0
		var color = grid_color_major if is_major else grid_color
		var width = 2.0 if is_major else 1.0
		
		draw_line(
			Vector2(rect.position.x * tile_size.x, world_y),
			Vector2(rect.end.x * tile_size.x, world_y),
			color,
			width
		)
		
		# Draw coordinate labels
		if show_coordinates and is_major and y % coordinate_interval == 0:
			var font = ThemeDB.fallback_font
			var font_size = 10
			draw_string(
				font,
				Vector2(rect.position.x * tile_size.x - 30, world_y + 12),
				str(y),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				font_size,
				Color(1, 1, 1, 0.7)
			)

func _process(_delta):
	queue_redraw()

func set_tilemap(tm: TileMapLayer):
	"""Set reference tilemap"""
	tilemap = tm
	if tm and tm.tile_set:
		tile_size = tm.tile_set.tile_size
	
	# Update visible rect from tilemap usage
	if tilemap:
		var used = tilemap.get_used_rect()
		if used.size != Vector2i.ZERO:
			visible_rect = used.grow(5)
	
	queue_redraw()

func toggle_grid(vis: bool):
	"""Toggle grid visibility"""
	visible = vis
	queue_redraw()

func toggle_coordinates(show: bool):
	"""Toggle coordinate display"""
	show_coordinates = show
	queue_redraw()

func set_visible_rect(rect: Rect2i):
	"""Set visible rect manually"""
	visible_rect = rect
	queue_redraw()
