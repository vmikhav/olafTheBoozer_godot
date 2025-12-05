class_name LevelSolverLogic
extends RefCounted

## Lightweight state representation for fast hypothesis testing
class CompactState:
	var hero_pos: Vector2i
	var items_collected: PackedByteArray  # Bitset for collected items
	var ghosts_consumed: PackedByteArray  # Bitset for consumed ghosts
	var tail_size: int
	var tail_modes: PackedByteArray  # Unit types in tail (for matching with spawns)
	var draggable_positions: PackedVector2Array  # Current draggable object positions
	var trigger_state: int  # Bitset for lever states
	var path_length: int  # Number of moves to reach this state
	var parent_state: CompactState  # For backtracking solution path
	var last_move: int  # Direction of last move (for reconstruction)
	
	func _init():
		items_collected = PackedByteArray()
		ghosts_consumed = PackedByteArray()
		tail_modes = PackedByteArray()
		draggable_positions = PackedVector2Array()
	
	func hash() -> int:
		var h = hero_pos.x + hero_pos.y * 1000
		h = h * 31 + tail_size
		
		# Include items collected
		for i in range(items_collected.size()):
			h = h * 31 + items_collected[i]
		
		# Include ghosts consumed
		for i in range(ghosts_consumed.size()):
			h = h * 31 + ghosts_consumed[i]
		
		# Include draggable positions
		for i in range(draggable_positions.size()):
			var pos = draggable_positions[i]
			h = h * 31 + pos.x + pos.y * 1000
		
		h = h * 31 + trigger_state
		return h
	
	func duplicate() -> CompactState:
		var dup = CompactState.new()
		dup.hero_pos = hero_pos
		dup.items_collected = items_collected.duplicate()
		dup.ghosts_consumed = ghosts_consumed.duplicate()
		dup.tail_size = tail_size
		dup.tail_modes = tail_modes.duplicate()
		dup.draggable_positions = draggable_positions.duplicate()
		dup.trigger_state = trigger_state
		dup.path_length = path_length
		dup.parent_state = parent_state
		dup.last_move = last_move
		return dup

## Strategic goal information
class Goal:
	enum Type {
		COLLECT_ITEMS,      # Collect all items in a region
		CONSUME_GHOST,      # Walk over a ghost
		DELIVER_TO_SPAWN,   # Get tail bot to spawn point
		PULL_DRAGGABLE,     # Move draggable to position
		TOGGLE_LEVER,       # Activate a lever
		REACH_POSITION      # Navigate to specific position
	}
	
	var type: Type
	var target_position: Vector2i
	var ghost_index: int = -1
	var draggable_index: int = -1
	var required_tail_mode: int = -1
	var dependencies: Array[Goal] = []
	var priority: float = 0.0
	
	func _init(goal_type: Type, pos: Vector2i = Vector2i.ZERO):
		type = goal_type
		target_position = pos

## Constraint and dependency analysis
class ConstraintAnalysis:
	var item_positions: Array[Vector2i] = []
	var chokepoints: Array[Vector2i] = []  # Positions that become blockers
	var regions: Array[Array] = []  # Separated regions after items collected
	var critical_items: Array[int] = []  # Items that must be collected in specific order
	var ghost_order_constraints: Dictionary = {}  # Ghost dependencies

## Strategic analysis of level structure
class StrategyAnalysis:
	var chokepoint_items: PackedInt32Array  # Item indices that split regions
	var item_dependencies: Dictionary = {}  # item_idx -> [items that must be collected first]
	var ghost_dependencies: Dictionary = {}  # ghost_idx -> [items/ghosts that must be collected first]
	var regional_goals: Dictionary = {}  # region_id -> [goal indices in that region]
	var collection_order: Array[int] = []  # Recommended collection order for items
	var ghost_order: Array[int] = []  # Recommended order for ghosts
	var critical_paths: Dictionary = {}  # goal_idx -> [positions on critical path]
	
	func _init():
		chokepoint_items = PackedInt32Array()
	
	func is_chokepoint(item_idx: int) -> bool:
		for i in range(chokepoint_items.size()):
			if chokepoint_items[i] == item_idx:
				return true
		return false
	
	func add_chokepoint(item_idx: int):
		if not is_chokepoint(item_idx):
			chokepoint_items.append(item_idx)
	
	func get_dependencies_for_item(item_idx: int) -> Array:
		return item_dependencies.get(item_idx, [])
	
	func get_dependencies_for_ghost(ghost_idx: int) -> Array:
		return ghost_dependencies.get(ghost_idx, [])

## Main solver class
const DIRECTIONS = [
	TileSet.CELL_NEIGHBOR_TOP_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE
]

var level: BaseLevel
var defs = LevelDefinitions

# Cached level data for fast access
var map_width: int
var map_height: int
var map_offset_x: int = 0  # Minimum X coordinate
var map_offset_y: int = 0  # Minimum Y coordinate
var walls_cache: PackedByteArray  # 1 = wall, 0 = passable
var items_cache: Array[Vector2i] = []  # Positions of collectible items
var ghosts_cache: Array[Dictionary] = []  # Ghost data
var draggables_cache: Array[Vector2i] = []  # Initial draggable positions
var movable_items_cache: Array[Vector2i] = []  # Target positions for draggables
var spawn_ghosts_cache: Array[Dictionary] = []  # ENEMY_SPAWN ghosts with required modes

# Solver statistics
var states_explored: int = 0
var solutions_found: int = 0
var max_search_depth: int = 0
var branching_factor_sum: float = 0.0
var branching_count: int = 0
var dead_ends_found: int = 0

# Strategic analysis cache
var strategic_analysis: StrategyAnalysis = null
var use_strategic_planning: bool = true

func _init(base_level: BaseLevel):
	level = base_level
	_cache_level_data()

