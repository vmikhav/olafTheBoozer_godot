extends Resource
class_name TriggersController

var defs = LevelDefinitions
var level: BaseLevel

var triggers: Dictionary = {} # String -> Trigger
var changesets: Dictionary = {} # String -> Changeset
var applied_changesets: Array[String] = [] # Track which changesets are currently applied

## Add a trigger to the controller
func add_trigger(trigger: Trigger):
	triggers[trigger.id] = trigger

## Add a changeset to the controller
func add_changeset(changeset: Changeset):
	changesets[changeset.id] = changeset

## Get a trigger by ID
func get_trigger(trigger_id: String) -> Trigger:
	return triggers.get(trigger_id)

## Get a changeset by ID
func get_changeset(changeset_id: String) -> Changeset:
	return changesets.get(changeset_id)

## Handle lever bump - toggle state and check for activation
func toggle_lever(lever_id: String) -> Array[String]:
	var trigger = triggers.get(lever_id)
	if not trigger or trigger.trigger_type != Trigger.TriggerType.LEVER:
		return []
	
	trigger.toggle_lever()
	trigger.update_visual(level)
	return evaluate_triggers()

## Handle press plate activation
func activate_press_plate(plate_id: String) -> Array[String]:
	var trigger = triggers.get(plate_id)
	if not trigger or trigger.trigger_type != Trigger.TriggerType.PRESS_PLATE:
		return []
	
	if trigger.is_pressed:
		return []  # Already pressed
	
	trigger.press()
	trigger.update_visual(level)
	return evaluate_triggers()

## Handle press plate deactivation
func deactivate_press_plate(plate_id: String) -> Array[String]:
	var trigger = triggers.get(plate_id)
	if not trigger or trigger.trigger_type != Trigger.TriggerType.PRESS_PLATE:
		return []
	
	if not trigger.is_pressed:
		return []  # Already released
	
	trigger.release()
	trigger.update_visual(level)
	return evaluate_triggers()

## Handle item trigger (when bad item converts to good)
func trigger_item_effect(item_trigger_id: String) -> Array[String]:
	var trigger = triggers.get(item_trigger_id)
	if not trigger or trigger.trigger_type != Trigger.TriggerType.ITEM_TRIGGER:
		return []
	
	return evaluate_triggers()

## Evaluate all triggers and apply/remove changesets
func evaluate_triggers() -> Array[String]:
	var activated_changesets: Array[String] = []
	
	# Check all triggers
	for trigger_id in triggers.keys():
		var trigger: Trigger = triggers[trigger_id]
		var trigger_states: Array[bool] = [trigger.get_state()]
		
		if trigger.should_activate(trigger_states):
			for changeset_id in trigger.changesets:
				if not changeset_id in activated_changesets:
					activated_changesets.append(changeset_id)
	
	# Apply new changesets and rollback removed ones
	apply_changesets(activated_changesets)
	return activated_changesets

## Apply changesets, rolling back any that are no longer needed
func apply_changesets(target_changesets: Array[String]):
	# Rollback changesets that are no longer active
	for changeset_id in applied_changesets:
		if not changeset_id in target_changesets:
			var changeset = changesets.get(changeset_id)
			if changeset and changeset.applied:
				changeset.rollback(level)
	
	# Apply new changesets
	for changeset_id in target_changesets:
		if not changeset_id in applied_changesets:
			var changeset = changesets.get(changeset_id)
			if changeset and not changeset.applied:
				changeset.apply(level)
	
	applied_changesets = target_changesets

## Reset all triggers to initial state
func reset():
	for trigger in triggers.values():
		match trigger.trigger_type:
			Trigger.TriggerType.LEVER:
				trigger.lever_state = false
			Trigger.TriggerType.PRESS_PLATE:
				trigger.is_pressed = false
		trigger.update_visual(level)
	
	# Rollback all changesets
	for changeset_id in applied_changesets:
		var changeset = changesets.get(changeset_id)
		if changeset and changeset.applied:
			changeset.rollback(level)
	
	applied_changesets.clear()

## Save state for history (returns state as Dictionary for HistoryItem)
func get_state_snapshot() -> Dictionary:
	var snapshot = {
		"lever_states": {},
		"plate_states": {},
		"applied_changesets": applied_changesets.duplicate()
	}
	
	for trigger_id in triggers.keys():
		var trigger = triggers[trigger_id]
		match trigger.trigger_type:
			Trigger.TriggerType.LEVER:
				snapshot["lever_states"][trigger_id] = trigger.lever_state
			Trigger.TriggerType.PRESS_PLATE:
				snapshot["plate_states"][trigger_id] = trigger.is_pressed
	
	return snapshot

## Restore state from snapshot (also updates visuals)
func restore_state_snapshot(snapshot: Dictionary):
	if snapshot.is_empty():
		return
	
	var target_changesets: Array[String] = []
	target_changesets.assign(snapshot.get("applied_changesets", []))
	
	# Restore trigger states and visuals
	for trigger_id in snapshot.get("lever_states", {}).keys():
		var trigger = triggers.get(trigger_id)
		if trigger:
			trigger.lever_state = snapshot["lever_states"][trigger_id]
			trigger.update_visual(level)
	
	for trigger_id in snapshot.get("plate_states", {}).keys():
		var trigger = triggers.get(trigger_id)
		if trigger:
			trigger.is_pressed = snapshot["plate_states"][trigger_id]
			trigger.update_visual(level)
	
	# Apply/rollback changesets to match target state
	apply_changesets(target_changesets)
