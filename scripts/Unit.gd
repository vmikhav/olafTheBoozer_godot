class_name Unit
extends Node2D


var orientation: String = 'right'
var sprite: AnimatedSprite2D
var emote: Sprite2D
var can_produce_sounds = true
var available_sounds = ["hiccup", "hrrng", "groan"]
var last_sound = -1
var mode: String = "demolitonist": set = set_mode 

func _ready():
	sprite.play(mode + "_idle")

func set_mode(params):
	mode = params[0]
	sprite.play(mode + "_idle")
	var sounds_old = can_produce_sounds
	can_produce_sounds = params[1]
	if not sounds_old and can_produce_sounds:
		play_idle_sound()

func init():
	init_sounds()

func init_sounds():
	get_tree().create_timer(randf_range(2.5, 4), false).timeout.connect(play_idle_sound)

func play_idle_sound():
	if can_produce_sounds:
		var sound_index = randi_range(0, available_sounds.size()-1)
		if last_sound == sound_index:
			sound_index = randi_range(0, available_sounds.size()-1)
		var sound = available_sounds[sound_index]
		last_sound = sound_index
		emote.visible = true
		emote.modulate.a8 = 0
		var tween = create_tween()
		tween.tween_property(emote, "modulate", Color8(255, 255, 255, 255), 0.25)
		tween.tween_property(emote, "modulate", Color8(255, 255, 255, 255), 0.1)
		tween.tween_property(emote, "modulate", Color8(255, 255, 255, 0), 0.4)
		tween.tween_callback(func():
			emote.visible = false
		)
		AudioController.play_sfx(sound)
		get_tree().create_timer(randf_range(4, 10), false).timeout.connect(play_idle_sound)

func make_ghost() -> void:
	sprite.modulate = Color8(100, 200, 255, 160)
	set_orientation("left" if randi_range(0, 1) else "right")
	can_produce_sounds = false

func set_orientation(direction: String) -> void:
	if direction == 'right' || direction == 'left':
		orientation = direction
		sprite.flip_h = direction == 'left'

func hit():
	sprite.play(mode + "_hit")
	await sprite.animation_finished
	sprite.play(mode + "_idle")


