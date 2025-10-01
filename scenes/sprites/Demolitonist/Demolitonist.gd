class_name DemolitonistSprite
extends Unit

# Called when the node enters the scene tree for the first time.
func _ready():
	sprite = $Sprite
	emote = $Emote
	emote2 = $Emote2
	init()
