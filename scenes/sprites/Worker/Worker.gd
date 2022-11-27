class_name WorkerSprite
extends Node2D

var orientation: String = 'right'

@onready var sprite = $Sprite as AnimatedSprite2D
@onready var state_machine = $StateMachine as StateMachine


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_orientation(direction: String) -> void:
	if direction == 'right' || direction == 'left':
		orientation = direction
		sprite.flip_h = direction == 'left'

func set_state(state: String) -> void:
	state_machine.transition_to(state)
