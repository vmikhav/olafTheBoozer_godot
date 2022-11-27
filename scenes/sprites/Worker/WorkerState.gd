# Boilerplate class to get full autocompletion and type checks for the `player` when coding the player's states.
# Without this, we have to run the game to see typos and other errors the compiler could otherwise catch while scripting.
class_name WorkerState
extends State

var worker: WorkerSprite


func _ready() -> void:
	await owner.ready
	worker = owner as WorkerSprite
	assert(worker != null)
