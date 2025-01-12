extends Node2D

@onready var sprite: Sprite2D = $Sprite2D


func set_icon(pos: int):
	var row = floori(pos / 10)
	var col = pos % 10
	sprite.region_rect = Rect2i(col * 16, row * 16, 16, 16)
