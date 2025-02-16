class_name Unit
extends Node2D

const MOVE_DURATION = 0.12

const ghost_colors = {
	LevelDefinitions.GhostType.MEMORY: Color8(100, 200, 255, 160),
	LevelDefinitions.GhostType.ENEMY: Color8(200, 200, 100, 160),
	LevelDefinitions.GhostType.ENEMY_SPAWN: Color8(255, 100, 100, 160),
}

var orientation: String = 'right'
var sprite: AnimatedSprite2D
var emote: Sprite2D
var can_produce_sounds = true
var available_sounds = ["olaf_hiccup_idle"]
var last_sound = -1
var mode: String = LevelDefinitions.UnitTypeName[LevelDefinitions.UnitType.DEMOLITONIST]
var move_tween: Tween
var is_dead := false
var is_moving := false
var can_reset_animation := false
var expected_position: Vector2

func _ready():
	sprite.play(mode + "_idle")
	move_tween = create_tween()
	move_tween.stop()
	expected_position = position

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
	if LevelDefinitions.Demons.has(mode) && type == LevelDefinitions.GhostType.ENEMY:
		sprite.modulate = Color8(150, 255, 100, 200)
	set_orientation("left" if randi_range(0, 1) else "right")
	can_produce_sounds = false
	if type == LevelDefinitions.GhostType.ENEMY:
		is_dead = true

func make_dead():
	can_produce_sounds = false
	is_dead = true
	sprite.play(mode + "_idle_dead")

func make_follower():
	sprite.play(mode + "_die", -1.5, true)
	await sprite.animation_finished
	sprite.play(mode + ("_walk" if is_moving else "_idle"))
	is_dead = false
	

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
	can_reset_animation = false
	sprite.play(mode + "_hit")
	await sprite.animation_finished
	sprite.play(mode + "_idle")

func move(new_position: Vector2) -> void:
	var diff = abs(expected_position.x - new_position.x) + abs(expected_position.y - new_position.y)
	if diff == 16:
		can_reset_animation = true
		if !is_dead and !is_moving:
			sprite.play(mode + "_walk")
		if move_tween and move_tween.is_running():
			move_tween.stop()
	
		# Create and start new movement tween
		move_tween = create_tween()
		move_tween.tween_property(self, "position", new_position, MOVE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		move_tween.finished.connect(_on_move_finished)
		is_moving = true
	else:
		position = new_position
	expected_position = new_position

func _on_move_finished():
	is_moving = false
	await get_tree().create_timer(0.15).timeout
	if !is_dead and !is_moving and can_reset_animation:
		sprite.play(mode + "_idle")
