class_name Unit
extends Node2D

var orientation: String = 'right'
var sprite: AnimatedSprite2D
@onready var sounds_map = SoundsMap.new() as SoundsMap
var can_produce_sounds = true
var available_sounds = ["hiccup", "hrrng", "groan"]
var last_sound = -1


func init():
	get_tree().create_timer(3).timeout.connect(play_idle_sound)


func play_idle_sound():
	if can_produce_sounds:
		var sound_index = randi_range(0, available_sounds.size()-1)
		if last_sound == sound_index:
			sound_index = randi_range(0, available_sounds.size()-1)
		var sound = available_sounds[sound_index]
		last_sound = sound_index
		play_sfx(sound)
		get_tree().create_timer(randf_range(4, 10)).timeout.connect(play_idle_sound)

func make_ghost() -> void:
	sprite.modulate = Color8(100, 200, 255, 160)
	set_orientation("left" if randi_range(0, 1) else "right")
	can_produce_sounds = false

func set_orientation(direction: String) -> void:
	if direction == 'right' || direction == 'left':
		orientation = direction
		sprite.flip_h = direction == 'left'

func hit():
	sprite.play("hit")
	await sprite.animation_finished
	sprite.play("idle")

func play_sfx(name: String):
	var player = AudioStreamPlayer.new()
	player.bus = "SFX"
	if name == "vomit":
		player.volume_db = -3
	player.stream = sounds_map.sounds[name]
	add_child(player)
	player.play()
	await player.finished
	player.queue_free()
