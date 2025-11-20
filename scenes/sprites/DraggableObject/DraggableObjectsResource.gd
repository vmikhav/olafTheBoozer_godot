class_name DraggableObjectsResource
extends Resource

# Dictionary to store draggable objects by grid position
# Key: Vector2i (grid position), Value: DraggableObject instance
var objects_by_position: Dictionary = {}

func _init():
	objects_by_position = {}

# Add a draggable object to the resource
func add_object(grid_pos: Vector2i, obj: DraggableObject):
	objects_by_position[grid_pos] = obj

# Remove a draggable object from the resource
func remove_object(grid_pos: Vector2i):
	if objects_by_position.has(grid_pos):
		objects_by_position.erase(grid_pos)

# Get draggable object at specific grid position
func get_object_at(grid_pos: Vector2i) -> DraggableObject:
	if objects_by_position.has(grid_pos):
		return objects_by_position[grid_pos]
	return null

# Get atlas coordinates of object at grid position (mimicking TileMapLayer behavior)
func get_cell_atlas_coords(grid_pos: Vector2i) -> Vector2i:
	var obj = get_object_at(grid_pos)
	if obj and obj.is_active():
		return obj.item_atlas_coords
	return Vector2i(-1, -1)

# Get alternative tile of object at grid position (mimicking TileMapLayer behavior)
func get_cell_alternative_tile(grid_pos: Vector2i) -> int:
	var obj = get_object_at(grid_pos)
	if obj and obj.is_active():
		return obj.item_alt_tile
	return -1

# Check if position has an active draggable object
func has_active_object_at(grid_pos: Vector2i) -> bool:
	var obj = get_object_at(grid_pos)
	return obj != null and obj.is_active()

func has_object_at(grid_pos: Vector2i) -> bool:
	var obj = get_object_at(grid_pos)
	return obj != null

# Get all grid positions that have objects
func get_used_cells() -> Array[Vector2i]:
	var used_cells: Array[Vector2i] = []
	for pos in objects_by_position.keys():
		var obj = objects_by_position[pos]
		if obj and obj.is_active():
			used_cells.append(pos)
	return used_cells

# Get all objects (active and inactive)
func get_all_objects() -> Array[DraggableObject]:
	var all_objects: Array[DraggableObject] = []
	for obj in objects_by_position.values():
		if obj:
			all_objects.append(obj)
	return all_objects

# Get only active objects
func get_active_objects() -> Array[DraggableObject]:
	var active_objects: Array[DraggableObject] = []
	for obj in objects_by_position.values():
		if obj and obj.is_active():
			active_objects.append(obj)
	return active_objects

# Clear all objects
func clear():
	for obj in objects_by_position.values():
		if obj:
			obj.queue_free()
	objects_by_position.clear()

# Update object position in the resource (when object is moved)
func update_object_position(old_pos: Vector2i, new_pos: Vector2i):
	if objects_by_position.has(old_pos):
		var obj = objects_by_position[old_pos]
		objects_by_position.erase(old_pos)
		objects_by_position[new_pos] = obj

# Apply a method to object at specific grid position
# Returns true if object was found and method was called, false otherwise
func apply_to_object_at(grid_pos: Vector2i, method_name: String, args: Array = []) -> bool:
	var obj = get_object_at(grid_pos)
	if obj and obj.has_method(method_name):
		if args.is_empty():
			obj.call(method_name)
		else:
			obj.callv(method_name, args)
		return true
	return false

# Apply a method to all active objects
func apply_to_all_active_objects(method_name: String, args: Array = []):
	for obj in get_active_objects():
		if obj.has_method(method_name):
			if args.is_empty():
				obj.call(method_name)
			else:
				obj.callv(method_name, args)

# Apply a method to all objects (active and inactive)
func apply_to_all_objects(method_name: String, args: Array = []):
	for obj in get_all_objects():
		if obj.has_method(method_name):
			if args.is_empty():
				obj.call(method_name)
			else:
				obj.callv(method_name, args)

# Boilerplate method examples for common operations:

# Set active state for object at position
func set_object_active_at(grid_pos: Vector2i, active: bool) -> bool:
	return apply_to_object_at(grid_pos, "set_active", [active])

# Move object at position to new position
func move_object_at(grid_pos: Vector2i, new_pos: Vector2i) -> bool:
	var success = apply_to_object_at(grid_pos, "move_to_position", [new_pos])
	if success:
		update_object_position(grid_pos, new_pos)
		apply_to_object_at(new_pos, "on_player_moved")
	return success

# Update arrow visibility for object at position
func update_arrow_at(grid_pos: Vector2i) -> bool:
	return apply_to_object_at(grid_pos, "update_arrow_visibility")

# Update arrow visibility for all active objects
func update_all_arrows():
	apply_to_all_active_objects("update_arrow_visibility")

# Notify all objects that player moved
func notify_player_moved():
	apply_to_all_active_objects("on_player_moved")

# Notify all objects that tail changed
func notify_tail_changed():
	apply_to_all_active_objects("on_tail_changed")

# Set arrow hint delay for all objects
func set_arrow_delay_for_all(delay: float):
	apply_to_all_objects("set", ["arrow_hint_delay", delay])

# Debug: Print all object positions and states
func debug_print_objects():
	print("Draggable Objects Status:")
	for pos in objects_by_position.keys():
		var obj = objects_by_position[pos]
		if obj:
			print("  Position: %s, Active: %s, Atlas: %s" % [pos, obj.is_active(), obj.item_atlas_coords])
		else:
			print("  Position: %s, Object: NULL" % pos)
