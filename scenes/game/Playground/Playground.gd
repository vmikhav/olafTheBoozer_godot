extends Node2D

@onready var camera = $TouchCamera as TouchCamera
@onready var nav_buttons = $UiLayer/HudContainer/VBoxContainer/HBoxContainer2/NavButtons
@onready var progress_panel = $UiLayer/HudContainer/VBoxContainer/HBoxContainer/MarginContainer2/MarginContainer/ProgressPanel
@onready var restart_button = $UiLayer/HudContainer/VBoxContainer/HBoxContainer/MarginContainer3/TextureButton as TextureButton
@onready var menu_button = $UiLayer/HudContainer/VBoxContainer/HBoxContainer/MarginContainer/TextureButton as TextureButton
@onready var transition_rect = $UiLayer/SceneTransitionRect
@onready var summary_container = $UiLayer/SummaryContainer
@onready var nav_controller = $NavController
@onready var menu = $UiLayer/LevelMenu
var level: BaseLevel = null

var is_level_finished: bool = false
var level_progress_report: LevelProgressReport

var level_index = 0
var levels = [
	"Cellar",
	"Library",
	"Tutorial0",
	"Kitchen",
	"Tavern",
]

# Called when the node enters the scene tree for the first time.
func _ready():
	nav_buttons.visible = SettingsManager.get_touch_control()
	transition_rect.fade_in()
	if SceneSwitcher.get_param("levels") != null:
		levels = SceneSwitcher.get_param("levels")
	load_level(levels[level_index])
	nav_buttons.actions.connect(imitate_input)
	nav_controller.actions.connect(move_hero)
	restart_button.pressed.connect(restart)
	menu_button.pressed.connect(show_menu)
	summary_container.restart.connect(restart)
	summary_container.next.connect(load_next_level)
	summary_container.progress_filled.connect(start_replay)
	menu.settings.connect(func():
		nav_buttons.visible = SettingsManager.get_touch_control()
	)
	menu.close.connect(close_menu)
	menu.restart.connect(restart)
	menu.exit.connect(func():
		close_menu()
		exit_levels()
	)
	transition_rect.fade_in()

func imitate_input(input: InputEvent):
	nav_controller._input(input)

func restart():
	if not is_level_finished:
		prepare_report()
	await transition_rect.fade_out()
	is_level_finished = false
	level.restart()
	prepare_ui_for_level()
	transition_rect.fade_in()

func start_replay():
	level.replay()

func move_hero(direction: String):
	if direction == "ui_left":
		level.navigate(TileSet.CELL_NEIGHBOR_LEFT_SIDE)
	if direction == "ui_right":
		level.navigate(TileSet.CELL_NEIGHBOR_RIGHT_SIDE)
	if direction == "ui_up":
		level.navigate(TileSet.CELL_NEIGHBOR_TOP_SIDE)
	if direction == "ui_down":
		level.navigate(TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)

func load_level(level_name: String):
	if level != null:
		level.queue_free()
	is_level_finished = false
	var pack = load("res://scenes/levels/" + level_name + "/" + level_name + ".tscn") as PackedScene
	level = pack.instantiate() as BaseLevel
	add_child(level)
	level.process_mode = PROCESS_MODE_PAUSABLE	
	camera.set_target(level.hero)
	camera.limit_top = level.camera_limit.position.y
	camera.limit_left = level.camera_limit.position.x
	camera.limit_bottom = level.camera_limit.end.y
	camera.limit_right = level.camera_limit.end.x
	level.level_finished.connect(on_level_finished)
	progress_panel.set_items_count(level.level_items_count)
	progress_panel.set_ghosts_count(level.ghosts_count)
	level.items_progress_signal.connect(progress_panel.items_progress)
	level.ghosts_progress_signal.connect(progress_panel.ghosts_progress)
	prepare_ui_for_level()

func prepare_ui_for_level():
	camera.restore_original_drag_margins()
	$UiLayer/HudContainer.visible = true
	summary_container.dismiss(false)

func on_level_finished():
	prepare_report()
	is_level_finished = true
	$UiLayer/HudContainer.visible = false
	summary_container.display(level_progress_report)
	camera.offset_drag_margins(Vector4(.4, .4, -0.2, .6))
	#AudioController.stop_music(1.5)
	AudioController.play_music("olaf_fast", 1.5)

func load_next_level():
	await summary_container.dismiss_panel()
	level.is_history_replay = false
	await transition_rect.fade_out()
	var next_scene = level.next_scene
	level.queue_free()
	level = null
	level_index += 1
	if levels.size() <= level_index:
		SceneSwitcher.change_scene_to_file(next_scene[0], next_scene[1])
	else:
		load_level(levels[level_index])
		transition_rect.fade_in()

func exit_levels():
	AudioController.stop_music()
	SceneSwitcher.change_scene_to_file("res://scenes/game/MainMenu/MainMenu.tscn")

func prepare_report():
	level_progress_report = level.fill_progress_report()
	level_progress_report.level = levels[level_index]
	level_progress_report.log_report()

func show_menu():
	get_tree().paused = true
	menu.visible = true
	menu.init_modal()

func close_menu():
	menu.visible = false
	get_tree().paused = false
