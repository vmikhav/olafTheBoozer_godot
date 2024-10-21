extends Node2D

enum Type {
	Wood, Iron, BronseCup, BronseTrophy, SilverCup, SilverTrophy, GoldCup, GoldTrophy,
}

const animations = {
	Type.Wood: 'wood', Type.Iron: 'iron',
	Type.BronseCup: 'bronse_cup', Type.BronseTrophy: 'bronse_trophy',
	Type.SilverCup: 'silver_cup', Type.SilverTrophy: 'silver_trophy',
	Type.GoldCup: 'gold_cup', Type.GoldTrophy: 'gold_trophy',
}

@export var type: Type = Type.Wood : set = _set_type
@onready var sprite = $Sprite as AnimatedSprite2D

var is_empty = false

# Called when the node enters the scene tree for the first time.
func _ready():
	_set_type(type)

func _set_type(new_type: Type):
	type = new_type
	if sprite:
		reset()

func drink():
	is_empty = true
	sprite.frame = 0
	modulate = Color8(255, 255, 255, 255)
	await get_tree().create_timer(0.1).timeout
	sprite.play()
	AudioController.play_sfx("dropdown_menu_drink")

func reset():
	is_empty = false
	modulate = Color8(0, 0, 0, 80)
	sprite.animation = animations[type]
	sprite.stop()
	sprite.frame = 2
