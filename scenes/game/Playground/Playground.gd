extends Node2D

@onready var camera = $TouchCamera as TouchCamera
@onready var nav_buttons = $UiLayer/HudContainer/VBoxContainer/HBoxContainer2/NavButtons
@onready var progress_panel = $UiLayer/HudContainer/VBoxContainer/HBoxContainer/MarginContainer2/MarginContainer/ProgressPanel
@onready var restart_button = $UiLayer/HudContainer/VBoxContainer/HBoxContainer/MarginContainer3/TextureButton as TextureButton
@onready var transition_rect = $UiLayer/SceneTransitionRect
@onready var summary_container = $UiLayer/SummaryContainer
@onready var nav_controller = $NavController
var level: BaseLevel

var level_index = 0
var levels = [
	"Tutorial0",
	"Kitchen",
	"Library",
]

# Called when the node enters the scene tree for the first time.
func _ready():
	load_level(levels[level_index])
	nav_buttons.actions.connect(imitate_input)
	nav_controller.actions.connect(move_hero)
	restart_button.pressed.connect(restart)
	summary_container.restart.connect(restart)
	summary_container.next.connect(load_next_level)
	transition_rect.fade_in()

func imitate_input(input: InputEvent):
	nav_controller._input(input)

func restart():
	await transition_rect.fade_out()
	level.restart()
	prepare_ui_for_level()
	transition_rect.fade_in()

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
	var pack = load("res://scenes/levels/" + level_name + "/" + level_name + ".tscn") as PackedScene
	level = pack.instantiate() as BaseLevel
	add_child(level)
	camera.target = level.hero
	camera.go_to(level.hero.position, true)
	level.level_finished.connect(on_level_finished)
	progress_panel.set_items_count(level.level_items_count)
	progress_panel.set_ghosts_count(level.ghosts_count)
	level.items_progress_signal.connect(progress_panel.items_progress)
	level.ghosts_progress_signal.connect(progress_panel.ghosts_progress)
	prepare_ui_for_level()

func prepare_ui_for_level():
	camera.drag_top_margin = 0.4
	camera.drag_bottom_margin = 0.4
	$UiLayer/HudContainer.visible = true
	summary_container.hide(false)

func on_level_finished():
	$UiLayer/HudContainer.visible = false
	summary_container.show()
	camera.drag_top_margin = 0
	camera.drag_bottom_margin = 0.6

func load_next_level():
	await summary_container.hide_panel()
	level.is_history_replay = false
	await transition_rect.fade_out()
	level.queue_free()
	level_index += 1
	if levels.size() <= level_index:
		SceneSwitcher.change_scene_to_file("res://scenes/game/MainMenu/MainMenu.tscn")
	else:
		load_level(levels[level_index])
		transition_rect.fade_in()
