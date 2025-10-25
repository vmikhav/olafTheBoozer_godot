class_name HistoryItem
extends Resource

# Basic movement data
var position: Vector2i
var direction: TileSet.CellNeighbor = -1

# Trail data
var trails: Array[Dictionary] = []  # {position: Vector2i, cell: Vector2i}
var is_trail_choice_point: bool = false

# Item collection data
var bad_item: Vector2i = Vector2i(-1, -1)
var bad_item_alt: int = -1
var good_item: Vector2i = Vector2i(-1, -1)
var good_item_alt: int = -1

# Ghost consumption data
var ghost: Unit = null
var ghost_position: Vector2i = Vector2i(-1, -1)
var ghost_type: int = -1  # LevelDefinitions.GhostType
var ghost_mode: int = -1

# Tail management
var tail_changed: bool = false

# Draggable item data
var dragged_item: Vector2i = Vector2i.MAX

# Teleportation
var teleported: bool = false


func _init(pos: Vector2i = Vector2i.ZERO, dir: TileSet.CellNeighbor = -1):
	position = pos
	direction = dir


func has_bad_item() -> bool:
	return bad_item.x != -1


func has_ghost() -> bool:
	return ghost != null


func has_dragged_item() -> bool:
	return dragged_item.x != Vector2i.MAX.x


func is_simple_step() -> bool:
	return not has_bad_item() and not has_ghost() and trails.is_empty() and not has_dragged_item()


func set_item_collection(bad_coords: Vector2i, bad_alt: int, good_coords: Vector2i, good_alt: int) -> void:
	bad_item = bad_coords
	bad_item_alt = bad_alt
	good_item = good_coords
	good_item_alt = good_alt


func set_ghost_consumption(ghost_unit: Unit, pos: Vector2i, type: int, mode: int) -> void:
	ghost = ghost_unit
	ghost_position = pos
	ghost_type = type
	ghost_mode = mode


func add_trail(trail_pos: Vector2i, cell: Vector2i) -> void:
	trails.push_back({position = trail_pos, cell = cell})
