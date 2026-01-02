# Resources/TileInfo.gd
extends Resource
class_name TileInfo

## Tile information for editor palette with layer restrictions

## Identity
@export var id: String = ""
@export var display_name: String = ""
@export var category: String = ""
@export var tags: Array[String] = []
@export var description: String = ""

## Visual Properties
@export var atlas_coords: Vector2i = Vector2i.ZERO
@export var alt_tile: int = 0  # For rotations/variants

## Broken State (for breakable items/walls)
@export var has_broken_state: bool = false
@export var broken_atlas_coords: Vector2i = Vector2i.ZERO
@export var broken_alt_tile: int = 0

## Layer Restrictions - which layers this tile CAN be placed on
@export var allowed_layers: Array[BaseLevel.Layer] = []

## Hints (suggestions, not enforced)
@export var suggested_layer: BaseLevel.Layer = BaseLevel.Layer.WALLS
@export var is_blocking_hint: bool = false
@export var is_breakable_hint: bool = false
@export var is_collectible_hint: bool = false
@export var is_draggable_hint: bool = false

## Check if tile can be placed on a specific layer
func can_place_on_layer(layer: BaseLevel.Layer) -> bool:
	if allowed_layers.is_empty():
		return true  # No restrictions = can place anywhere
	return layer in allowed_layers

## Get display info
func get_broken_display() -> String:
	if has_broken_state:
		return "%s (Broken: %s, alt %d)" % [display_name, broken_atlas_coords, broken_alt_tile]
	return display_name

## Get layer restrictions display
func get_allowed_layers_display() -> String:
	if allowed_layers.is_empty():
		return "Any layer"
	
	var layer_names: Array[String] = []
	for layer in allowed_layers:
		layer_names.append(BaseLevel.Layer.keys()[layer])
	return ", ".join(layer_names)

## Create a simple tile with layer restriction
static func create_simple(
	p_id: String,
	p_name: String,
	p_category: String,
	p_atlas: Vector2i,
	p_alt: int = 0,
	p_allowed_layers: Array[BaseLevel.Layer] = []
) -> TileInfo:
	var tile = TileInfo.new()
	tile.id = p_id
	tile.display_name = p_name
	tile.category = p_category
	tile.atlas_coords = p_atlas
	tile.alt_tile = p_alt
	tile.allowed_layers = p_allowed_layers.duplicate()
	
	# Set suggested layer to first allowed layer if specified
	if not p_allowed_layers.is_empty():
		tile.suggested_layer = p_allowed_layers[0]
	
	return tile

## Create a breakable tile
static func create_breakable(
	p_id: String,
	p_name: String,
	p_category: String,
	p_atlas: Vector2i,
	p_alt: int,
	p_broken_atlas: Vector2i,
	p_broken_alt: int = 0,
	p_allowed_layers: Array[BaseLevel.Layer] = []
) -> TileInfo:
	var tile = create_simple(p_id, p_name, p_category, p_atlas, p_alt, p_allowed_layers)
	tile.has_broken_state = true
	tile.broken_atlas_coords = p_broken_atlas
	tile.broken_alt_tile = p_broken_alt
	tile.is_breakable_hint = true
	return tile

## Create rotatable tiles (4 rotations)
static func create_rotatable(
	p_id: String,
	p_name: String,
	p_category: String,
	p_atlas: Vector2i,
	rotation_count: int = 4,
	p_allowed_layers: Array[BaseLevel.Layer] = []
) -> Array[TileInfo]:
	var tiles: Array[TileInfo] = []
	for i in range(rotation_count):
		var tile = TileInfo.new()
		tile.id = "%s_rot%d" % [p_id, i]
		tile.display_name = "%s (↻%d°)" % [p_name, i * 90]
		tile.category = p_category
		tile.atlas_coords = p_atlas
		tile.alt_tile = i
		tile.allowed_layers = p_allowed_layers.duplicate()
		if not p_allowed_layers.is_empty():
			tile.suggested_layer = p_allowed_layers[0]
		tiles.append(tile)
	return tiles

## Helper to create ground tile (restricted to GROUND layer)
static func create_ground_tile(
	p_id: String,
	p_name: String,
	p_atlas: Vector2i,
	p_alt: int = 0
) -> TileInfo:
	return create_simple(
		p_id,
		p_name,
		"ground",
		p_atlas,
		p_alt,
		[BaseLevel.Layer.GROUND]
	)

## Helper to create floor tile (can go on GROUND or FLOOR)
static func create_floor_tile(
	p_id: String,
	p_name: String,
	p_atlas: Vector2i,
	p_alt: int = 0
) -> TileInfo:
	return create_simple(
		p_id,
		p_name,
		"floors",
		p_atlas,
		p_alt,
		[BaseLevel.Layer.GROUND, BaseLevel.Layer.FLOOR]
	)

## Helper to create wall tile (typically WALLS, but flexible)
static func create_wall_tile(
	p_id: String,
	p_name: String,
	p_atlas: Vector2i,
	p_alt: int = 0,
	allow_ground: bool = false  # For your compression technique
) -> TileInfo:
	var layers = [BaseLevel.Layer.WALLS]
	if allow_ground:
		layers.append(BaseLevel.Layer.GROUND)
	
	return create_simple(
		p_id,
		p_name,
		"walls",
		p_atlas,
		p_alt,
		layers
	)

## Helper to create decoration (FLOOR, TREES, or both)
static func create_decoration(
	p_id: String,
	p_name: String,
	p_atlas: Vector2i,
	p_alt: int = 0,
	foreground: bool = false
) -> TileInfo:
	var layers = [BaseLevel.Layer.FLOOR] if not foreground else [BaseLevel.Layer.TREES]
	
	return create_simple(
		p_id,
		p_name,
		"decorations",
		p_atlas,
		p_alt,
		layers
	)

## Helper to create flexible tile (like your edge tile)
static func create_flexible_tile(
	p_id: String,
	p_name: String,
	p_atlas: Vector2i,
	p_alt: int = 0
) -> TileInfo:
	# No layer restrictions - can go anywhere
	return create_simple(
		p_id,
		p_name,
		"special",
		p_atlas,
		p_alt,
		[]  # Empty = any layer
	)
