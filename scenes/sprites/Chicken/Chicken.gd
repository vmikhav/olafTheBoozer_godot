extends Node2D

@onready var sprite: AnimatedSprite2D = $Sprite

func hit(number: int):
	if number <= 2:
		AudioController.play_sfx("chicken")
		sprite.play("hit")
		await sprite.animation_finished
		sprite.play("default")
	else:
		sprite.flip_h = false
		
