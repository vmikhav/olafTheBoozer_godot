class_name Unit
extends Node2D

const MOVE_DURATION = 0.12

const ghost_colors = {
	LevelDefinitions.GhostType.MEMORY: Color8(100, 200, 255, 255),
	LevelDefinitions.GhostType.ENEMY: Color8(255, 210, 0, 255),
	LevelDefinitions.GhostType.ENEMY_SPAWN: Color8(255, 100, 100, 255),
}

var orientation: String = 'right'
var sprite: AnimatedSprite2D
var emote: Sprite2D
var emote_small: Sprite2D
var emote_small_overlay: Sprite2D
var can_produce_sounds = true
var available_sounds = ["olaf_hiccup_idle"]
var last_sound = -1
var mode: String = LevelDefinitions.UnitTypeName[LevelDefinitions.UnitType.DEMOLITONIST]
var move_tween: Tween
var emote_tween: Tween
var emote_small_tween: Tween
var is_dead := false
var is_moving := false
var is_ghost := false
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
	emote_small.visible = false
	is_ghost = false
	var sounds_old = can_produce_sounds
	can_produce_sounds = params[1]
	if not sounds_old and can_produce_sounds:
		play_idle_sound()

func init():
	init_sounds()
	sprite.material.set_shader_parameter("status_intensity", 0.0)
	sprite.material.set_shader_parameter("transparency", 1.0)

func init_sounds():
	get_tree().create_timer(randf_range(2.5, 4), false).timeout.connect(play_idle_sound)

func play_idle_sound():
	if can_produce_sounds and not emote.visible:
		var sound_index = randi_range(0, available_sounds.size()-1)
		if last_sound == sound_index:
			sound_index = randi_range(0, available_sounds.size()-1)
		var sound = available_sounds[sound_index]
		last_sound = sound_index
		if emote_tween and emote_tween.is_running():
			emote_tween.stop()
		emote.visible = true
		emote.modulate.a8 = 0
		emote.region_rect = Rect2i(Vector2i(128, 16), Vector2i(16, 16))
		emote_tween = create_tween()
		emote_tween.tween_property(emote, "modulate", Color8(255, 255, 255, 255), 0.25)
		emote_tween.tween_property(emote, "modulate", Color8(255, 255, 255, 255), 0.1)
		emote_tween.tween_property(emote, "modulate", Color8(255, 255, 255, 0), 0.4)
		emote_tween.tween_callback(func():
			emote.visible = false
		)
		AudioController.play_sfx(sound)
		get_tree().create_timer(randf_range(4, 10), false).timeout.connect(play_idle_sound)

func play_emote(x: int, y: int, duration: float = 0.6, pause: float = 0.05):
	if emote_tween and emote_tween.is_running():
		emote_tween.stop()
	emote.visible = true
	emote.modulate.a8 = 0
	emote.region_rect = Rect2i(Vector2i(x*16, y*16), Vector2i(16, 16))
	emote_tween = create_tween()
	emote_tween.tween_property(emote, "modulate", Color8(255, 255, 255, 0), pause)
	emote_tween.tween_property(emote, "modulate", Color8(255, 255, 255, 255), 0.1)
	emote_tween.tween_property(emote, "modulate", Color8(255, 255, 255, 255), duration)
	emote_tween.tween_property(emote, "modulate", Color8(255, 255, 255, 0), 0.1)
	emote_tween.tween_callback(func():
		emote.visible = false
	)

func reset_emote() -> void:
	if emote_tween and emote_tween.is_running():
		emote_tween.stop()
	emote.visible = false

func reset_emote_small() -> void:
	if emote_small_tween and emote_small_tween.is_running():
		emote_small_tween.stop()
	emote_small.visible = false
	emote_small_overlay.visible = false

func make_ghost(type: LevelDefinitions.GhostType = LevelDefinitions.GhostType.MEMORY) -> void:
	is_ghost = true
	sprite.material.set_shader_parameter("status_color", ghost_colors[type])
	sprite.material.set_shader_parameter("status_intensity", 1.0)
	sprite.material.set_shader_parameter("transparency", 0.85)
	set_orientation("left" if randi_range(0, 1) else "right")
	can_produce_sounds = false
	if type == LevelDefinitions.GhostType.ENEMY:
		is_dead = true
		emote_small.visible = true
		emote_small.region_rect = Rect2i(Vector2i(40, 27), Vector2i(8, 9))
	if type == LevelDefinitions.GhostType.ENEMY_SPAWN:
		emote_small.visible = true
		emote_small.region_rect = Rect2i(Vector2i(48, 27), Vector2i(8, 9))

func make_dead():
	can_produce_sounds = false
	is_dead = true
	sprite.play(mode + "_idle_dead")

func make_follower():
	emote_small.visible = false
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

func hit(direction: TileSet.CellNeighbor = TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER):
	can_reset_animation = false
	sprite.play(mode + "_hit")
	
	var show_emote = false
	match direction:
		TileSet.CELL_NEIGHBOR_LEFT_SIDE:
			show_emote = true
			emote_small.region_rect = Rect2i(Vector2i(0, 27), Vector2i(8, 9))
		TileSet.CELL_NEIGHBOR_RIGHT_SIDE:
			show_emote = true
			emote_small.region_rect = Rect2i(Vector2i(8, 27), Vector2i(8, 9))
		TileSet.CELL_NEIGHBOR_TOP_SIDE:
			show_emote = true
			emote_small.region_rect = Rect2i(Vector2i(16, 27), Vector2i(8, 9))
		TileSet.CELL_NEIGHBOR_BOTTOM_SIDE:
			show_emote = true
			emote_small.region_rect = Rect2i(Vector2i(24, 27), Vector2i(8, 9))
	
	if show_emote:
		emote_small.modulate.a8 = 0
		emote_small.visible = true
		emote_small_tween = create_tween()
		emote_small_tween.tween_property(emote_small, "modulate", Color8(255, 255, 255, 255), 0.1)
		emote_small_tween.tween_property(emote_small, "modulate", Color8(255, 255, 255, 255), 0.1)
		emote_small_tween.tween_callback(func():
			emote_small_overlay.visible = true
		)
		emote_small_tween.tween_property(emote_small, "modulate", Color8(255, 255, 255, 0), 0.15)
		emote_small_tween.tween_callback(func():
			emote_small.visible = false
			emote_small_overlay.visible = false
		)
	
	await sprite.animation_finished
	sprite.play(mode + "_idle")

func repair():
	can_reset_animation = false
	sprite.play(mode + "_repair_2")
	await sprite.animation_finished
	sprite.play(mode + "_idle")

func move(new_position: Vector2, animation: String = "walk") -> void:
	var diff = abs(expected_position.x - new_position.x) + abs(expected_position.y - new_position.y)
	var animation_suffix := "_walk"
	var move_duration := MOVE_DURATION
	var can_display_animation:bool = diff == 16
	if animation == "slide":
		can_display_animation = true
		animation_suffix = "_hit"
		move_duration = maxf(MOVE_DURATION * diff / 24, MOVE_DURATION)
	if can_display_animation:
		can_reset_animation = true
		if !is_dead and !is_moving:
			sprite.play(mode + animation_suffix)
		if move_tween and move_tween.is_running():
			move_tween.stop()
	
		# Create and start new movement tween
		move_tween = create_tween()
		move_tween.tween_property(self, "position", new_position, move_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
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
