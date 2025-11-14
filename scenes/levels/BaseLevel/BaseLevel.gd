class_name BaseLevel
extends Node2D

const TILE_SIZE = 16
const TILE_OFFSET = Vector2i(8, 18)

enum Layer {
	GROUND, FLOOR, PRESS_PLATES, LIQUIDS, WALLS, TRAILS, ITEMS, TREES, BAD_ITEMS, GOOD_ITEMS, MOVABLE_ITEMS
}

var defs = LevelDefinitions

var splash_scene: PackedScene = preload("res://scenes/sprites/Splash/Splash.tscn")
var puff_scene: PackedScene = preload("res://scenes/sprites/Puff/Puff.tscn")
var draggable_scene: PackedScene = preload("res://scenes/sprites/DraggableObject/DraggableObject.tscn")
var puff_displayed := false

# parameters from an implemented scene
var music_key: String = "olaf_gameplay"
var tilemaps: Array[TileMapLayer]
var hero: Unit
var hero_play_type: Array = ["worker", true]
var hero_replay_type: Array = ["worker", true]
var hero_start_position: Vector2i
var ghosts = []
var teleports = []
var camera_limit := Rect2i(-1000000, -1000000, 2000000, 2000000)
var level_type : LevelDefinitions.LevelType = LevelDefinitions.LevelType.BACKWARD
var next_scene = ["res://scenes/game/Playground/Playground.tscn", {levels = ["Tutorial0"]}]

# local variables
var hero_position: Vector2i
var allow_input: bool
var level_items_count: int
var level_items_progress: int
var ghosts_count: int
var ghosts_progress: int
var draggable_objects: DraggableObjectsResource = DraggableObjectsResource.new()
var trails_controller: TrailsController = TrailsController.new()
var slippery_controller: SlipperyController = SlipperyController.new()
var triggers_controller: TriggersController = TriggersController.new()
var tail = []
var last_active_tail_item = -1
var lever_positions: Dictionary = {} # Vector2i -> String (lever_id)
var press_plate_positions: Dictionary = {} # Vector2i -> String (plate_id)
var item_trigger_positions: Dictionary = {} # Vector2i -> String (item_id)
var history: Array[HistoryItem] = []
var is_history_replay: bool = false
var progress_report: LevelProgressReport
var has_replay: bool

signal items_progress_signal(items_count: int)
signal ghosts_progress_signal(ghosts_count: int)
signal level_finished


func init_map(source: Layer = Layer.BAD_ITEMS):
	has_replay = level_type == LevelDefinitions.LevelType.BACKWARD
	trails_controller.trails_layer = tilemaps[Layer.TRAILS]
	trails_controller.hints_layer = tilemaps[Layer.ITEMS]
	trails_controller.level = self
	slippery_controller.level = self
	triggers_controller.level = self
	tilemaps[Layer.ITEMS].clear()
	tilemaps[Layer.BAD_ITEMS].enabled = false
	tilemaps[Layer.GOOD_ITEMS].enabled = false
	var bad_items = tilemaps[source].get_used_cells()
	if source == Layer.BAD_ITEMS:
		allow_input = true
		is_history_replay = false
		hero.set_mode(hero_play_type)
		history = [HistoryItem.new(hero_position)]
		level_items_progress = 0
		level_items_count = 0
		for item in bad_items:
			if (tilemaps[Layer.BAD_ITEMS].get_cell_atlas_coords(item) != tilemaps[Layer.GOOD_ITEMS].get_cell_atlas_coords(item)):
				level_items_count += 1
		ghosts_progress = 0
		ghosts_count = ghosts.size() + tilemaps[Layer.MOVABLE_ITEMS].get_used_cells().size()
		init_progress_report()
		init_draggable_objects()
		init_triggers()
		for item in tail:
			item.unit.queue_free()
		last_active_tail_item = -1
		tail = []
		for i in ghosts.size():
			if "unit" in ghosts[i] and ghosts[i].unit:
				ghosts[i].unit.queue_free()
			ghosts[i].unit = hero.duplicate()
			tilemaps[Layer.ITEMS].add_child(ghosts[i].unit)
			ghosts[i].unit.sprite.material = ghosts[i].unit.sprite.material.duplicate()
			ghosts[i].unit.set_mode([defs.UnitTypeName[ghosts[i].mode], false])
			ghosts[i].unit.make_ghost(ghosts[i].type)
			move_unit_to_position(ghosts[i].unit, ghosts[i].position)
	for pos in bad_items:
		update_cell(pos, tilemaps[source].get_cell_atlas_coords(pos), tilemaps[source].get_cell_alternative_tile(pos))
	AudioController.play_music(music_key)

