extends Node2D
class_name QuestHintSprite

@onready var sprite: Sprite2D = $Sprite2D

func set_animation(anim_name: String):
	$Sprite2D/AnimationPlayer.play(anim_name)

func set_icon(pos: int):
	var row = floori(pos / 10)
	var col = pos % 10
	sprite.region_rect = Rect2i(col * 8, row * 9, 8, 9)