## Initialize solver with level data
func _cache_level_data():
	# Determine map bounds
	var ground_cells = level.tilemaps[BaseLevel.Layer.GROUND].get_used_cells()
	if ground_cells.is_empty():
		map_width = 16
		map_height = 16
		map_offset_x = 0
		map_offset_y = 0
	else:
		var min_x = 10000
		var max_x = -10000
		var min_y = 10000
		var max_y = -10000
		for cell in ground_cells:
			min_x = min(min_x, cell.x)
			max_x = max(max_x, cell.x)
			min_y = min(min_y, cell.y)
			max_y = max(max_y, cell.y)
		
		map_offset_x = min_x
		map_offset_y = min_y
		map_width = max_x - min_x + 1
		map_height = max_y - min_y + 1
	
	# Cache walls and passable tiles
	var total_cells = map_width * map_height
	walls_cache = PackedByteArray()
	walls_cache.resize(total_cells)
	for i in range(total_cells):
		walls_cache[i] = 0
	
	var walls = level.tilemaps[BaseLevel.Layer.WALLS].get_used_cells()
	for wall_pos in walls:
		var idx = _pos_to_index(wall_pos)
		if idx >= 0 and idx < total_cells:
			walls_cache[idx] = 1
	
	# Cache collectible items (where BAD != GOOD)
	var bad_items = level.tilemaps[BaseLevel.Layer.BAD_ITEMS].get_used_cells()
	for pos in bad_items:
		var bad_coords = level.tilemaps[BaseLevel.Layer.BAD_ITEMS].get_cell_atlas_coords(pos)
		var good_coords = level.tilemaps[BaseLevel.Layer.GOOD_ITEMS].get_cell_atlas_coords(pos)
		if bad_coords != good_coords:
			items_cache.append(pos)
	
	# Cache ghosts
	ghosts_cache.clear()
	spawn_ghosts_cache.clear()
	for i in range(level.ghosts.size()):
		var ghost = level.ghosts[i]
		ghosts_cache.append(ghost)
		if ghost.type == defs.GhostType.ENEMY_SPAWN:
			spawn_ghosts_cache.append({
				"index": i,
				"position": ghost.position,
				"mode": ghost.mode
			})
	
	# Cache draggable objects
	draggables_cache.clear()
	var good_items = level.tilemaps[BaseLevel.Layer.GOOD_ITEMS].get_used_cells()
	for pos in good_items:
		var good_coords = level.tilemaps[BaseLevel.Layer.GOOD_ITEMS].get_cell_atlas_coords(pos)
		var cell_value = str(good_coords.x) + "," + str(good_coords.y)
		if defs.DraggableItems.has(cell_value):
			var bad_coords = level.tilemaps[BaseLevel.Layer.BAD_ITEMS].get_cell_atlas_coords(pos)
			var is_broken = bad_coords != good_coords
			if not is_broken:  # Only active draggables
				draggables_cache.append(pos)
	
	# Cache movable item target positions
	movable_items_cache.clear()
	var movable_cells = level.tilemaps[BaseLevel.Layer.MOVABLE_ITEMS].get_used_cells()
	for pos in movable_cells:
		movable_items_cache.append(pos)

## ============================================================================
## STRATEGIC ANALYSIS - Core of intelligent solving
## ============================================================================

## Perform full strategic analysis of the level
func analyze_level_strategy(strict_mode: bool = false) -> StrategyAnalysis:
	if strategic_analysis != null:
		return strategic_analysis
	
	strategic_analysis = StrategyAnalysis.new()
	
	# Step 1: Find chokepoint items (items that split regions when collected)
	_analyze_chokepoints()
	
	# Step 2: Build reachability graph for all goals (skip for large levels)
	if items_cache.size() + ghosts_cache.size() < 30:
		_analyze_goal_reachability()
	
	# Step 3: Determine collection order constraints
	_build_dependency_graph(strict_mode)
	
	# Step 4: Calculate recommended collection order
	_compute_collection_order()
	
	return strategic_analysis

## Find items that act as chokepoints (collecting them splits accessible regions)
func _analyze_chokepoints():
	# For each item, simulate collecting it and check if any goals become unreachable
	for item_idx in range(items_cache.size()):
		var item_pos = items_cache[item_idx]
		
		# Create a temporary "collected items" set with just this item
		var temp_collected = PackedByteArray()
		var byte_count = (items_cache.size() + 7) / 8
		temp_collected.resize(byte_count)
		for i in range(byte_count):
			temp_collected[i] = 0
		_set_bit(temp_collected, item_idx, true)
		
		# Count how many goals become unreachable
		var blocked_count = 0
		var blocked_goals: Array[int] = []
		
		# Check other items
		for other_idx in range(items_cache.size()):
			if other_idx == item_idx:
				continue
			var other_pos = items_cache[other_idx]
			if not _can_reach_ignoring_items(level.hero_position, other_pos, temp_collected):
				blocked_count += 1
				blocked_goals.append(other_idx)
		
		# Check ghosts
		for ghost_idx in range(ghosts_cache.size()):
			var ghost_pos = ghosts_cache[ghost_idx].position
			if not _can_reach_ignoring_items(level.hero_position, ghost_pos, temp_collected):
				blocked_count += 1
				blocked_goals.append(-ghost_idx - 1)  # Negative to distinguish from items
		
		# Determine if this is a chokepoint based on topology and blocked goals
		var is_chokepoint = false
		
		if blocked_count >= 2:
			# Blocks 2+ goals = definitely a chokepoint
			is_chokepoint = true
		elif blocked_count == 1:
			# Blocks 1 goal: Check topology
			# Count passable directions from item position
			var passable_directions = 0
			for direction in DIRECTIONS:
				var neighbor = _get_neighbor_pos(item_pos, direction)
				if not _is_wall(neighbor):
					passable_directions += 1
			
			# If 3+ directions available, you can step around the item
			# This means collecting it can block the goal permanently
			# In a 2-direction corridor, you MUST walk through anyway
			if passable_directions >= 3:
				is_chokepoint = true
		
		if is_chokepoint:
			strategic_analysis.add_chokepoint(item_idx)

## Check if position B is reachable from position A (ignoring uncollected items, but respecting collected ones)
func _can_reach_ignoring_items(from: Vector2i, to: Vector2i, collected_items: PackedByteArray) -> bool:
	if from == to:
		return true
	
	# Simple BFS to check reachability
	var visited = {}
	var queue = [from]
	visited[from] = true
	
	var max_iterations = map_width * map_height * 2
	var iterations = 0
	
	while not queue.is_empty() and iterations < max_iterations:
		iterations += 1
		var current = queue.pop_front()
		
		if current == to:
			return true
		
		# Try all 4 directions
		for direction in DIRECTIONS:
			var next_pos = _get_neighbor_pos(current, direction)
			
			if visited.has(next_pos):
				continue
			
			# Check if blocked by wall
			if _is_wall(next_pos):
				continue
			
			# Check if blocked by collected item
			var blocked_by_item = false
			for i in range(items_cache.size()):
				if items_cache[i] == next_pos and _get_bit(collected_items, i):
					blocked_by_item = true
					break
			
			if blocked_by_item:
				continue
			
			visited[next_pos] = true
			queue.append(next_pos)
	
	return false