func init_draggable_objects():
	if draggable_objects:
		draggable_objects.clear()
	else:
		draggable_objects = DraggableObjectsResource.new()
	
	var good_items = tilemaps[Layer.GOOD_ITEMS].get_used_cells()
	for pos in good_items:
		var good_coords = tilemaps[Layer.GOOD_ITEMS].get_cell_atlas_coords(pos)
		var good_alt = tilemaps[Layer.GOOD_ITEMS].get_cell_alternative_tile(pos)
		var cell_value = str(good_coords.x) + "," + str(good_coords.y)
		
		if defs.DraggableItems.has(cell_value):
			var draggable_obj = draggable_scene.instantiate()
			tilemaps[Layer.ITEMS].add_child(draggable_obj)
			draggable_obj.initialize(pos, good_coords, good_alt, self)
			
			var bad_coords = tilemaps[Layer.BAD_ITEMS].get_cell_atlas_coords(pos)
			var is_broken = bad_coords != good_coords
			draggable_obj.set_active(not is_broken)
			
			draggable_objects.add_object(pos, draggable_obj)

func init_triggers():
	lever_positions.clear()
	press_plate_positions.clear()
	item_trigger_positions.clear()
	
	# Load levers
	for lever_data in get_level_levers():
		var trigger = Trigger.new(lever_data.id, Trigger.TriggerType.LEVER, lever_data.position)
		
		# Set visual tiles - either from tile_set or custom tiles
		if lever_data.has("tile_set"):
			var tile_set = defs.Levers[lever_data.tile_set]
			if tile_set:
				trigger.set_visual_tiles(
					Layer.WALLS,
					tile_set.off,
					tile_set.on,
					tile_set.get("alt", 0)
				)
		elif lever_data.has("tile_off") and lever_data.has("tile_on"):
			trigger.set_visual_tiles(
				Layer.WALLS,
				lever_data.tile_off,
				lever_data.tile_on,
				lever_data.get("alt", 0)
			)
		
		if lever_data.has("pressed") and lever_data.pressed:
			trigger.toggle_lever()
		
		for changeset_id in lever_data.get("changesets", []):
			trigger.add_changeset(changeset_id)
		triggers_controller.add_trigger(trigger)
		lever_positions[lever_data.position] = trigger.id
		
		# Set initial visual state
		trigger.update_visual(self)
	
	# Load press plates
	for plate_data in get_level_press_plates():
		var trigger = Trigger.new(plate_data.id, Trigger.TriggerType.PRESS_PLATE, plate_data.position)
		
		# Set visual tiles - either from tile_set or custom tiles
		if plate_data.has("tile_set"):
			var tile_set = defs.PressPlates[plate_data.tile_set]
			if tile_set:
				trigger.set_visual_tiles(
					Layer.PRESS_PLATES,
					tile_set.off,
					tile_set.on,
					tile_set.get("alt", 0)
				)
		elif plate_data.has("tile_off") and plate_data.has("tile_on"):
			trigger.set_visual_tiles(
				Layer.PRESS_PLATES,
				plate_data.tile_off,
				plate_data.tile_on,
				plate_data.get("alt", 0)
			)
		
		if plate_data.has("pressed") and plate_data.pressed:
			trigger.press()
		
		for changeset_id in plate_data.get("changesets", []):
			trigger.add_changeset(changeset_id)
		triggers_controller.add_trigger(trigger)
		press_plate_positions[plate_data.position] = trigger.id
		
		# Set initial visual state
		trigger.update_visual(self)
	
	for item_data in get_level_item_trigers():
		var trigger = Trigger.new(item_data.id, Trigger.TriggerType.ITEM_TRIGGER, item_data.position)
		
		for changeset_id in item_data.get("changesets", []):
			trigger.add_changeset(changeset_id)
		triggers_controller.add_trigger(trigger)
		item_trigger_positions[item_data.position] = trigger.id
	
	# Load changesets
	for cs_data in get_level_changesets():
		var changeset = Changeset.new(cs_data.id, cs_data.get("description", ""))
		for change in cs_data.get("changes", []):
			if change.old_coords == null:
				change.old_coords = tilemaps[change.layer].get_cell_atlas_coords(change.position)
			if change.new_coords == null:
				change.new_coords = tilemaps[change.layer].get_cell_atlas_coords(change.position)
			changeset.add_cell_change(
				change.position,
				change.layer,
				change.old_coords,
				change.new_coords,
				change.get("old_alt", 0),
				change.get("new_alt", 0)
			)
		triggers_controller.add_changeset(changeset)

