extends Node2D

@onready var camera = $TouchCamera as TouchCamera
@onready var nav_buttons = $UiLayer/HudContainer/VBoxContainer/HBoxContainer2/NavButtons
@onready var progress_panel = $UiLayer/HudContainer/VBoxContainer/HBoxContainer/MarginContainer2/MarginContainer/ProgressPanel
@onready var undo_button = $UiLayer/HudContainer/VBoxContainer/HBoxContainer/MarginContainer3/TextureButton as TextureButton
@onready var menu_button = $UiLayer/HudContainer/VBoxContainer/HBoxContainer/MarginContainer/TextureButton as TextureButton
@onready var transition_rect = $UiLayer/SceneTransitionRect
@onready var summary_container = $UiLayer/SummaryContainer
@onready var nav_controller = $NavController
@onready var menu = $MenuLayer/LevelMenu
var level: BaseLevel = null
var current_level_name: String

var is_level_finished: bool = false
var in_intro: bool = false
var level_progress_report: LevelProgressReport

var level_index = 0
var levels = [
	"SawmillYard",
	"TavernTutorial",
	"TavernKitchen",
	"Kitchen",
	"Cellar",
	"Library",
	"TavernWarehouse",
	"Tutorial0",
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
	undo_button.pressed.connect(undo_step)
	menu_button.pressed.connect(show_menu)
	summary_container.restart.connect(restart)
	summary_container.next.connect(load_next_level)
	summary_container.progress_filled.connect(start_replay)
	menu.settings.connect(func():
		nav_buttons.visible = SettingsManager.get_touch_control()
	)
	menu.close.connect(close_menu)
	menu.restart.connect(restart)
	menu.skip.connect(skip)
	menu.exit.connect(func():
		AudioController.stop_music(0)
		close_menu()
		exit_levels()
	)
	play_intro()

func _process(delta):
	if Input.is_action_just_pressed("toggle_menu"):
		show_menu()
	if Input.is_action_just_pressed("restart_level"):
		restart()

func imitate_input(input: InputEvent):
	nav_controller._input(input)

func undo_step():
	if not is_level_finished:
		level.step_back(true)

func restart():
	if in_intro:
		return
	if not is_level_finished:
		prepare_report()
	await transition_rect.fade_out()
	is_level_finished = false
	level.restart()
	prepare_ui_for_level()
	play_intro(false)

func skip():
	if in_intro:
		return
	if not is_level_finished:
		prepare_report()
	load_next_level()

func start_replay():
	level.replay()

func move_hero(direction: String):
	if direction == "step_left":
		level.navigate(TileSet.CELL_NEIGHBOR_LEFT_SIDE)
	if direction == "step_right":
		level.navigate(TileSet.CELL_NEIGHBOR_RIGHT_SIDE)
	if direction == "step_up":
		level.navigate(TileSet.CELL_NEIGHBOR_TOP_SIDE)
	if direction == "step_down":
		level.navigate(TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)
	if direction == "undo_step":
		undo_step()

func load_level(level_name: String):
	if level != null:
		level.queue_free()
	is_level_finished = false
	current_level_name = level_name
	var path := get_level_path(level_name)
	if !ResourceLoader.exists(path):
		push_error("Level " + level_name + " not found")
		exit_levels()
		return
	level = load(path).instantiate() as BaseLevel
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
	camera.set_drag_offset(Vector2(0, 0))
	$UiLayer/HudContainer.visible = true
	summary_container.dismiss(false)

func on_level_finished():
	prepare_report()
	is_level_finished = true
	$UiLayer/HudContainer.visible = false
	summary_container.display(level_progress_report)
	camera.set_drag_offset(Vector2(0, 0.3))
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
		play_intro()

func exit_levels():
	AudioController.stop_music()
	prepare_report()
	SceneSwitcher.change_scene_to_file("res://scenes/game/MainMenu/MainMenu.tscn")

func prepare_report():
	level_progress_report = level.fill_progress_report()
	level_progress_report.level = levels[level_index]
	if level_progress_report.steps_count == 0:
		return
	var json = level_progress_report.log_report()
	var headers = ["Content-Type: application/json"]
	$HTTPRequest.request("https://hidalgocode.com/d/olaf.php", headers, HTTPClient.METHOD_POST, json)

func show_menu():
	if in_intro:
		return
	get_tree().paused = true
	menu.visible = true
	menu.init_modal()

func close_menu():
	menu.visible = false
	get_tree().paused = false

func get_level_path(_name: String) -> String:
	var level_name = _name
	return "res://scenes/levels/" + level_name + "/" + level_name + ".tscn"

func get_level_intro_path(_name: String) -> String:
	var level_name = _name
	return "res://scenes/levels/" + level_name + "/" + level_name + "_intro.tscn"

func play_intro(init: bool = true):
	var intro_path := get_level_intro_path(current_level_name)
	var intro: BaseLevelIntro = null
	if ResourceLoader.exists(intro_path):
		intro = load(intro_path).instantiate() as BaseLevelIntro
		add_child(intro)
	if intro == null:
		transition_rect.fade_in()
		return
	in_intro = true
	var fade = 0.5 if init else 0.25
	$UiLayer/HudContainer.visible = false
	await transition_rect.fade_in(fade)
	intro.visible = true
	intro.play(init)
	await intro.finished
	await transition_rect.fade_out(fade)
	intro.queue_free()
	intro = null
	$UiLayer/HudContainer.visible = true
	in_intro = false
	transition_rect.fade_in(fade)
