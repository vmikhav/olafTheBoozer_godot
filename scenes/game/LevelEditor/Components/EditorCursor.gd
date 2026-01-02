# Scripts/Editor/EditorCursor.gd
extends Node2D
class_name EditorCursor

## Cursor preview showing tile being painted

var current_tile: TileInfo
var tile_size: Vector2i = Vector2i(16, 16)
var preview_sprite: Sprite2D
var highlight_rect: ColorRect

func _ready():
	# Create highlight rectangle
	highlight_rect = ColorRect.new()
	highlight_rect.size = Vector2(tile_size)
	highlight_rect.color = Color(1, 1, 0, 0.3)
	highlight_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(highlight_rect)
	
	# Create preview sprite
	preview_sprite = Sprite2D.new()
	preview_sprite.modulate = Color(1, 1, 1, 0.7)
	preview_sprite.centered = false
	add_child(preview_sprite)

func show_tile_preview(tile: TileInfo):
	"""Show preview of tile"""
	current_tile = tile
	
	if not tile:
		hide_preview()
		return
	
	visible = true
	highlight_rect.visible = true
	
	# TODO: Extract actual texture from atlas
	# For now just show highlight
	preview_sprite.visible = false
	
	queue_redraw()

func hide_preview():
	"""Hide tile preview"""
	visible = false
	queue_redraw()

func _draw():
	if not current_tile:
		return
	
	# Draw tile outline
	draw_rect(
		Rect2(Vector2.ZERO, Vector2(tile_size)),
		Color(1, 1, 0, 0.5),
		false,
		2.0
	)
	
	# Draw tile info
	if current_tile:
		var font = ThemeDB.fallback_font
		var font_size = 8
		draw_string(
			font,
			Vector2(0, -4),
			current_tile.display_name,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			Color(1, 1, 1, 0.9)
		)

func set_tile_size(size: Vector2i):
	"""Update tile size"""
	tile_size = size
	if highlight_rect:
		highlight_rect.size = Vector2(size)
	queue_redraw()