func get_level_levers() -> Array:
	return []

func get_level_press_plates() -> Array:
	return []

func get_level_item_trigers() -> Array:
	return []

func get_level_changesets() -> Array:
	return []

func restart():
	is_history_replay = false
	allow_input = true
	init_progress_report()
	while history.size() > 1:
		step_back()
	hero.set_mode(hero_play_type)
	ghosts_progress_signal.emit(ghosts_progress)
	items_progress_signal.emit(level_items_progress)
	AudioController.play_music(music_key)

func move_unit_to_position(unit: Unit, new_position: Vector2i):
	unit.move(new_position * TILE_SIZE + TILE_OFFSET)

func move_oriented_unit_to_position(unit: Unit, new_position: Vector2i, animation: String = "walk"):
	var new_absolute_position := new_position * TILE_SIZE + TILE_OFFSET
	if new_absolute_position.x > unit.position.x:
		unit.set_orientation('right')
	if new_absolute_position.x < unit.position.x:
		unit.set_orientation('left')
	unit.move(new_absolute_position, animation)

func move_hero_to_position(new_position: Vector2i, history_item: HistoryItem = null):
	hero_position = new_position
	move_oriented_unit_to_position(hero, new_position, "slide" if history_item and history_item.has_slide() else "walk")
	draggable_objects.notify_player_moved()

func is_empty_cell(layer: Layer, cell_position: Vector2i) -> bool:
	var atlas_pos = tilemaps[layer].get_cell_atlas_coords(cell_position)
	return atlas_pos.x == -1

func skip_step():
	hero.hit()
	AudioController.play_sfx("bump")

func update_cell(pos: Vector2i, new_value: Vector2i, alternative: int, layer: Layer = Layer.ITEMS):
	if new_value.x == -1:
		tilemaps[layer].erase_cell(pos)
	else:
		tilemaps[layer].set_cell(pos, 0, new_value, alternative)

func navigate(direction: TileSet.CellNeighbor, skip_check = false):
	if not allow_input and not skip_check:
		return

	if direction == TileSet.CELL_NEIGHBOR_RIGHT_SIDE:
		hero.set_orientation('right')
	if direction == TileSet.CELL_NEIGHBOR_LEFT_SIDE:
		hero.set_orientation('left')

	var neighbor_pos = tilemaps[Layer.ITEMS].get_neighbor_cell(hero_position, direction)
	var history_item = HistoryItem.new(neighbor_pos, direction)
	
	if neighbor_pos in lever_positions:
		handle_lever_bump(neighbor_pos)
		return
	
	# Handle trail choice mode
	if trails_controller.waiting_for_trail_choice:
		if direction in trails_controller.available_trail_directions:
			history_item.is_trail_choice_point = true
			trails_controller.clear_trail_choices()
		elif not skip_check:
			skip_step()
			return
	
	var slippery_result = slippery_controller.move_on_slippery(hero_position, direction, last_active_tail_item >= 0)
	if slippery_result.slid:
		# Record slide in history for undo
		history_item.slid = true
		history_item.slide_path = slippery_result.positions_traversed
		neighbor_pos = slippery_result.final_position
		history_item.position = neighbor_pos
	elif not slippery_result.can_move:
		skip_step()
		return

	var can_move_result = can_move_to(neighbor_pos, history_item)
	if not can_move_result.can_move:
		return
	
	neighbor_pos = can_move_result.new_position

	if not trails_controller.process_trails(neighbor_pos, history_item):
		return
	
	var draggable_item = check_for_draggable_item(direction)
	if draggable_item != Vector2i.MAX:
		move_draggable_item(draggable_item, direction)
		history_item.dragged_item = draggable_item

	process_item_collection(neighbor_pos, history_item)
	update_tail(history_item)
	process_ghosts(neighbor_pos, history_item)

	move_hero_to_position(neighbor_pos, history_item)
	
	history_item.trigger_state = triggers_controller.get_state_snapshot()
	check_press_plates(neighbor_pos, history_item)
	
	save_history_item(history_item)
	play_sfx_by_history(history_item)

	check_level_completion()

