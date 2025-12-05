extends Node2D
var level: BaseLevel = null
var current_level_name: String

var is_level_finished: bool = false
var temp_scene_root: Node2D

var level_index = 0
var levels = [
	#"Tutorial1",
	#"Kitchen",
	"Library",
	#"TavernTutorial",
	"Cellar",
	"SawmillDemon",
	"TavernKitchen",
	"SawmillYard",
	"TavernWarehouse",
	"TutorialBarrel",
]

func _ready():
	var level = await load_headless_level(get_level_path(levels[level_index]))
	var solver = LevelSolverLogic.new(level)
	var result = solver.verify_solvability(100000, 500000.0)
	#var solver = MacroSolver.new(get_level_path(levels[level_index]))
	#var stats = await solver.solve()
	#var solver = FastSolver.new()
	#var level = await load_headless_level(get_level_path(levels[level_index]))
	#var stats = await solver.solve_from_level(level)


	if result.solvable:
		print("✓ Solvable in ", result.solution_length, " moves")
	else:
		print("✗ Not solvable!")

func get_level_path(_name: String) -> String:
	var level_name = _name
	return "res://scenes/levels/" + level_name + "/" + level_name + ".tscn"

func load_headless_level(level_scene_path: String) -> BaseLevel:
	if not ResourceLoader.exists(level_scene_path):
		return null
	
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
	level.can_display_puffs = false
	level.hero.can_produce_sounds = false
	
	level.position = Vector2i(300, 300)
	
	return level

func exit_levels():
	SceneSwitcher.change_scene_to_file("res://scenes/game/MainMenu/MainMenu.tscn")
