extends Node2D

@onready var shadow: AnimatedSprite2D = $Shadow
@onready var base: AnimatedSprite2D = $Base
@onready var body: AnimatedSprite2D = $Body
@onready var legs: AnimatedSprite2D = $Legs
@onready var shoes: AnimatedSprite2D = $Shoes
@onready var beard: AnimatedSprite2D = $Beard
@onready var hair: AnimatedSprite2D = $Hair


@onready var path_follow = $PathFollow2D
var current_path: Path2D
var speed = 40  # Adjust as needed
var follow = false
var orientation: StringName = "right"
var _last_position: Vector2
signal follow_comlete

func _process(delta):
	if follow:
		var new_position = global_position

		# Check movement direction only
		if new_position.x < _last_position.x and orientation == "right":
			orientation = "left"
			flip(true)
		elif new_position.x > _last_position.x and orientation == "left":
			orientation = "right"
			flip(false)

		_last_position = new_position

func navigate_to(path: Path2D, target: Vector2i):
	if path is Path2D:
		follow = true
		play("walk")
		current_path = path
		path_follow.reparent(path)
		
		# Find the closest point on the path to the character
		var closest_offset = current_path.curve.get_closest_offset(current_path.to_local(global_position))
		path_follow.progress = closest_offset
		
		# Set the target to the POI's position on the path
		var target_offset = current_path.curve.get_closest_offset(current_path.to_local(target))
		_move_along_path(target_offset)

func _move_along_path(target_offset: float):
	var curve := current_path.curve
	_last_position = global_position
	var start_distance := curve.get_closest_offset(current_path.to_local(global_position))
	var end_distance := target_offset
	var duration = abs(start_distance - end_distance) / speed
	
	var tween = create_tween()
	tween.tween_method(
		func(distance: float):
			var pos = curve.sample_baked(distance)
			global_position = current_path.to_global(pos)
	, start_distance, end_distance, duration)
	tween.finished.connect(func() :
		follow = false
		path_follow.reparent(self)
		follow_comlete.emit()
		play("idle")
	)

func _update_character_position(new_offset: float):
	path_follow.progress = new_offset

func play(name: StringName = &"", custom_speed: float = 1.0, from_end: bool = false):
	shadow.play(name, custom_speed, from_end)
	base.play(name, custom_speed, from_end)
	body.play(name, custom_speed, from_end)
	legs.play(name, custom_speed, from_end)
	shoes.play(name, custom_speed, from_end)
	beard.play(name, custom_speed, from_end)
	hair.play(name, custom_speed, from_end)

func flip(_value: bool):
	shadow.flip_h = _value
	base.flip_h = _value
	body.flip_h = _value
	legs.flip_h = _value
	shoes.flip_h = _value
	beard.flip_h = _value
	hair.flip_h = _value
