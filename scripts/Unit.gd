class_name Unit
extends Node2D

const ghost_colors = {
	LevelDefinitions.GhostType.MEMORY: Color8(100, 200, 255, 160),
	LevelDefinitions.GhostType.ENEMY: Color8(255, 100, 100, 160),
	LevelDefinitions.GhostType.ENEMY_SPAWN: Color8(200, 200, 100, 160),
}

var orientation: String = 'right'
var sprite: AnimatedSprite2D
var emote: Sprite2D
var can_produce_sounds = true
var available_sounds = ["hiccup", "hrrng", "groan"]
var last_sound = -1
var mode: String = "demolitonist"

func _ready():
	sprite.play(mode + "_idle")

func set_mode(params):
	mode = params[0]
	sprite.play(mode + "_idle")
	emote.visible = false
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

func make_ghost(type: LevelDefinitions.GhostType = LevelDefinitions.GhostType.MEMORY) -> void:
	sprite.modulate = ghost_colors[type]
	set_orientation("left" if randi_range(0, 1) else "right")
	can_produce_sounds = false

func make_follower():
	sprite.play(mode + "_die", -1.5, true)
	await sprite.animation_finished
	sprite.play(mode + "_idle")

func die(with_animation: bool):
	if with_animation:
		sprite.play(mode + "_die", 1.5)
		await sprite.animation_finished
	queue_free()

func set_orientation(direction: String) -> void:
	if direction == 'right' || direction == 'left':
		orientation = direction
		sprite.flip_h = direction == 'left'

func hit():
	sprite.play(mode + "_hit")
	await sprite.animation_finished
	sprite.play(mode + "_idle")