## Analyze which goals are reachable from which positions
func _analyze_goal_reachability():
	# For each goal (item or ghost), determine what's needed to reach it
	var start_pos = level.hero_position
	
	# Analyze each item
	for item_idx in range(items_cache.size()):
		var item_pos = items_cache[item_idx]
		strategic_analysis.critical_paths[item_idx] = _find_critical_path(start_pos, item_pos, PackedByteArray())
	
	# Analyze each ghost
	for ghost_idx in range(ghosts_cache.size()):
		var ghost_pos = ghosts_cache[ghost_idx].position
		var ghost_key = "ghost_" + str(ghost_idx)
		strategic_analysis.critical_paths[ghost_key] = _find_critical_path(start_pos, ghost_pos, PackedByteArray())

## Find the critical path from A to B (positions that must remain passable)
func _find_critical_path(from: Vector2i, to: Vector2i, collected_items: PackedByteArray) -> Array[Vector2i]:
	# Simple BFS pathfinding to find A path (not necessarily optimal)
	var visited = {}
	var parent = {}
	var queue = [from]
	visited[from] = true
	
	while not queue.is_empty():
		var current = queue.pop_front()
		
		if current == to:
			# Reconstruct path
			var path: Array[Vector2i] = []
			var pos = to
			while pos != from:
				path.push_front(pos)
				pos = parent[pos]
			return path
		
		for direction in DIRECTIONS:
			var next_pos = _get_neighbor_pos(current, direction)
			
			if visited.has(next_pos):
				continue
			
			if _is_wall(next_pos):
				continue
			
			# Check if blocked by collected item
			var blocked = false
			for i in range(items_cache.size()):
				if items_cache[i] == next_pos and _get_bit(collected_items, i):
					blocked = true
					break
			
			if blocked:
				continue
			
			visited[next_pos] = true
			parent[next_pos] = current
			queue.append(next_pos)
	
	return []  # No path found

## Build dependency graph showing which goals depend on others
func _build_dependency_graph(strict_mode: bool = false):
	# For each item, check which other items must be collected first
	for item_idx in range(items_cache.size()):
		var dependencies: Array[int] = []
		
		# Check if collecting other items would block this one
		for other_idx in range(items_cache.size()):
			if other_idx == item_idx:
				continue
			
			# Would collecting other_idx make item_idx unreachable?
			if _does_collecting_block_goal(other_idx, item_idx, true):
				# In relaxed mode, only add if it's a known chokepoint
				# In strict mode, add all blocking relationships
				if strict_mode or strategic_analysis.is_chokepoint(other_idx):
					dependencies.append(other_idx)
		
		if not dependencies.is_empty():
			strategic_analysis.item_dependencies[item_idx] = dependencies
	
	# For each ghost, check dependencies
	for ghost_idx in range(ghosts_cache.size()):
		var dependencies: Array = []
		
		# Check items that would block this ghost
		for item_idx in range(items_cache.size()):
			if _does_collecting_block_goal(item_idx, ghost_idx, false):
				# For ghosts, always add blocking items (they're usually important)
				dependencies.append({"type": "item", "index": item_idx})
		
		if not dependencies.is_empty():
			strategic_analysis.ghost_dependencies[ghost_idx] = dependencies

## Check if collecting item_idx makes goal_idx unreachable
func _does_collecting_block_goal(item_idx: int, goal_idx: int, goal_is_item: bool) -> bool:
	var item_pos = items_cache[item_idx]
	
	var goal_pos: Vector2i
	if goal_is_item:
		goal_pos = items_cache[goal_idx]
	else:
		goal_pos = ghosts_cache[goal_idx].position
	
	# Simulate collecting the item
	var temp_collected = PackedByteArray()
	var byte_count = (items_cache.size() + 7) / 8
	temp_collected.resize(byte_count)
	for i in range(byte_count):
		temp_collected[i] = 0
	_set_bit(temp_collected, item_idx, true)
	
	# Check if goal is still reachable
	var reachable_before = _can_reach_ignoring_items(level.hero_position, goal_pos, PackedByteArray())
	var reachable_after = _can_reach_ignoring_items(level.hero_position, goal_pos, temp_collected)
	
	# If truly unreachable after collection, it blocks
	if reachable_before and not reachable_after:
		return true
	
	# Additional check: If item is on critical path AND has 3+ directions
	# This means you can step around it, so collecting blocks the goal
	var critical_path = strategic_analysis.critical_paths.get(goal_idx if goal_is_item else "ghost_" + str(goal_idx), [])
	if item_pos in critical_path:
		# Check topology at item position
		var passable_directions = 0
		for direction in DIRECTIONS:
			var neighbor = _get_neighbor_pos(item_pos, direction)
			if not _is_wall(neighbor):
				passable_directions += 1
		
		# If 3+ directions, you can avoid the item, so it's a true dependency
		if passable_directions >= 3:
			return true
	
	return false

## Compute recommended collection order using topological sort
func _compute_collection_order():
	# Build adjacency list for topological sort
	# If item A blocks item B, then B must come before A in collection order
	var in_degree: Dictionary = {}
	var adj_list: Dictionary = {}
	
	# Initialize
	for item_idx in range(items_cache.size()):
		in_degree[item_idx] = 0
		adj_list[item_idx] = []
	
	# Build graph: if collecting A blocks B, then B -> A (B must come before A)
	for item_idx in range(items_cache.size()):
		var deps = strategic_analysis.get_dependencies_for_item(item_idx)
		for blocker_idx in deps:
			# blocker blocks item_idx, so item_idx must come before blocker
			adj_list[item_idx].append(blocker_idx)
			in_degree[blocker_idx] += 1
	
	# Kahn's algorithm for topological sort
	var queue: Array[int] = []
	for item_idx in range(items_cache.size()):
		if in_degree[item_idx] == 0:
			queue.append(item_idx)
	
	strategic_analysis.collection_order.clear()
	
	while not queue.is_empty():
		var current = queue.pop_front()
		strategic_analysis.collection_order.append(current)
		
		for neighbor in adj_list[current]:
			in_degree[neighbor] -= 1
			if in_degree[neighbor] == 0:
				queue.append(neighbor)
	
	# Similar for ghosts (simplified - just order by dependencies)
	strategic_analysis.ghost_order.clear()
	for ghost_idx in range(ghosts_cache.size()):
		strategic_analysis.ghost_order.append(ghost_idx)

