extends Node2D

@onready var emote = $Character/Emote
@onready var character = $Character

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func run():
	emote.region_rect = Rect2(Vector2(16, 16), Vector2(16, 16))
	await show_emote(0.5)
	await show_emote(0.5)
	character.play("default")
	await character.animation_finished
	character.play("idle")
	emote.region_rect = Rect2(Vector2(128, 16), Vector2(16, 16))
	await show_emote(1.5, 0.25)
	emote.region_rect = Rect2(Vector2(144, 32), Vector2(16, 16))
	await show_emote(1.5, 0.25)
	emote.region_rect = Rect2(Vector2(144, 0), Vector2(16, 16))
	character.flip_h = true
	await show_emote(1.5, 1)
	emote.region_rect = Rect2(Vector2(128, 0), Vector2(16, 16))
	character.flip_h = false
	await show_emote(1.5)

func show_emote(duration: float = 0.1, delay: float = 0) -> Signal:
	emote.modulate.a8 = 0
	var tween = create_tween()
	tween.tween_property(emote, "modulate", Color8(255, 255, 255, 255), 0.25)
	tween.tween_interval(duration)
	tween.tween_property(emote, "modulate", Color8(255, 255, 255, 0), 0.4)
	tween.tween_interval(delay)
	return tween.finished
