# Scripts/Editor/TriggerConfiguration.gd
extends Node
class_name TriggerConfiguration

## Manages trigger creation and configuration

signal trigger_created(trigger: Trigger)
signal trigger_modified(trigger: Trigger)
signal trigger_deleted(trigger_id: String)

var editor: LevelEditor

func _init(p_editor: LevelEditor):
	editor = p_editor

## Create a lever trigger
func create_lever(position: Vector2i, id: String = "") -> Trigger:
	if id.is_empty():
		id = generate_trigger_id("lever")
	
	var trigger = Trigger.new()
	trigger.id = id
	trigger.trigger_type = Trigger.TriggerType.LEVER
	trigger.position = position
	trigger.layer = BaseLevel.Layer.WALLS  # Levers typically on walls
	
	# Defaults for lever
	trigger.tile_off = Vector2i(-1, -1)  # Will use tile_set reference
	trigger.tile_on = Vector2i(-1, -1)
	trigger.tile_mid = Vector2i(-1, -1)
	
	return trigger

## Create a press plate trigger
func create_press_plate(position: Vector2i, id: String = "") -> Trigger:
	if id.is_empty():
		id = generate_trigger_id("plate")
	
	var trigger = Trigger.new()
	trigger.id = id
	trigger.trigger_type = Trigger.TriggerType.PRESS_PLATE
	trigger.position = position
	trigger.layer = BaseLevel.Layer.PRESS_PLATES
	
	return trigger

## Create an item trigger (target item coordinates only)
func create_item_trigger(item_coords: Vector2i, id: String = "") -> Trigger:
	if id.is_empty():
		id = generate_trigger_id("item")
	
	var trigger = Trigger.new()
	trigger.id = id
	trigger.trigger_type = Trigger.TriggerType.ITEM_TRIGGER
	trigger.position = Vector2i(-1, -1)  # Item triggers don't have position
	trigger.target_item_coords = item_coords  # This is what matters!
	
	return trigger

## Link a trigger to changesets
func link_trigger_to_changesets(trigger: Trigger, changeset_ids: Array[String]):
	"""Connect trigger to one or more changesets"""
	trigger.changesets = changeset_ids.duplicate()
	
	# Also update changesets to reference this trigger
	for cs_id in changeset_ids:
		var changeset = editor.get_changeset(cs_id)
		if changeset and trigger.id not in changeset.trigger_ids:
			changeset.trigger_ids.append(trigger.id)
	
	trigger_modified.emit(trigger)

## Link levers together
func link_levers(lever_ids: Array[String]):
	"""Connect multiple levers together (they share state)"""
	for lever_id in lever_ids:
		var trigger = editor.get_trigger(lever_id)
		if trigger and trigger.trigger_type == Trigger.TriggerType.LEVER:
			# Each lever knows about all others
			trigger.connected_levers = lever_ids.filter(func(id): return id != lever_id)
			trigger_modified.emit(trigger)

## Set trigger visual appearance
func set_trigger_visuals(
	trigger: Trigger,
	tile_set_index: int = -1,
	tile_off: Vector2i = Vector2i(-1, -1),
	tile_on: Vector2i = Vector2i(-1, -1),
	tile_mid: Vector2i = Vector2i(-1, -1),
	tile_alt: int = 0
):
	"""Configure how a trigger looks"""
	if tile_set_index >= 0:
		trigger.tile_set_index = tile_set_index
	
	if tile_off != Vector2i(-1, -1):
		trigger.tile_off = tile_off
	
	if tile_on != Vector2i(-1, -1):
		trigger.tile_on = tile_on
	
	if tile_mid != Vector2i(-1, -1):
		trigger.tile_mid = tile_mid
	
	trigger.tile_alt = tile_alt
	
	trigger_modified.emit(trigger)

## Generate unique trigger ID
func generate_trigger_id(prefix: String) -> String:
	var count = 0
	var existing_ids = editor.triggers.map(func(t): return t.id)
	
	while true:
		var candidate = "%s_%d" % [prefix, count]
		if candidate not in existing_ids:
			return candidate
		count += 1
	return ""

## Validate trigger
func validate_trigger(trigger: Trigger) -> Array[String]:
	"""Check if trigger is properly configured"""
	var errors: Array[String] = []
	
	if trigger.id.is_empty():
		errors.append("Trigger has no ID")
	
	if trigger.trigger_type == Trigger.TriggerType.ITEM_TRIGGER:
		if trigger.target_item_coords == Vector2i(-1, -1):
			errors.append("Item trigger has no target coordinates")
	else:
		if trigger.position == Vector2i(-1, -1):
			errors.append("Trigger has no position")
	
	if trigger.changesets.is_empty():
		errors.append("Trigger has no connected changesets")
	else:
		# Verify changesets exist
		for cs_id in trigger.changesets:
			if not editor.has_changeset(cs_id):
				errors.append("Referenced changeset '%s' doesn't exist" % cs_id)
	
	return errors

## Get all triggers that reference a changeset
func get_triggers_for_changeset(changeset_id: String) -> Array[Trigger]:
	var result: Array[Trigger] = []
	for trigger in editor.triggers:
		if changeset_id in trigger.changesets:
			result.append(trigger)
	return result

## Get all changesets referenced by a trigger
func get_changesets_for_trigger(trigger_id: String) -> Array[Changeset]:
	var trigger = editor.get_trigger(trigger_id)
	if not trigger:
		return []
	
	var result: Array[Changeset] = []
	for cs_id in trigger.changesets:
		var changeset = editor.get_changeset(cs_id)
		if changeset:
			result.append(changeset)
	
	return result