## Check if a state violates strategic constraints
func _violates_strategy(state: CompactState) -> bool:
	if strategic_analysis == null or not use_strategic_planning:
		return false
	
	# Check if we've collected items in wrong order
	var collected_indices: Array[int] = []
	for i in range(items_cache.size()):
		if _get_bit(state.items_collected, i):
			collected_indices.append(i)
	
	# Check ordering constraints
	for item_idx in collected_indices:
		var deps = strategic_analysis.get_dependencies_for_item(item_idx)
		for blocker_idx in deps:
			# If item_idx is collected but blocker_idx blocks it, that's bad
			# Actually, if blocker is NOT collected yet, check if we can still reach other goals
			if not _get_bit(state.items_collected, blocker_idx):
				# blocker_idx not collected yet, but item_idx is collected
				# This might be OK if blocker doesn't actually block anything now
				# This is a soft constraint
				pass
	
	return false

## Calculate strategic heuristic (guides search toward strategic goals)
func _strategic_heuristic(state: CompactState) -> float:
	if strategic_analysis == null or not use_strategic_planning:
		return _heuristic(state)
	
	var h = 0.0
	var uncollected_count = 0
	
	# Prioritize goals in strategic order
	var next_priority_item = -1
	for item_idx in strategic_analysis.collection_order:
		if not _get_bit(state.items_collected, item_idx):
			next_priority_item = item_idx
			break
	
	if next_priority_item >= 0:
		# Strongly guide toward next priority item
		var item_pos = items_cache[next_priority_item]
		h += (abs(state.hero_pos.x - item_pos.x) + abs(state.hero_pos.y - item_pos.y)) * 1.0
		
		# Penalty for uncollected lower-priority items
		for i in range(items_cache.size()):
			if not _get_bit(state.items_collected, i) and i != next_priority_item:
				uncollected_count += 1
		h += uncollected_count * 0.1
	else:
		# All items collected, focus on ghosts
		var next_ghost = -1
		for ghost_idx in strategic_analysis.ghost_order:
			if not _get_bit(state.ghosts_consumed, ghost_idx):
				next_ghost = ghost_idx
				break
		
		if next_ghost >= 0:
			var ghost_pos = ghosts_cache[next_ghost].position
			h += (abs(state.hero_pos.x - ghost_pos.x) + abs(state.hero_pos.y - ghost_pos.y)) * 1.0
	
	# Penalty for being on a chokepoint item position (encourages collecting them early)
	for i in range(strategic_analysis.chokepoint_items.size()):
		var chokepoint_idx = strategic_analysis.chokepoint_items[i]
		if not _get_bit(state.items_collected, chokepoint_idx):
			var choke_pos = items_cache[chokepoint_idx]
			if state.hero_pos == choke_pos:
				h -= 5.0  # Bonus for being on uncollected chokepoint
	
	return h

## Convert position to linear index for cache access
func _pos_to_index(pos: Vector2i) -> int:
	var adjusted_x = pos.x - map_offset_x
	var adjusted_y = pos.y - map_offset_y
	
	if adjusted_x < 0 or adjusted_x >= map_width or adjusted_y < 0 or adjusted_y >= map_height:
		return -1
	
	return adjusted_y * map_width + adjusted_x

## Check if position has a wall
func _is_wall(pos: Vector2i) -> bool:
	var idx = _pos_to_index(pos)
	if idx < 0 or idx >= walls_cache.size():
		return true  # Out of bounds = wall
	return walls_cache[idx] == 1

## Build initial state from current level
func build_initial_state() -> CompactState:
	var state = CompactState.new()
	state.hero_pos = level.hero_position
	
	# Initialize bitsets
	var item_bytes = (items_cache.size() + 7) / 8
	state.items_collected.resize(item_bytes)
	for i in range(item_bytes):
		state.items_collected[i] = 0
	
	var ghost_bytes = (ghosts_cache.size() + 7) / 8
	state.ghosts_consumed.resize(ghost_bytes)
	for i in range(ghost_bytes):
		state.ghosts_consumed[i] = 0
	
	# Mark already collected items
	for i in range(items_cache.size()):
		var pos = items_cache[i]
		var bad_coords = level.tilemaps[BaseLevel.Layer.BAD_ITEMS].get_cell_atlas_coords(pos)
		if bad_coords == Vector2i(-1, -1):  # Already collected
			_set_bit(state.items_collected, i, true)
	
	# Mark already consumed ghosts
	for i in range(level.ghosts.size()):
		if not level.ghosts[i].has("unit") or level.ghosts[i].unit == null or not level.ghosts[i].unit.visible:
			_set_bit(state.ghosts_consumed, i, true)
	
	# Copy tail state
	state.tail_size = level.tail.size()
	state.tail_modes.resize(state.tail_size)
	for i in range(state.tail_size):
		var tail_item = level.tail[i]
		if "mode" in tail_item:
			state.tail_modes[i] = tail_item.mode
		else:
			state.tail_modes[i] = 0
	
	# Copy draggable positions
	var active_draggables = level.draggable_objects.get_active_objects()
	state.draggable_positions.resize(active_draggables.size())
	for i in range(active_draggables.size()):
		state.draggable_positions[i] = active_draggables[i].grid_position
	
	# Copy trigger state (simplified - just levers for now)
	state.trigger_state = 0
	var lever_idx = 0
	for lever_pos in level.lever_positions.keys():
		var lever_id = level.lever_positions[lever_pos]
		var trigger = level.triggers_controller.get_trigger(lever_id)
		if trigger and trigger.is_activated:
			state.trigger_state |= (1 << lever_idx)
		lever_idx += 1
	
	state.path_length = 0
	state.parent_state = null
	state.last_move = -1
	
	return state

