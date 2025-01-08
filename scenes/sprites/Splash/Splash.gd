extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	sprite.play("default")
	sprite.animation_finished.connect(func() :
		queue_free()
	)
