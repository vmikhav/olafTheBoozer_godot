extends Node2D

signal finished
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var animations := ["364", "298", "288"]

func _ready() -> void:
	var animation = animations.pick_random()
	if animation == "288":
		sprite.position.y -= 5
	sprite.play(animation)
	sprite.animation_finished.connect(func() :
		finished.emit()
		queue_free()
	)
