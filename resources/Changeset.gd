extends Resource
class_name Changeset

## Represents a reversible change to the level state
## Changes are organized by layer and position for efficient undo/redo

enum LogicMode { ALL, AT_LEAST_ONE }

@export var id: String
@export var description: String
@export var cell_changes: Array[CellChangeset] = []
@export var mode: LogicMode = LogicMode.ALL
var applied: bool = false
var trigger_ids: Array[String] = []


## Apply all changes to the level
func apply(level: BaseLevel):
	for change in cell_changes:
		level.update_cell(change.position, change.new_coords, change.new_alt, change.layer)
	applied = true

## Rollback all changes
func rollback(level: BaseLevel):
	for change in cell_changes:
		level.update_cell(change.position, change.old_coords, change.old_alt, change.layer)
	applied = false

func should_activate(trigger_states: Array[bool]) -> bool:
	if mode == 0:
		return trigger_states.all(func(state): return state)
	
	return trigger_states.count(true) >= mode
