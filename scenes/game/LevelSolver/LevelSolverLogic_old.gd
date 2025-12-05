extends Resource
class_name LevelSolverLogicOld

# A robust solver that respects Game Logic by using the actual navigate() function
# instead of trying to manually manipulate tilemaps.

class SolverNode:
	var moves: Array[int] = [] # Array of TileSet.CellNeighbor
	var g_score: int = 0 # Cost (steps)
	var h_score: float = 0.0 # Heuristic
	
	func _init(p_moves: Array[int] = [], g: int = 0, h: float = 0.0):
		moves = p_moves
		g_score = g
		h_score = h
	
	func get_f_score() -> float:
		return g_score + h_score

class SolveStats:
	var is_solvable: bool = false
	var steps: int = 0
	var solution_path: Array[int] = []
	var time_taken: float = 0.0
	var states_explored: int = 0
	var max_depth: int = 0
	
	# Metrics for UX estimation
	var branching_factor_avg: float = 0.0
	var backtracking_complexity: float = 0.0 # How often we had to discard a path
	var mechanics_density: float = 0.0 # Interaction with levers/items per step
	
	func get_difficulty_rating() -> String:
		if not is_solvable: return "Impossible"
		var score = (steps * 0.5) + (branching_factor_avg * 10) + (backtracking_complexity * 2)
		if score < 20: return "Easy"
		if score < 50: return "Medium"
		if score < 100: return "Hard"
		return "Expert"

# Configuration
var level_scene_path: String
var max_nodes: int = 80000
var timeout_seconds: float = 600.0
var working_level: BaseLevel
var temp_scene_root: Node2D
var original_history: Array[HistoryItem] = []

const DIRECTIONS = [
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE
]

func _init(p_level_path: String = "", p_history: Array[HistoryItem] = []):
	level_scene_path = p_level_path
	original_history = p_history

func solve() -> SolveStats:
	var start_time = Time.get_ticks_msec() / 1000.0
	var stats = SolveStats.new()
	
	# 1. Load the level in a headless "Simulation" mode
	working_level = await load_headless_level()
	if not working_level:
		push_error("Failed to load level for solving")
		return stats
	
	print("Solver started for: ", level_scene_path)
	
	# 2. A* Setup
	var priority_queue: Array[SolverNode] = []
	var visited_states: Dictionary = {} # Hash -> g_score
	
	var start_node = SolverNode.new()
	start_node.h_score = calculate_heuristic(working_level)
	priority_queue.append(start_node)
	
	# Initial State Hash
	var initial_hash = get_state_hash(working_level)
	visited_states[initial_hash] = 0
	
	var total_branches = 0
	var nodes_processed = 0
	
	while priority_queue.size() > 0:
		# Safety Breakers
		if Time.get_ticks_msec() / 1000.0 - start_time > timeout_seconds:
			print("Solver Timed Out")
			break
		if nodes_processed > max_nodes:
			print("Solver Max Nodes Reached")
			break
			
		# Pop best node (Sort by F score - lowest first)
		# Note: efficient binary heap is better, but Array.sort is okay for <10k nodes in GDScript
		var current_node: SolverNode
		if stats.states_explored < 1000:
			current_node = priority_queue.pick_random()
			priority_queue.erase(current_node)
		else:
			priority_queue.sort_custom(func(a, b): return a.get_f_score() < b.get_f_score())
			current_node = priority_queue.pop_front()
		nodes_processed += 1
		stats.max_depth = max(stats.max_depth, current_node.moves.size())
		
		# 3. REPLAY STATE
		# We must reset and replay to guarantee game logic integrity (tails, slippery, etc)
		while working_level.history.size() > 1:
			working_level.step_back()
		# Fast forward history (logic only, no tweening delays)
		apply_moves_fast(current_node.moves)
		
		# Check Win Condition
		if working_level.ghosts_progress >= working_level.ghosts_count and working_level.level_items_progress >= working_level.level_items_count:
			stats.is_solvable = true
			stats.steps = current_node.moves.size()
			stats.solution_path = current_node.moves
			break
		
		# 4. EXPLORE NEIGHBORS
		var valid_moves_count = 0
		
		# Snapshot current state before trying moves
		# Note: We can't easily snapshot the whole level, so we rely on step_back logic
		# But since step_back might trigger complex reversals, it's safer/easier 
		# in this specific architecture to replay from start for the *Next* node. 
		# To optimize here: we try the move, hash it, then step back.
		
		for direction in DIRECTIONS:
			# Try navigating
			var old_history_size = working_level.history.size()
			var moved = working_level.navigate(direction, true) # true = skip_check (force input)
			var new_history_size = working_level.history.size()
			#await working_level.get_tree().process_frame
			
			if moved and old_history_size > new_history_size:
				# Inverse step to restore state when step removes the last history item
				working_level.navigate(direction ^ 8, true)
				continue
			
			if moved:
				valid_moves_count += 1
				
				# Check if this state has been visited efficiently
				var new_hash = get_state_hash(working_level)
				var new_g = current_node.g_score + 1
				
				if not visited_states.has(new_hash) or visited_states[new_hash] > new_g:
					visited_states[new_hash] = new_g
					
					var next_node = SolverNode.new()
					next_node.moves = current_node.moves.duplicate()
					next_node.moves.append(direction)
					next_node.g_score = new_g
					next_node.h_score = calculate_heuristic(working_level)
					priority_queue.append(next_node)
					
					if working_level.ghosts_progress >= working_level.ghosts_count and working_level.level_items_progress >= working_level.level_items_count:
						stats.is_solvable = true
						stats.steps = next_node.moves.size()
						stats.solution_path = next_node.moves
						priority_queue.clear()
						break
				
				# CRITICAL: Undo the move to try the next direction
				working_level.step_back(true) # true = manual
		
		total_branches += valid_moves_count
	
	# Cleanup
	cleanup_working_level()
	
	# Finalize Stats
	stats.time_taken = Time.get_ticks_msec() / 1000.0 - start_time
	stats.states_explored = nodes_processed
	if nodes_processed > 0:
		stats.branching_factor_avg = float(total_branches) / float(nodes_processed)
	stats.backtracking_complexity = float(visited_states.size() - stats.steps) / float(max(1, stats.steps))
	
	return stats

