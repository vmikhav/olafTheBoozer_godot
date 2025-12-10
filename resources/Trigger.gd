extends Resource
class_name Trigger

## Represents a trigger point that can activate changesets
## Triggers can be: levers, press plates, or item conversions

enum TriggerType { LEVER, PRESS_PLATE, ITEM_TRIGGER }

@export var id: String
@export var trigger_type: TriggerType
@export var position: Vector2i
@export var changesets: Array[String] = [] ## IDs of changesets to apply
@export var connected_levers: Array[String] = []

@export_category("Visual state management")
@export var layer: BaseLevel.Layer = BaseLevel.Layer.PRESS_PLATES
@export var tile_off: Vector2i = Vector2i(-1, -1)  ## Tile coords when inactive
@export var tile_mid: Vector2i = Vector2i(-1, -1)
@export var tile_on: Vector2i = Vector2i(-1, -1)   ## Tile coords when active
@export var tile_off_alt: int = 0
@export var tile_mid_alt: int = 0
@export var tile_on_alt: int = 0
@export var tile_set: int = -1

@export var is_activated: bool = false

## Add a changeset to this trigger
func add_changeset(changeset_id: String):
	if not changeset_id in changesets:
		changesets.append(changeset_id)

## Set visual appearance tiles
func set_visual_tiles(p_layer: BaseLevel.Layer, off_coords: Vector2i, on_coords: Vector2i, alt_on: int = 0, alt_off: int = 0):
	layer = p_layer
	tile_off = off_coords
	tile_on = on_coords
	tile_on_alt = alt_on
	tile_off_alt = alt_off

## Toggle lever state
func toggle_lever() -> bool:
	if trigger_type == TriggerType.LEVER:
		is_activated = not is_activated
		return true
	return false

## Activate press plate
func press() -> bool:
	if trigger_type == TriggerType.PRESS_PLATE:
		is_activated = true
		return true
	return false

## Release press plate
func release() -> bool:
	if trigger_type == TriggerType.PRESS_PLATE:
		is_activated = false
		return true
	return false



## Get state of this trigger as bool
func get_state() -> bool:
	return is_activated

## Get the visual tile coords for current state
func get_current_tile() -> Vector2i:
	if layer == -1:
		return Vector2i(-1, -1)
	
	match trigger_type:
		TriggerType.LEVER, TriggerType.PRESS_PLATE:
			return tile_on if is_activated else tile_off
	
	return tile_off

## Update visual appearance on the level
func update_visual(level: BaseLevel):
	if layer == -1 or tile_off.x == -1:
		return
	
	var current_tile = get_current_tile()
	if trigger_type == TriggerType.LEVER:
		if tile_mid.x >= 0:
			level.update_cell(position, tile_mid, tile_mid_alt, layer)
			await level.get_tree().create_timer(.05).timeout
	level.update_cell(position, current_tile, tile_on_alt if is_activated else tile_off_alt, layer)
