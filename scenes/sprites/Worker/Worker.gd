class_name WorkerSprite
extends Unit

@onready var state_machine = $StateMachine as StateMachine

# Called when the node enters the scene tree for the first time.
func _ready():
	sprite = $Sprite


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func set_state(state: String) -> void:
	state_machine.transition_to(state)