## Bit manipulation helpers
func _set_bit(array: PackedByteArray, bit_index: int, value: bool):
	var byte_idx = bit_index / 8
	var bit_pos = bit_index % 8
	if byte_idx >= array.size():
		return
	if value:
		array[byte_idx] |= (1 << bit_pos)
	else:
		array[byte_idx] &= ~(1 << bit_pos)

func _get_bit(array: PackedByteArray, bit_index: int) -> bool:
	var byte_idx = bit_index / 8
	var bit_pos = bit_index % 8
	if byte_idx >= array.size():
		return false
	return (array[byte_idx] & (1 << bit_pos)) != 0

## Check if all goals are completed in state
func _is_goal_state(state: CompactState) -> bool:
	# All items collected
	for i in range(items_cache.size()):
		if not _get_bit(state.items_collected, i):
			return false
	
	# All ghosts consumed
	for i in range(ghosts_cache.size()):
		if not _get_bit(state.ghosts_consumed, i):
			return false
	
	# All draggables on target positions (if any targets exist)
	if not movable_items_cache.is_empty():
		for draggable_pos in state.draggable_positions:
			var on_target = false
			for target_pos in movable_items_cache:
				if draggable_pos.x == target_pos.x and draggable_pos.y == target_pos.y:
					on_target = true
					break
			if not on_target:
				return false
	
	return true

## Generate possible moves from current state
func _get_possible_moves(state: CompactState, real_level: BaseLevel = null) -> Array[CompactState]:
	var moves: Array[CompactState] = []
	
	for direction in DIRECTIONS:
		var new_state = _try_move(state, direction, real_level)
		if new_state != null:
			moves.append(new_state)
	
	return moves

## Try to move in a direction and return new state if valid
func _try_move(state: CompactState, direction: int, real_level: BaseLevel = null) -> CompactState:
	# Get neighbor position
	var new_pos = _get_neighbor_pos(state.hero_pos, direction)
	
	# Check bounds (using offset coordinates)
	var adjusted_x = new_pos.x - map_offset_x
	var adjusted_y = new_pos.y - map_offset_y
	if adjusted_x < 0 or adjusted_x >= map_width or adjusted_y < 0 or adjusted_y >= map_height:
		return null
	
	# Check if wall
	if _is_wall(new_pos):
		# Check if it's a lever
		if real_level and real_level.lever_positions.has(new_pos):
			# Lever bump - create new state with toggled lever
			var new_state = state.duplicate()
			var lever_idx = 0
			for lever_pos in real_level.lever_positions.keys():
				if lever_pos == new_pos:
					new_state.trigger_state ^= (1 << lever_idx)
					new_state.path_length = state.path_length + 1
					new_state.parent_state = state
					new_state.last_move = direction
					return new_state
				lever_idx += 1
		return null
	
	# Check if blocked by collected item
	for i in range(items_cache.size()):
		if _get_bit(state.items_collected, i) and items_cache[i] == new_pos:
			return null
	
	# Check if blocked by tail
	# (Simplified - in real implementation would track tail positions)
	
	# Check if blocked by active draggable
	for draggable_pos in state.draggable_positions:
		if draggable_pos == new_pos:
			return null
	
	# Valid move - create new state
	var new_state = state.duplicate()
	new_state.hero_pos = new_pos
	new_state.path_length = state.path_length + 1
	new_state.parent_state = state
	new_state.last_move = direction
	
	# Check for item collection
	var collected_item_at_new_pos = false
	for i in range(items_cache.size()):
		if items_cache[i] == new_pos and not _get_bit(state.items_collected, i):
			_set_bit(new_state.items_collected, i, true)
			collected_item_at_new_pos = true
			break
	
	# DEAD-END DETECTION: If we just collected an item, check if it cuts off other goals
	if collected_item_at_new_pos:
		if _creates_unreachable_goals(new_state, new_pos):
			# This item blocks access to other goals - reject this state
			return null
	
	# Check for ghost consumption
	for i in range(ghosts_cache.size()):
		if ghosts_cache[i].position == new_pos and not _get_bit(state.ghosts_consumed, i):
			_set_bit(new_state.ghosts_consumed, i, true)
			var ghost = ghosts_cache[i]
			if ghost.type == defs.GhostType.ENEMY:
				# Add to tail
				new_state.tail_size += 1
				new_state.tail_modes.append(ghost.mode)
			break
	
	# Check for ENEMY_SPAWN ghost interaction
	for spawn_data in spawn_ghosts_cache:
		if spawn_data.position == new_pos:
			var spawn_idx = spawn_data.index
			if not _get_bit(state.ghosts_consumed, spawn_idx):
				# Check if we have matching tail bot
				if new_state.tail_size > 0 and new_state.tail_modes[new_state.tail_size - 1] == spawn_data.mode:
					_set_bit(new_state.ghosts_consumed, spawn_idx, true)
					new_state.tail_size -= 1
					new_state.tail_modes.resize(new_state.tail_size)
			break
	
	# TODO: Handle draggable pulling
	# TODO: Handle slippery floors (sliding)
	# TODO: Handle trails
	# TODO: Handle press plates
	
	return new_state

## Check if a newly placed blocker cuts off unreached goals
func _creates_unreachable_goals(state: CompactState, blocker_pos: Vector2i) -> bool:
	# Quick check: can we still reach all uncompleted goals?
	var unreached_positions: Array[Vector2i] = []
	
	# Add uncollected items
	for i in range(items_cache.size()):
		if not _get_bit(state.items_collected, i):
			unreached_positions.append(items_cache[i])
	
	# Add unconsumed ghosts
	for i in range(ghosts_cache.size()):
		if not _get_bit(state.ghosts_consumed, i):
			unreached_positions.append(ghosts_cache[i].position)
	
	if unreached_positions.is_empty():
		return false  # No more goals, can't create unreachability
	
	# Simple flood fill from hero position (with blocker in place)
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [state.hero_pos]
	visited[state.hero_pos] = true
	
	while not queue.is_empty():
		var pos = queue.pop_front()
		
		# Try all 4 directions
		for dir in DIRECTIONS:
			var next_pos = _get_neighbor_pos(pos, dir)
			
			# Skip if already visited
			if visited.has(next_pos):
				continue
			
			# Skip if out of bounds or wall
			if _is_wall(next_pos):
				continue
			
			# Skip if it's the new blocker
			if next_pos == blocker_pos:
				continue
			
			# Skip if blocked by already-collected item
			var blocked = false
			for i in range(items_cache.size()):
				if _get_bit(state.items_collected, i) and items_cache[i] == next_pos:
					blocked = true
					break
			if blocked:
				continue
			
			# Can reach this position
			visited[next_pos] = true
			queue.append(next_pos)
	
	# Check if any unreached goal is not in visited set
	for goal_pos in unreached_positions:
		if not visited.has(goal_pos):
			# This goal is unreachable after placing the blocker!
			return true
	
	return false

