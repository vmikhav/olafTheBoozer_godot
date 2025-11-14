extends Resource
class_name Trigger

## Represents a trigger point that can activate changesets
## Triggers can be: levers, press plates, or item conversions

enum TriggerType { LEVER, PRESS_PLATE, ITEM_TRIGGER }
enum LogicMode { ALL, AT_LEAST_ONE }

var id: String
@export var trigger_type: TriggerType
var position: Vector2i
@export var logic_mode: LogicMode = LogicMode.ALL
var changesets: Array[String] = [] ## IDs of changesets to apply

# Visual state management
var layer: int = -1  ## Which layer to update visual state on
var tile_off: Vector2i = Vector2i(-1, -1)  ## Tile coords when inactive
var tile_on: Vector2i = Vector2i(-1, -1)   ## Tile coords when active
var tile_alt: int = 0  ## Alternative tile index

# Lever-specific
var lever_state: bool = false

# Press plate-specific
var is_pressed: bool = false

# Item trigger-specific (when bad item converts to good)
var target_item_coords: Vector2i = Vector2i(-1, -1)

func _init(p_id: String = "", p_type: TriggerType = TriggerType.LEVER, p_pos: Vector2i = Vector2i.ZERO):
	id = p_id
	trigger_type = p_type
	position = p_pos

## Add a changeset to this trigger
func add_changeset(changeset_id: String):
	if not changeset_id in changesets:
		changesets.append(changeset_id)

## Set visual appearance tiles
func set_visual_tiles(p_layer: int, off_coords: Vector2i, on_coords: Vector2i, alt: int = 0):
	layer = p_layer
	tile_off = off_coords
	tile_on = on_coords
	tile_alt = alt

## Toggle lever state
func toggle_lever() -> bool:
	if trigger_type == TriggerType.LEVER:
		lever_state = not lever_state
		return true
	return false

## Activate press plate
func press() -> bool:
	if trigger_type == TriggerType.PRESS_PLATE:
		is_pressed = true
		return true
	return false

## Release press plate
func release() -> bool:
	if trigger_type == TriggerType.PRESS_PLATE:
		is_pressed = false
		return true
	return false

## Check if trigger should activate based on logic mode
func should_activate(trigger_states: Array[bool]) -> bool:
	match logic_mode:
		LogicMode.ALL:
			return trigger_states.all(func(state): return state)
		LogicMode.AT_LEAST_ONE:
			return trigger_states.any(func(state): return state)
	return false

## Get state of this trigger as bool
func get_state() -> bool:
	match trigger_type:
		TriggerType.LEVER:
			return lever_state
		TriggerType.PRESS_PLATE:
			return is_pressed
		TriggerType.ITEM_TRIGGER:
			return true # Item triggers are one-time
	return false

## Get the visual tile coords for current state
func get_current_tile() -> Vector2i:
	if layer == -1:
		return Vector2i(-1, -1)
	
	match trigger_type:
		TriggerType.LEVER:
			return tile_on if lever_state else tile_off
		TriggerType.PRESS_PLATE:
			return tile_on if is_pressed else tile_off
	
	return tile_off

## Update visual appearance on the level
func update_visual(level: BaseLevel):
	if layer == -1 or tile_off.x == -1:
		return
	
	var current_tile = get_current_tile()
	level.update_cell(position, current_tile, tile_alt, layer)