# --- Helpers ---

func apply_moves_fast(moves: Array[int]):
	# Disable visuals temporarily inside BaseLevel if possible, or just call navigate
	# BaseLevel usually relies on timers for input, we bypass allow_input check
	working_level.allow_input = true
	for move in moves:
		working_level.navigate(move, true) 

func get_state_hash(level: BaseLevel) -> int:
	# Hashes the MINIMUM VIABLE STATE to detect loops.
	# Must include: Hero Pos, Draggables, Tail, Levers/Plates, Items/Ghosts
	var h = 0
	var FNV_PRIME = 16777619
	
	# 1. Hero
	h = (h ^ level.hero_position.x) * FNV_PRIME
	h = (h ^ level.hero_position.y) * FNV_PRIME
	
	# 2. Draggables (Order independent)
	# We XOR positions of active objects
	var drag_hash = 0
	var active_objects = level.draggable_objects.get_active_objects()
	for obj in active_objects:
		var pos = obj.grid_position
		drag_hash = drag_hash ^ (pos.x + pos.y * 1000)
	h = (h ^ drag_hash) * FNV_PRIME
	
	# 3. Tail (Order DEPENDENT)
	for segment in level.tail:
		h = (h ^ segment.position.x) * FNV_PRIME
		h = (h ^ segment.position.y) * FNV_PRIME
	
	# 4. Progress
	h = (h ^ level.level_items_progress) * FNV_PRIME
	h = (h ^ level.ghosts_progress) * FNV_PRIME
	
	# 5. Triggers (Levers/Plates)
	# We can use the snapshot dictionary key order if sorted, or just specific values
	var trigger_snap = level.triggers_controller.get_state_snapshot()
	# Only hash lever states, plates are usually momentary or derived from position
	var levers = trigger_snap.get("lever_states", {})
	var lever_keys = levers.keys()
	lever_keys.sort()
	for k in lever_keys:
		h = (h ^ (1 if levers[k] else 0)) * FNV_PRIME
		
	return h

func calculate_heuristic(level: BaseLevel) -> float:
	# Lower is better
	var h = 0.0
	
	# 1. Remaining Goals
	var items_left = level.level_items_count - level.level_items_progress
	var ghosts_left = level.ghosts_count - level.ghosts_progress
	
	h += items_left * 10.0
	h += ghosts_left * 15.0
	
	# 2. Distance to nearest objective (Simple Manhattan)
	# This helps guide the search toward goals
	var min_dist = 9999
	
	# Find nearest bad item to fix
	var bad_items = level.tilemaps[BaseLevel.Layer.BAD_ITEMS].get_used_cells()
	for pos in bad_items:
		var current_cell = level.tilemaps[BaseLevel.Layer.ITEMS].get_cell_atlas_coords(pos)
		var bad_cell = level.tilemaps[BaseLevel.Layer.BAD_ITEMS].get_cell_atlas_coords(pos)
		var good_cell = level.tilemaps[BaseLevel.Layer.GOOD_ITEMS].get_cell_atlas_coords(pos)
		
		# If it's still bad and fixable
		if current_cell != good_cell and bad_cell != good_cell:
			var dist = abs(level.hero_position.x - pos.x) + abs(level.hero_position.y - pos.y)
			if dist < min_dist: min_dist = dist
			
	# Find nearest ghost
	for ghost in level.ghosts:
		var dist = abs(level.hero_position.x - ghost.position.x) + abs(level.hero_position.y - ghost.position.y)
		if dist < min_dist: min_dist = dist
		
	if min_dist != 9999:
		h += min_dist
		
	return h

func load_headless_level() -> BaseLevel:
	if not ResourceLoader.exists(level_scene_path): return null
	
	temp_scene_root = Node2D.new()
	temp_scene_root.name = "SolverWorkspace"
	
	var tree = Engine.get_main_loop() as SceneTree
	tree.root.add_child.call_deferred(temp_scene_root)
	await tree.process_frame
	
	var level: BaseLevel = load(level_scene_path).instantiate() as BaseLevel
	temp_scene_root.add_child.call_deferred(level)
	await tree.process_frame
	
	level.process_mode = Node.PROCESS_MODE_DISABLED
	level.visible = false
	level.has_replay = false
	level.can_display_puffs = false
	level.hero.can_produce_sounds = false
	
	# Wait one frame for _ready to fire
	replay_history_to_current_state()
	
	return level

func replay_history_to_current_state():
	if original_history.is_empty():
		return
	
	for history_item in original_history:
		if history_item.direction != -1:
			working_level.navigate(history_item.direction, true)
	
	working_level.history.clear()
	working_level.history.append(HistoryItem.new(working_level.hero_position))
	working_level.history[0].trigger_state = working_level.triggers_controller.get_state_snapshot()

func cleanup_working_level():
	if temp_scene_root:
		temp_scene_root.queue_free()
		temp_scene_root = null