## Get neighbor position in direction
func _get_neighbor_pos(pos: Vector2i, direction: int) -> Vector2i:
	match direction:
		TileSet.CELL_NEIGHBOR_TOP_SIDE:
			return Vector2i(pos.x, pos.y - 1)
		TileSet.CELL_NEIGHBOR_BOTTOM_SIDE:
			return Vector2i(pos.x, pos.y + 1)
		TileSet.CELL_NEIGHBOR_LEFT_SIDE:
			return Vector2i(pos.x - 1, pos.y)
		TileSet.CELL_NEIGHBOR_RIGHT_SIDE:
			return Vector2i(pos.x + 1, pos.y)
	return pos

## Calculate heuristic for A* (Manhattan distance to nearest uncompleted goal)
func _heuristic(state: CompactState) -> float:
	var total_distance = 0.0
	var uncompleted_goals = 0
	
	# Distance to uncollected items (low priority)
	for i in range(items_cache.size()):
		if not _get_bit(state.items_collected, i):
			var item_pos = items_cache[i]
			total_distance += abs(state.hero_pos.x - item_pos.x) + abs(state.hero_pos.y - item_pos.y)
			uncompleted_goals += 1
	
	# Distance to unconsumed ghosts
	for i in range(ghosts_cache.size()):
		if not _get_bit(state.ghosts_consumed, i):
			var ghost_pos = ghosts_cache[i].position
			var distance = abs(state.hero_pos.x - ghost_pos.x) + abs(state.hero_pos.y - ghost_pos.y)
			
			# Strategic penalties
			var penalty = 0.0
			
			# ENEMY ghosts create tail - delay them unless needed for spawns
			if ghosts_cache[i].type == defs.GhostType.ENEMY:
				# Check if we need this enemy for a spawn
				var needed_for_spawn = false
				for spawn in spawn_ghosts_cache:
					if not _get_bit(state.ghosts_consumed, spawn.index):
						if spawn.mode == ghosts_cache[i].mode:
							needed_for_spawn = true
							break
				
				if not needed_for_spawn:
					penalty = 20.0  # Avoid enemy ghosts unless needed
			
			# ENEMY_SPAWN needs delivery - high priority if we have matching tail
			elif ghosts_cache[i].type == defs.GhostType.ENEMY_SPAWN:
				# Check if we have matching tail bot
				var has_matching_tail = false
				if state.tail_size > 0:
					var required_mode = ghosts_cache[i].mode
					for tail_idx in range(state.tail_size):
						if state.tail_modes[tail_idx] == required_mode:
							has_matching_tail = true
							break
				
				if has_matching_tail:
					penalty = -30.0  # Prioritize delivering to spawn
				else:
					penalty = 40.0  # Can't complete yet, deprioritize
			
			total_distance += distance + penalty
			uncompleted_goals += 1
	
	if uncompleted_goals == 0:
		return 0.0
	
	return total_distance / float(uncompleted_goals)

## Main solving function - Check if level is solvable
func verify_solvability(max_states: int = 100000, time_limit_ms: float = 5000.0, use_strategy: bool = true) -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	# Reset statistics
	states_explored = 0
	solutions_found = 0
	max_search_depth = 0
	branching_factor_sum = 0.0
	branching_count = 0
	dead_ends_found = 0
	
	# Perform strategic analysis
	use_strategic_planning = use_strategy
	if use_strategic_planning:
		var strategy_start = Time.get_ticks_msec()
		analyze_level_strategy(false)  # Use relaxed mode (not strict)
		var strategy_time = Time.get_ticks_msec() - strategy_start
		if OS.is_debug_build():
			print("\n=== Strategic Analysis (", strategy_time, "ms) ===")
			print("Chokepoint items: ", strategic_analysis.chokepoint_items.size())
			for i in range(strategic_analysis.chokepoint_items.size()):
				var idx = strategic_analysis.chokepoint_items[i]
				print("  Item ", idx, " at ", items_cache[idx], " is a chokepoint")
			print("Item dependencies: ", strategic_analysis.item_dependencies.size())
			for item_idx in strategic_analysis.item_dependencies.keys():
				var deps = strategic_analysis.item_dependencies[item_idx]
				print("  Item ", item_idx, " blocked by items: ", deps)
			print("Recommended collection order: ", strategic_analysis.collection_order)
			print("Ghost order: ", strategic_analysis.ghost_order)
	
	var initial_state = build_initial_state()
	
	# Check if already solved
	if _is_goal_state(initial_state):
		return {
			"solvable": true,
			"solution_length": 0,
			"states_explored": 1,
			"time_ms": Time.get_ticks_msec() - start_time
		}
	
	# A* search with priority queue
	var open_set: Array[CompactState] = [initial_state]
	var open_set_hashes: Dictionary = {}  # hash -> bool (track what's in open set)
	var closed_set: Dictionary = {}  # hash -> bool
	var g_score: Dictionary = {}  # hash -> cost
	var f_score: Dictionary = {}  # hash -> estimated total cost
	
	var initial_hash = initial_state.hash()
	open_set_hashes[initial_hash] = true
	g_score[initial_hash] = 0
	f_score[initial_hash] = _strategic_heuristic(initial_state) if use_strategic_planning else _heuristic(initial_state)
	
	while not open_set.is_empty():
		# Check time limit
		if Time.get_ticks_msec() - start_time > time_limit_ms:
			return {
				"solvable": false,
				"error": "timeout",
				"states_explored": states_explored,
				"time_ms": time_limit_ms
			}
		
		# Check state limit
		if states_explored >= max_states:
			return {
				"solvable": false,
				"error": "max_states_reached",
				"states_explored": states_explored,
				"time_ms": Time.get_ticks_msec() - start_time
			}
		
		# Get state with lowest f_score
		var current = _get_lowest_f_score_state(open_set, f_score)
		var current_hash = current.hash()
		
		# Goal check
		if _is_goal_state(current):
			solutions_found += 1
			var solution_path = _reconstruct_path(current)
			return {
				"solvable": true,
				"solution_length": solution_path.size(),
				"solution_path": solution_path,
				"states_explored": states_explored,
				"max_depth": max_search_depth,
				"time_ms": Time.get_ticks_msec() - start_time,
				"branching_factor": branching_factor_sum / max(1.0, branching_count),
				"dead_ends": dead_ends_found
			}
		
		# Move from open to closed
		open_set.erase(current)
		open_set_hashes.erase(current_hash)
		closed_set[current_hash] = true
		states_explored += 1
		max_search_depth = max(max_search_depth, current.path_length)
		
		# Explore neighbors
		var neighbors = _get_possible_moves(current, level)
		
		if neighbors.is_empty():
			dead_ends_found += 1
		else:
			branching_factor_sum += neighbors.size()
			branching_count += 1
		
		for neighbor in neighbors:
			var neighbor_hash = neighbor.hash()
			
			if closed_set.has(neighbor_hash):
				continue
			
			var tentative_g = g_score.get(current_hash, INF) + 1
			
			if not g_score.has(neighbor_hash) or tentative_g < g_score[neighbor_hash]:
				g_score[neighbor_hash] = tentative_g
				f_score[neighbor_hash] = tentative_g + (_strategic_heuristic(neighbor) if use_strategic_planning else _heuristic(neighbor))
				
				if not open_set_hashes.has(neighbor_hash):
					open_set.append(neighbor)
					open_set_hashes[neighbor_hash] = true
	
	# No solution found
	return {
		"solvable": false,
		"states_explored": states_explored,
		"max_depth": max_search_depth,
		"time_ms": Time.get_ticks_msec() - start_time,
		"dead_ends": dead_ends_found
	}

