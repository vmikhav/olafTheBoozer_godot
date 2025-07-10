class_name DraggableObject
extends Node2D

const TILE_SIZE = 16
const TILE_OFFSET = Vector2i(0, 0)

@export var arrow_hint_delay: float = 0.01

@onready var tilemap: TileMapLayer = %TileMapLayer
@onready var arrow_sprite: QuestHintSprite = %Arrow
@onready var cross_sprite: QuestHintSprite = %Cross
var tween: Tween

var grid_position: Vector2i
var is_object_active: bool = false
var item_atlas_coords: Vector2i
var item_alt_tile: int
var base_level: BaseLevel
var arrow_timer: Timer

func _ready():
	# Create timer for arrow hint delay
	arrow_timer = Timer.new()
	arrow_timer.wait_time = arrow_hint_delay
	arrow_timer.one_shot = true
	arrow_timer.timeout.connect(_on_arrow_timer_timeout)
	add_child(arrow_timer)
	
	cross_sprite.set_icon(34)
	cross_sprite.set_animation("half")
	arrow_sprite.set_animation("half")

func initialize(pos: Vector2i, atlas_coords: Vector2i, alt_tile: int, level: BaseLevel):
	grid_position = pos
	item_atlas_coords = atlas_coords
	item_alt_tile = alt_tile
	base_level = level
	
	# Set up tilemap properties (copy from base level tilemaps)
	if base_level.tilemaps.size() > 0:
		tilemap.tile_set = base_level.tilemaps[0].tile_set
	
	# Position the object
	position = Vector2(grid_position) * TILE_SIZE + Vector2(TILE_OFFSET)
	
	# Set up the tilemap with the item
	tilemap.set_cell(Vector2i.ZERO, 0, item_atlas_coords, item_alt_tile)

func set_active(active: bool):
	is_object_active = active
	tilemap.visible = active
	
	if not active:
		hide_arrow_and_cross()
		if arrow_timer:
			arrow_timer.stop()

func move_to_position(new_grid_pos: Vector2i):
	grid_position = new_grid_pos
	var target_position = Vector2(grid_position) * TILE_SIZE + Vector2(TILE_OFFSET)
	
	# Stop existing tween if running
	if tween:
		tween.kill()
	
	# Create new tween
	tween = create_tween()
	tween.tween_property(self, "position", target_position, 0.12)

func get_grid_position() -> Vector2i:
	return grid_position

func is_active() -> bool:
	return is_object_active

func set_item_data(atlas_coords: Vector2i, alt_tile: int):
	item_atlas_coords = atlas_coords
	item_alt_tile = alt_tile
	if tilemap:
		tilemap.set_cell(Vector2i.ZERO, 0, item_atlas_coords, item_alt_tile)

func update_arrow_visibility():
	if not is_object_active or not base_level:
		hide_arrow_and_cross()
		return
	
	# Check if player is adjacent
	var player_pos = base_level.hero_position
	var distance = abs(player_pos.x - grid_position.x) + abs(player_pos.y - grid_position.y)
	var pull_direction = get_pull_direction()
	
	if distance != 1 or not base_level.can_move_in_direction(player_pos, pull_direction):
		hide_arrow_and_cross()
		return
	
	# Check if player can pull (no tail and cell is empty)
	var can_pull = (base_level.last_active_tail_item == -1 and 
					base_level.is_empty_cell(BaseLevel.Layer.ITEMS, base_level.hero_position))
	
	if can_pull:
		# Show arrow after delay
		if arrow_hint_delay > 0:
			arrow_timer.start()
		else:
			show_arrow()
	else:
		# Show cross (player has tail)
		if base_level.last_active_tail_item > -1:
			show_cross()
		else:
			hide_arrow_and_cross()

func _on_arrow_timer_timeout():
	show_arrow()

func show_arrow():
	if not is_object_active:
		return
	
	# Calculate direction from object to player
	var direction = get_pull_direction()
	set_arrow_direction(direction)
	
	arrow_sprite.visible = true
	cross_sprite.visible = false

func show_cross():
	if not is_object_active:
		return
	
	# Show cross over arrow
	show_arrow()  # First show arrow
	cross_sprite.visible = true

func hide_arrow_and_cross():
	arrow_sprite.visible = false
	cross_sprite.visible = false
	if arrow_timer:
		arrow_timer.stop()

func set_arrow_direction(direction: TileSet.CellNeighbor):
	# You'll need to implement this based on your arrow atlas
	# This is a placeholder - replace with actual atlas coordinates
	match direction:
		TileSet.CELL_NEIGHBOR_RIGHT_SIDE:
			arrow_sprite.set_icon(31)
		TileSet.CELL_NEIGHBOR_LEFT_SIDE:
			arrow_sprite.set_icon(30)
		TileSet.CELL_NEIGHBOR_TOP_SIDE:
			arrow_sprite.set_icon(32)
		TileSet.CELL_NEIGHBOR_BOTTOM_SIDE:
			arrow_sprite.set_icon(33)

# Call this method when player moves to update arrow visibility
func on_player_moved():
	update_arrow_visibility()

# Call this method when player's tail state changes
func on_tail_changed():
	update_arrow_visibility()

func get_pull_direction() -> TileSet.CellNeighbor:
	# Calculate direction from object to player (this is the pull direction)
	var player_pos = base_level.hero_position
	var direction = player_pos - grid_position
	
	if direction.x > 0:
		return TileSet.CELL_NEIGHBOR_RIGHT_SIDE
	elif direction.x < 0:
		return TileSet.CELL_NEIGHBOR_LEFT_SIDE
	elif direction.y > 0:
		return TileSet.CELL_NEIGHBOR_BOTTOM_SIDE
	elif direction.y < 0:
		return TileSet.CELL_NEIGHBOR_TOP_SIDE
	
	return TileSet.CELL_NEIGHBOR_RIGHT_SIDE  # Default fallback
