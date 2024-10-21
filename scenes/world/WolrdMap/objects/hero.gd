extends Node2D


@onready var path_follow = $PathFollow2D
var current_path: Path2D
var speed = 100  # Adjust as needed
var follow = false

func _process(delta):
	if follow:
		global_position = global_position.lerp(path_follow.global_position, delta * 5).ceil()

func navigate_to(path: Path2D, target: Vector2i):
	if path is Path2D:
		follow = true
		current_path = path
		path_follow.reparent(path)
		
		# Find the closest point on the path to the character
		var closest_offset = current_path.curve.get_closest_offset(current_path.to_local(global_position))
		path_follow.progress = closest_offset
		
		# Set the target to the POI's position on the path
		var target_offset = current_path.curve.get_closest_offset(current_path.to_local(target))
		_move_along_path(target_offset)

func _move_along_path(target_offset: float):
	var tween = create_tween()
	tween.tween_method(self._update_character_position, path_follow.progress, target_offset, 5.0)
	tween.finished.connect(func() :
		follow = false
		path_follow.reparent(self)
	)

func _update_character_position(new_offset: float):
	path_follow.progress = new_offset