## Get state with lowest f_score from open set
func _get_lowest_f_score_state(open_set: Array[CompactState], f_scores: Dictionary) -> CompactState:
	var best_state = open_set[0]
	var best_score = f_scores.get(best_state.hash(), INF)
	
	for i in range(1, open_set.size()):
		var state = open_set[i]
		var score = f_scores.get(state.hash(), INF)
		if score < best_score:
			best_score = score
			best_state = state
	
	return best_state

## Reconstruct solution path from goal state
func _reconstruct_path(goal_state: CompactState) -> Array[int]:
	var path: Array[int] = []
	var current = goal_state
	
	while current.parent_state != null:
		path.push_front(current.last_move)
		current = current.parent_state
	
	return path

## Check if current state can still be solved
func can_solve_from_current_state(max_states: int = 50000, time_limit_ms: float = 2000.0) -> Dictionary:
	# This uses the same verification but from current state
	return verify_solvability(max_states, time_limit_ms)

## Reset strategic analysis (useful for re-analysis with different settings)
func reset_strategic_analysis():
	strategic_analysis = null

## Analyze level difficulty and gather statistics
func analyze_difficulty() -> Dictionary:
	var analysis = {
		"total_items": items_cache.size(),
		"total_ghosts": ghosts_cache.size(),
		"enemy_ghosts": 0,
		"spawn_ghosts": spawn_ghosts_cache.size(),
		"draggable_objects": draggables_cache.size(),
		"map_size": map_width * map_height,
		"complexity_score": 0.0,
		"estimated_difficulty": "unknown"
	}
	
	# Count enemy ghosts
	for ghost in ghosts_cache:
		if ghost.type == defs.GhostType.ENEMY:
			analysis.enemy_ghosts += 1
	
	# Calculate complexity score
	var complexity = 0.0
	complexity += items_cache.size() * 1.0  # Each item adds complexity
	complexity += analysis.enemy_ghosts * 3.0  # Tail management is complex
	complexity += spawn_ghosts_cache.size() * 5.0  # Spawns require planning
	complexity += draggables_cache.size() * 4.0  # Draggables require positioning
	
	analysis.complexity_score = complexity
	
	# Estimate difficulty
	if complexity < 10:
		analysis.estimated_difficulty = "easy"
	elif complexity < 30:
		analysis.estimated_difficulty = "medium"
	elif complexity < 60:
		analysis.estimated_difficulty = "hard"
	else:
		analysis.estimated_difficulty = "very_hard"
	
	return analysis

## Build strategic goals for hierarchical planning
func build_strategic_plan() -> Array[Goal]:
	var goals: Array[Goal] = []
	
	# Create goals for all ghosts
	for i in range(ghosts_cache.size()):
		var ghost = ghosts_cache[i]
		if ghost.type == defs.GhostType.ENEMY_SPAWN:
			# This requires delivering a tail bot
			var goal = Goal.new(Goal.Type.DELIVER_TO_SPAWN, ghost.position)
			goal.ghost_index = i
			goal.required_tail_mode = ghost.mode
			goal.priority = 10.0  # High priority
			goals.append(goal)
		else:
			# Simple consumption
			var goal = Goal.new(Goal.Type.CONSUME_GHOST, ghost.position)
			goal.ghost_index = i
			goal.priority = 5.0 if ghost.type == defs.GhostType.ENEMY else 3.0
			goals.append(goal)
	
	# Create goals for draggable objects that need to be moved
	for i in range(draggables_cache.size()):
		var drag_pos = draggables_cache[i]
		# Find if there's a target for this draggable
		for target_pos in movable_items_cache:
			if drag_pos != target_pos:
				var goal = Goal.new(Goal.Type.PULL_DRAGGABLE, target_pos)
				goal.draggable_index = i
				goal.priority = 6.0
				goals.append(goal)
				break
	
	# Items are background complexity - no explicit goals
	
	return goals