func handle_lever_bump(lever_pos: Vector2i):
	var lever_id = lever_positions[lever_pos]
	triggers_controller.toggle_lever(lever_id)
	hero.hit()
	AudioController.play_sfx("lever")

func check_press_plates(pos: Vector2i, history_item: HistoryItem):
	if pos in press_plate_positions:
		var plate_id = press_plate_positions[pos]
		triggers_controller.activate_press_plate(plate_id)
		# Update trigger state after activation
		history_item.trigger_state = triggers_controller.get_state_snapshot()

func check_press_plate_deactivation(pos: Vector2i):
	if pos in press_plate_positions:
		var plate_id = press_plate_positions[pos]
		triggers_controller.deactivate_press_plate(plate_id)

func can_move_to(neighbor_pos: Vector2i, history_item: HistoryItem) -> Dictionary:
	if is_empty_cell(Layer.GROUND, neighbor_pos):
		skip_step()
		return {can_move = false, new_position = neighbor_pos}

	if not is_empty_cell(Layer.WALLS, neighbor_pos):
		return handle_teleport(neighbor_pos, history_item)

	if is_tail_blocking(neighbor_pos) or has_draggable_object_at(neighbor_pos):
		skip_step()
		return {can_move = false, new_position = neighbor_pos}
	
	if has_blocking_item_at(neighbor_pos):
		skip_step()
		return {can_move = false, new_position = neighbor_pos}

	return {can_move = true, new_position = neighbor_pos}

func can_move_in_direction(start_pos: Vector2i, direction: TileSet.CellNeighbor) -> bool:
	var target_pos = tilemaps[Layer.ITEMS].get_neighbor_cell(start_pos, direction)
	
	if is_empty_cell(Layer.GROUND, target_pos):
		return false
	
	if not is_empty_cell(Layer.WALLS, target_pos):
		for teleport in teleports:
			if teleport.start == target_pos:
				target_pos = teleport.end
		return false
	
	if is_tail_blocking(target_pos):
		return false
	
	if has_draggable_object_at(target_pos):
		return false
	
	if has_blocking_item_at(target_pos):
		return false
	
	var trail_cell = tilemaps[Layer.TRAILS].get_cell_atlas_coords(target_pos)
	if trail_cell.x != -1:
		if not trails_controller.check_trail(target_pos, direction):
			return false
	
	return true

func has_blocking_item_at(pos: Vector2i) -> bool:
	var neighbor_cell = tilemaps[Layer.ITEMS].get_cell_atlas_coords(pos)
	var bad_neighbor_cell = tilemaps[Layer.BAD_ITEMS].get_cell_atlas_coords(pos)
	var good_neighbor_cell = tilemaps[Layer.GOOD_ITEMS].get_cell_atlas_coords(pos)
	var immutable = bad_neighbor_cell == good_neighbor_cell
	
	return neighbor_cell.x != -1 and (immutable or neighbor_cell != bad_neighbor_cell)

func has_broken_item_at(pos: Vector2i) -> bool:
	var neighbor_cell = tilemaps[Layer.ITEMS].get_cell_atlas_coords(pos)
	var bad_neighbor_cell = tilemaps[Layer.BAD_ITEMS].get_cell_atlas_coords(pos)
	var good_neighbor_cell = tilemaps[Layer.GOOD_ITEMS].get_cell_atlas_coords(pos)
	var immutable = bad_neighbor_cell == good_neighbor_cell
	
	return neighbor_cell.x != -1 and not immutable and neighbor_cell == bad_neighbor_cell

func handle_teleport(neighbor_pos: Vector2i, history_item: HistoryItem) -> Dictionary:
	for teleport in teleports:
		if teleport.start == neighbor_pos:
			process_teleport(teleport, history_item)
			return {can_move = true, new_position = teleport.end}

	skip_step()
	return {can_move = false, new_position = neighbor_pos}

func process_teleport(teleport, history_item: HistoryItem):
	if not is_empty_cell(Layer.TRAILS, teleport.start):
		allow_input = true
		history_item.add_trail(
			teleport.start,
			tilemaps[Layer.TRAILS].get_cell_atlas_coords(teleport.start)
		)
	history_item.teleported = true
	history_item.position = teleport.end

func is_tail_blocking(neighbor_pos: Vector2i) -> bool:
	return tail.any(func(item): return item.position == neighbor_pos)

