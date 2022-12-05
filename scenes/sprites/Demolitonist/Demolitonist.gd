class_name DemolitonistSprite
extends Unit

# Called when the node enters the scene tree for the first time.
func _ready():
	sprite = $Sprite
	label = $Label
	init()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
