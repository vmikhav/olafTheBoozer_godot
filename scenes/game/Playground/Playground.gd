extends Node2D

@onready var camera = $TouchCamera as TouchCamera
var level: BaseLevel

# Called when the node enters the scene tree for the first time.
func _ready():
	load_level("Tutorial0")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event is InputEventKey: 
		if event.is_action_released("ui_left"):
			level.navigate(TileSet.CELL_NEIGHBOR_LEFT_SIDE)
		if event.is_action_released("ui_right"):
			level.navigate(TileSet.CELL_NEIGHBOR_RIGHT_SIDE)
		if event.is_action_released("ui_up"):
			level.navigate(TileSet.CELL_NEIGHBOR_TOP_SIDE)
		if event.is_action_released("ui_down"):
			level.navigate(TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)


func load_level(name: String):
	var pack = load("res://scenes/levels/" + name + "/" + name + ".tscn") as PackedScene
	level = pack.instantiate() as BaseLevel
	add_child(level)
	camera.position = level.hero_position