func process_item_collection(neighbor_pos: Vector2i, history_item: HistoryItem):
	var neighbor_cell = tilemaps[Layer.ITEMS].get_cell_atlas_coords(neighbor_pos)
	var bad_neighbor_cell = tilemaps[Layer.BAD_ITEMS].get_cell_atlas_coords(neighbor_pos)
	var bad_neighbor_alt = tilemaps[Layer.BAD_ITEMS].get_cell_alternative_tile(neighbor_pos)
	var good_neighbor_cell = tilemaps[Layer.GOOD_ITEMS].get_cell_atlas_coords(neighbor_pos)
	var good_neighbor_alt = tilemaps[Layer.GOOD_ITEMS].get_cell_alternative_tile(neighbor_pos)
	var immutable = bad_neighbor_cell == good_neighbor_cell

	if neighbor_cell.x != -1 and (not immutable) and neighbor_cell == bad_neighbor_cell:
		update_cell(neighbor_pos, good_neighbor_cell, good_neighbor_alt)
		history_item.set_item_collection(bad_neighbor_cell, bad_neighbor_alt, good_neighbor_cell, good_neighbor_alt)
		level_items_progress += 1
		draggable_objects.set_object_active_at(neighbor_pos, true)
		display_puff(neighbor_pos)
		items_progress_signal.emit(level_items_progress)
		
		if neighbor_pos in item_trigger_positions:
			triggers_controller.trigger_item_effect(item_trigger_positions[neighbor_pos])
			# Update trigger state after item trigger
			history_item.trigger_state = triggers_controller.get_state_snapshot()

func is_trigger_item(cell_coords: Vector2i) -> bool:
	var cell_value = str(cell_coords.x) + "," + str(cell_coords.y)
	return defs.TriggerItems.has(cell_value)

func update_tail(history_item: HistoryItem):
	if should_add_bot_to_tail():
		add_bot_to_tail(history_item)

	for item in tail:
		if item.movement_mode == "follow":
			update_tail_item_position(item)
	draggable_objects.notify_tail_changed()
	
	if history_item.tail_changed and tail.size() > 0:
		var removed_item_pos = tail[0].position
		check_press_plate_deactivation(removed_item_pos)

func should_add_bot_to_tail() -> bool:
	return history.size() and history[-1].has_ghost() and history[-1].ghost_type == defs.GhostType.ENEMY

func add_bot_to_tail(history_item: HistoryItem):
	var last_history = history[-1]
	var unit = hero.duplicate()
	tilemaps[Layer.ITEMS].add_child(unit)
	unit.sprite.material = unit.sprite.material.duplicate()
	unit.set_mode([defs.UnitTypeName[last_history.ghost_mode], false])
	move_unit_to_position(unit, last_history.position)
	unit.make_follower()
	tail.push_front({
		unit = unit,
		unit_mode = last_history.ghost_mode,
		position = last_history.position,
		history_position = history.size() - 1,
		movement_mode = "follow",
	})
	last_active_tail_item += 1
	history_item.tail_changed = true
	for item in tail:
		if item.movement_mode == "follow":
			item.history_position -= 1

func update_tail_item_position(item):
	item.history_position += 1
	item.position = history[item.history_position].position
	move_oriented_unit_to_position(item.unit, item.position)

func process_ghosts(neighbor_pos: Vector2i, history_item: HistoryItem):
	for i in ghosts.size():
		if can_consume_ghost(i, neighbor_pos):
			consume_ghost(i, history_item)
			display_splash(neighbor_pos)
			break

func can_consume_ghost(ghost_index: int, neighbor_pos: Vector2i) -> bool:
	var ghost = ghosts[ghost_index]
	if ghost.type == defs.GhostType.ENEMY_SPAWN:
		return can_consume_enemy_spawn_ghost(ghost)
	return neighbor_pos == ghost.position

func can_consume_enemy_spawn_ghost(ghost) -> bool:
	if last_active_tail_item >= 0:
		var item = tail[last_active_tail_item]
		return (item.movement_mode == "follow"
			and item.unit_mode == ghost.mode
			and item.position == ghost.position)
	return false

func consume_ghost(ghost_index: int, history_item: HistoryItem):
	var ghost = ghosts[ghost_index]
	ghosts_progress += 1
	ghosts_progress_signal.emit(ghosts_progress)
	ghost.unit.visible = false
	history_item.set_ghost_consumption(ghost.unit, ghost.position, ghost.type, ghost.mode)

	if ghost.type == defs.GhostType.ENEMY_SPAWN:
		var item = tail[last_active_tail_item]
		item.movement_mode = "chill"
		last_active_tail_item -= 1

	ghosts.remove_at(ghost_index)

