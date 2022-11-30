extends Node2D

@onready var camera = $TouchCamera as TouchCamera
@onready var nav_buttons = $UiLayer/Container/VBoxContainer/HBoxContainer2/NavButtons
@onready var restart_button = $UiLayer/Container/VBoxContainer/HBoxContainer/MarginContainer3/TextureButton as TextureButton
var level: BaseLevel

# Called when the node enters the scene tree for the first time.
func _ready():
	load_level("Tutorial0")
	nav_buttons.navigate.connect(move_hero)
	restart_button.pressed.connect(level.restart)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func move_hero(direction: String):
	if direction == "left":
		level.navigate(TileSet.CELL_NEIGHBOR_LEFT_SIDE)
	if direction == "right":
		level.navigate(TileSet.CELL_NEIGHBOR_RIGHT_SIDE)
	if direction == "up":
		level.navigate(TileSet.CELL_NEIGHBOR_TOP_SIDE)
	if direction == "down":
		level.navigate(TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)

#func _input(event):
#	if event is InputEventKey: 
#		if event.is_action_released("ui_left"):
#			level.navigate(TileSet.CELL_NEIGHBOR_LEFT_SIDE)
#		if event.is_action_released("ui_right"):
#			level.navigate(TileSet.CELL_NEIGHBOR_RIGHT_SIDE)
#		if event.is_action_released("ui_up"):
#			level.navigate(TileSet.CELL_NEIGHBOR_TOP_SIDE)
#		if event.is_action_released("ui_down"):
#			level.navigate(TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)


func load_level(name: String):
	var pack = load("res://scenes/levels/" + name + "/" + name + ".tscn") as PackedScene
	level = pack.instantiate() as BaseLevel
	add_child(level)
	camera.target = level.hero
	camera.go_to(level.hero.position, true)
