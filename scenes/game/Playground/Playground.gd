extends Node2D

@onready var camera = $TouchCamera as TouchCamera
@onready var nav_buttons = $UiLayer/Container/VBoxContainer/HBoxContainer2/NavButtons
@onready var progress_panel = $UiLayer/Container/VBoxContainer/HBoxContainer/MarginContainer2/MarginContainer/ProgressPanel
@onready var restart_button = $UiLayer/Container/VBoxContainer/HBoxContainer/MarginContainer3/TextureButton as TextureButton
@onready var transition_rect = $UiLayer/SceneTransitionRect
var level: BaseLevel

var level_index = 0
var levels = [
	"Tutorial0",
]

# Called when the node enters the scene tree for the first time.
func _ready():
	load_level(levels[level_index])
	nav_buttons.navigate.connect(move_hero)
	restart_button.pressed.connect(restart)
	transition_rect.fade_in()


func restart():
	await transition_rect.fade_out()
	level.restart()
	transition_rect.fade_in()

func move_hero(direction: String):
	if direction == "left":
		level.navigate(TileSet.CELL_NEIGHBOR_LEFT_SIDE)
	if direction == "right":
		level.navigate(TileSet.CELL_NEIGHBOR_RIGHT_SIDE)
	if direction == "up":
		level.navigate(TileSet.CELL_NEIGHBOR_TOP_SIDE)
	if direction == "down":
		level.navigate(TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)

func load_level(name: String):
	var pack = load("res://scenes/levels/" + name + "/" + name + ".tscn") as PackedScene
	level = pack.instantiate() as BaseLevel
	add_child(level)
	camera.target = level.hero
	camera.go_to(level.hero.position, true)
	level.playback_finished.connect(load_next_level)
	progress_panel.set_items_count(level.level_items_count)
	progress_panel.set_ghosts_count(level.ghosts_count)
	level.items_progress_signal.connect(progress_panel.items_progress)
	level.ghosts_progress_signal.connect(progress_panel.ghosts_progress)

func load_next_level():
	await transition_rect.fade_out()
	level_index += 1
	if levels.size() <= level_index:
		SceneSwitcher.change_scene_to_file("res://scenes/game/MainMenu/MainMenu.tscn")
	else:
		load_level(levels[level_index])
		transition_rect.fade_in()