func check_level_completion():
	if ghosts_progress == ghosts_count:
		finish_level()

func finish_level():
	allow_input = false
	level_finished.emit()
	get_tree().create_timer(0.5).timeout.connect(func():
		AudioController.play_sfx("dropdown_menu")
		if has_replay:
			hero.set_mode(hero_replay_type)
	)

func step_back(manual: bool = false):
	if history.size() <= 1:
		is_history_replay = false
		return
	
	if manual and not allow_input:
		return

	var history_item = history.pop_back()
	var previous_position = history[-1].position

	if is_history_replay or manual:
		play_sfx_by_history(history_item)

	move_hero_to_position(previous_position, history_item)
	
	if history_item.has_trigger_state():
		triggers_controller.restore_state_snapshot(history[-1].trigger_state)
	
	trails_controller.handle_trails_reversal(history_item, history[-1], hero_position, manual)
	handle_item_reversal(history_item)
	handle_ghost_reversal(history_item)
	handle_tail_reversal(history_item)
	handle_dragged_item_reversal(history_item)

	if not is_history_replay:
		update_progress_signals()

func schedule_next_step(direction: TileSet.CellNeighbor, time: float = 0.1):
	allow_input = false
	var timer = get_tree().create_timer(time)
	timer.timeout.connect(func():
		allow_input = true
		navigate(direction)
	)

func schedule_next_step_back(manual: bool):
	allow_input = false
	var timer = get_tree().create_timer(0.1 + randf_range(0, 0.075))
	timer.timeout.connect(func():
		allow_input = true
		step_back(manual)
	)

func handle_item_reversal(history_item: HistoryItem):
	if history_item.has_bad_item():
		update_cell(history_item.position, history_item.bad_item, history_item.bad_item_alt)
		level_items_progress -= 1
		draggable_objects.set_object_active_at(history_item.position, false)

func handle_ghost_reversal(history_item: HistoryItem):
	if history_item.has_ghost():
		restore_ghost(history_item)
		ghosts_progress -= 1

func restore_ghost(history_item: HistoryItem):
	if history_item.ghost_type == defs.GhostType.ENEMY_SPAWN:
		restore_enemy_spawn_ghost(history_item)
	
	history_item.ghost.make_ghost(history_item.ghost_type)
	history_item.ghost.visible = true
	ghosts.push_back({
		position = history_item.ghost_position,
		type = history_item.ghost_type,
		mode = history_item.ghost_mode,
		unit = history_item.ghost,
	})

func restore_enemy_spawn_ghost(history_item: HistoryItem):
	for item in tail:
		if item.position == history_item.ghost_position:
			item.movement_mode = "follow"
			last_active_tail_item += 1
			break

func handle_tail_reversal(history_item: HistoryItem):
	if history_item.tail_changed:
		remove_tail_item()
	else:
		update_tail_positions()

func remove_tail_item():
	tail.pop_front().unit.die(is_history_replay)
	last_active_tail_item -= 1

func update_tail_positions():
	for item in tail:
		if item.movement_mode == "follow":
			item.history_position -= 1
			item.position = history[item.history_position].position
			move_oriented_unit_to_position(item.unit, item.position)

func update_progress_signals():
	ghosts_progress_signal.emit(ghosts_progress)
	items_progress_signal.emit(level_items_progress)

func replay():
	if !has_replay:
		return
	allow_input = false
	is_history_replay = true
	step_back()
	while is_history_replay and history.size() > 1:
		await get_tree().create_timer(0.15 + randf_range(0, 0.075)).timeout
		if is_history_replay:
			step_back()

func play_sfx_by_history(history_item: HistoryItem):
	if history_item.has_ghost():
		AudioController.play_sfx("pickup")
		return
	if history_item.has_bad_item():
		AudioController.play_sfx_by_tiles(history_item.bad_item, history_item.good_item)
		return
	if history_item.trails.size():
		AudioController.play_sfx_by_tiles(history_item.trails[0].cell)
		return
	if history_item.has_dragged_item():
		AudioController.play_sfx("barrel_roll")
		return
	if history_item.has_slide():
		AudioController.play_sfx("slide")
		return
	AudioController.play_sfx("step")

