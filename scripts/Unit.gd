class_name Unit
extends Node2D

var orientation: String = 'right'
var sprite: AnimatedSprite2D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func make_ghost() -> void:
	$Sprite.modulate = Color8(100, 200, 255, 160)
	set_orientation("left" if randi_range(0, 1) else "right")

func set_orientation(direction: String) -> void:
	if direction == 'right' || direction == 'left':
		orientation = direction
		sprite.flip_h = direction == 'left'

func hit():
	sprite.play("hit")
	await sprite.animation_finished
	sprite.play("idle")