## Generate detailed difficulty report
func generate_difficulty_report() -> Dictionary:
	var basic_analysis = analyze_difficulty()
	
	# Try to solve to get more metrics
	var solve_result = verify_solvability(10000, 3000.0)
	
	var report = basic_analysis.duplicate()
	report["solvable"] = solve_result.get("solvable", false)
	
	if solve_result.get("solvable", false):
		report["solution_length"] = solve_result.get("solution_length", 0)
		report["search_efficiency"] = solve_result.get("solution_length", 0) / float(max(1, solve_result.get("states_explored", 1)))
		report["branching_factor"] = solve_result.get("branching_factor", 0.0)
		report["dead_end_ratio"] = solve_result.get("dead_ends", 0) / float(max(1, solve_result.get("states_explored", 1)))
		
		# Difficulty factors
		var tightness = 1.0 - report["search_efficiency"]  # Low efficiency = tight puzzle
		var exploration = solve_result.get("states_explored", 0) / 1000.0  # Normalized
		
		# Update difficulty estimate based on solving metrics
		var difficulty_score = (
			tightness * 40.0 +
			exploration * 20.0 +
			report["complexity_score"] * 0.5 +
			report["branching_factor"] * 10.0
		)
		
		if difficulty_score < 30:
			report["estimated_difficulty"] = "easy"
			report["enjoyment_prediction"] = "good_for_beginners"
		elif difficulty_score < 60:
			report["estimated_difficulty"] = "medium"
			report["enjoyment_prediction"] = "balanced_challenge"
		elif difficulty_score < 100:
			report["estimated_difficulty"] = "hard"
			report["enjoyment_prediction"] = "satisfying_puzzle"
		else:
			report["estimated_difficulty"] = "very_hard"
			report["enjoyment_prediction"] = "expert_challenge"
		
		# Frustration potential
		if report["dead_end_ratio"] > 0.3:
			report["frustration_risk"] = "high"
		elif report["dead_end_ratio"] > 0.15:
			report["frustration_risk"] = "moderate"
		else:
			report["frustration_risk"] = "low"
	else:
		report["error"] = solve_result.get("error", "unsolvable")
	
	report["solve_time_ms"] = solve_result.get("time_ms", 0.0)
	
	return report

## Quick check if level has obvious issues
func quick_sanity_check() -> Dictionary:
	var issues: Array[String] = []
	
	# Check if hero is on valid ground
	if _is_wall(level.hero_position):
		issues.append("Hero starts on a wall")
	
	# Check if all ghosts are reachable (basic check)
	for ghost in ghosts_cache:
		if _is_wall(ghost.position):
			issues.append("Ghost at " + str(ghost.position) + " is on a wall")
	
	# Check spawn/enemy balance
	var enemy_count = 0
	for ghost in ghosts_cache:
		if ghost.type == defs.GhostType.ENEMY:
			enemy_count += 1
	
	if spawn_ghosts_cache.size() > enemy_count:
		issues.append("More spawn points than enemy ghosts")
	
	return {
		"has_issues": not issues.is_empty(),
		"issues": issues
	}

## Debug function to print cached level data
func debug_print_level_info():
	print("\n=== Level Solver Debug Info ===")
	print("Map bounds: offset=(", map_offset_x, ",", map_offset_y, "), size=(", map_width, "x", map_height, ")")
	print("Hero start: ", level.hero_position)
	print("Items (", items_cache.size(), "):")
	for i in range(items_cache.size()):
		print("  [", i, "] ", items_cache[i])
	print("Ghosts (", ghosts_cache.size(), "):")
	for i in range(ghosts_cache.size()):
		var ghost = ghosts_cache[i]
		var type_name = ["MEMORY", "ENEMY", "ENEMY_SPAWN"][ghost.type]
		print("  [", i, "] ", ghost.position, " - ", type_name)
	print("Draggables (", draggables_cache.size(), "):")
	for i in range(draggables_cache.size()):
		print("  [", i, "] ", draggables_cache[i])
	print("Walls cache size: ", walls_cache.size(), " cells")
	print("Ground cells:")
	var ground_cells = level.tilemaps[BaseLevel.Layer.GROUND].get_used_cells()
	for cell in ground_cells:
		var idx = _pos_to_index(cell)
		var is_wall = _is_wall(cell)
		print("  ", cell, " -> index=", idx, ", wall=", is_wall)
	print("===============================\n")

## Debug function to print strategic analysis results
func debug_print_strategy():
	if strategic_analysis == null:
		print("\n=== No Strategic Analysis Available ===")
		print("Run analyze_level_strategy() or verify_solvability() first")
		return
	
	print("\n=== Strategic Analysis ===")
	print("\nChokepoint Items (", strategic_analysis.chokepoint_items.size(), "):")
	for i in range(strategic_analysis.chokepoint_items.size()):
		var item_idx = strategic_analysis.chokepoint_items[i]
		print("  Item ", item_idx, " at ", items_cache[item_idx], " - collecting blocks other goals")
	
	print("\nItem Dependencies:")
	if strategic_analysis.item_dependencies.is_empty():
		print("  None - items can be collected in any order")
	else:
		for item_idx in strategic_analysis.item_dependencies.keys():
			var blockers = strategic_analysis.item_dependencies[item_idx]
			print("  Item ", item_idx, " at ", items_cache[item_idx])
			print("    Blocked by items: ", blockers)
			for blocker_idx in blockers:
				print("      - Item ", blocker_idx, " at ", items_cache[blocker_idx])
	
	print("\nGhost Dependencies:")
	if strategic_analysis.ghost_dependencies.is_empty():
		print("  None - ghosts can be consumed in any order")
	else:
		for ghost_idx in strategic_analysis.ghost_dependencies.keys():
			var deps = strategic_analysis.ghost_dependencies[ghost_idx]
			print("  Ghost ", ghost_idx, " at ", ghosts_cache[ghost_idx].position)
			print("    Dependencies: ", deps.size())
	
	print("\nRecommended Collection Order:")
	if strategic_analysis.collection_order.is_empty():
		print("  No specific order required")
	else:
		for i in range(strategic_analysis.collection_order.size()):
			var item_idx = strategic_analysis.collection_order[i]
			print("  ", i+1, ". Item ", item_idx, " at ", items_cache[item_idx])
	
	print("\nRecommended Ghost Order:")
	for i in range(strategic_analysis.ghost_order.size()):
		var ghost_idx = strategic_analysis.ghost_order[i]
		print("  ", i+1, ". Ghost ", ghost_idx, " at ", ghosts_cache[ghost_idx].position)
	
	print("===========================\n")