func save_history_item(item: HistoryItem):
	var size = history.size()
	if item.is_simple_step() and size >= 2:
		if history[size-1].is_simple_step() and history[size-2].position == item.position:
			history.pop_back()
			return
	history.push_back(item)

func is_draggable_item(cell_coords: Vector2i) -> bool:
	var cell_value = str(cell_coords.x) + "," + str(cell_coords.y)
	return defs.DraggableItems.has(cell_value)

func check_for_draggable_item(direction: TileSet.CellNeighbor) -> Vector2i:
	if (not tail.is_empty() and last_active_tail_item > -1) or not is_empty_cell(Layer.ITEMS, hero_position):
		return Vector2i.MAX

	var opposite_direction = defs.get_opposite_direction(direction)
	var item_pos = tilemaps[Layer.ITEMS].get_neighbor_cell(hero_position, opposite_direction)
	
	if has_draggable_object_at(item_pos):
		return item_pos
	return Vector2i.MAX

func move_draggable_item(item_pos: Vector2i, direction: TileSet.CellNeighbor):
	var item_coords = get_draggable_object_atlas_coords(item_pos)
	var new_pos = tilemaps[Layer.ITEMS].get_neighbor_cell(item_pos, direction)
	
	var old_movable = tilemaps[Layer.MOVABLE_ITEMS].get_cell_atlas_coords(item_pos)
	var new_movable = tilemaps[Layer.MOVABLE_ITEMS].get_cell_atlas_coords(new_pos)
	
	if old_movable == item_coords:
		ghosts_progress -= 1
	if new_movable == item_coords:
		ghosts_progress += 1
		display_splash(new_pos)
	ghosts_progress_signal.emit(ghosts_progress)

	update_cell(item_pos, Vector2i(-1, -1), 0, Layer.ITEMS)
	draggable_objects.move_object_at(item_pos, new_pos)

func handle_dragged_item_reversal(history_item: HistoryItem):
	if history_item.has_dragged_item():
		var item_pos = history_item.dragged_item
		var new_pos = tilemaps[Layer.ITEMS].get_neighbor_cell(item_pos, history_item.direction)
		var item_coords = get_draggable_object_atlas_coords(new_pos)
		
		var old_movable = tilemaps[Layer.MOVABLE_ITEMS].get_cell_atlas_coords(item_pos)
		var new_movable = tilemaps[Layer.MOVABLE_ITEMS].get_cell_atlas_coords(new_pos)
		
		if old_movable == item_coords:
			ghosts_progress += 1
		if new_movable == item_coords:
			ghosts_progress -= 1
		ghosts_progress_signal.emit(ghosts_progress)
		
		draggable_objects.move_object_at(new_pos, item_pos)

func init_progress_report():
	progress_report = LevelProgressReport.new()
	progress_report.total_items = level_items_count
	progress_report.total_ghosts = ghosts_count

func fill_progress_report() -> LevelProgressReport:
	progress_report.mark_as_filled(history)
	progress_report.progress_items = level_items_progress
	progress_report.progress_ghosts = ghosts_progress
	progress_report.finished = ghosts_progress == ghosts_count
	progress_report.score = calc_score()
	return progress_report

func calc_score() -> int:
	return ceili((
			(progress_report.progress_items + progress_report.progress_ghosts) * 1.0
			/ (progress_report.total_items + progress_report.total_ghosts)
		) * 100)

func display_splash(tile_pos: Vector2) -> void:
	var splash = splash_scene.instantiate() as Node2D
	add_child(splash)
	splash.z_index = 50
	splash.position = (tile_pos + Vector2(0.5, 0.5)) * TILE_SIZE

func display_puff(tile_pos: Vector2) -> void:
	if puff_displayed:
		return
	puff_displayed = true
	var puff = puff_scene.instantiate() as Node2D
	add_child(puff)
	puff.z_index = 50
	puff.position = (tile_pos + Vector2(0.5, 0.5)) * TILE_SIZE
	puff.finished.connect(func():
		puff_displayed = false
	)

func has_draggable_object_at(pos: Vector2i) -> bool:
	if draggable_objects:
		return draggable_objects.has_active_object_at(pos)
	return false

func get_draggable_object_atlas_coords(pos: Vector2i) -> Vector2i:
	if draggable_objects:
		return draggable_objects.get_cell_atlas_coords(pos)
	return Vector2i(-1, -1)
