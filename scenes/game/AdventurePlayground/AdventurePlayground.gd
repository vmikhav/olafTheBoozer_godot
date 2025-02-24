extends Node2D

@onready var camera = $TouchCamera as TouchCamera
@onready var nav_buttons = $UiLayer/HudContainer/VBoxContainer/HBoxContainer2/NavButtons
@onready var menu_button = $UiLayer/HudContainer/VBoxContainer/HBoxContainer/MarginContainer/TextureButton as TextureButton
@onready var transition_rect = $UiLayer/SceneTransitionRect
@onready var nav_controller = $NavController
@onready var menu_layer = $MenuLayer
@onready var menu = $MenuLayer/AdventureMenu
var level: BaseAdventure = null

var is_level_finished: bool = false

var level_index = 0
var levels = [
	"StartTavern"
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
	menu_button.pressed.connect(show_menu)
	menu.settings.connect(func():
		nav_buttons.visible = SettingsManager.get_touch_control()
	)
	menu.close.connect(close_menu)
	menu.exit.connect(func():
		AudioController.stop_music(0)
		close_menu()
		exit_levels()
	)
	transition_rect.fade_in()

func _process(delta):
	if Input.is_action_just_pressed("toggle_menu"):
		show_menu()

func imitate_input(input: InputEvent):
	nav_controller._input(input)

func move_hero(direction: String):
	if direction == "step_left":
		level.navigate(TileSet.CELL_NEIGHBOR_LEFT_SIDE)
	if direction == "step_right":
		level.navigate(TileSet.CELL_NEIGHBOR_RIGHT_SIDE)
	if direction == "step_up":
		level.navigate(TileSet.CELL_NEIGHBOR_TOP_SIDE)
	if direction == "step_down":
		level.navigate(TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)

func load_level(level_name: String):
	if level != null:
		level.queue_free()
	is_level_finished = false
	var path := "res://scenes/adventures/" + level_name + "/" + level_name + ".tscn"
	if !ResourceLoader.exists(path):
		push_error("Level " + level_name + " not found")
		exit_levels()
		return
	level = load(path).instantiate() as BaseAdventure
	add_child(level)
	level.process_mode = PROCESS_MODE_PAUSABLE	
	camera.set_target(level.hero)
	camera.limit_top = level.camera_limit.position.y
	camera.limit_left = level.camera_limit.position.x
	camera.limit_bottom = level.camera_limit.end.y
	camera.limit_right = level.camera_limit.end.x
	level.level_finished.connect(on_level_finished)
	prepare_ui_for_level()

func prepare_ui_for_level():
	camera.set_drag_offset(Vector2(0, 0))
	$UiLayer/HudContainer.visible = true

func on_level_finished():
	prepare_report()
	is_level_finished = true
	$UiLayer/HudContainer.visible = false
	load_next_level()

func load_next_level():
	await transition_rect.fade_out()
	var next_scene = level.next_scene
	var need_stop_music = level.need_stop_music
	level.queue_free()
	level = null
	level_index += 1
	if need_stop_music:
		AudioController.stop_music()
	if levels.size() <= level_index:
		SceneSwitcher.change_scene_to_file(next_scene[0], next_scene[1])
	else:
		load_level(levels[level_index])
		transition_rect.fade_in()

func exit_levels():
	AudioController.stop_music()
	SceneSwitcher.change_scene_to_file("res://scenes/game/MainMenu/MainMenu.tscn")

func prepare_report():
	pass

func show_menu():
	if !get_tree().paused:
		get_tree().paused = true
		menu_layer.visible = true
		menu.init_modal()

func close_menu():
	menu_layer.visible = false
	get_tree().paused = false
