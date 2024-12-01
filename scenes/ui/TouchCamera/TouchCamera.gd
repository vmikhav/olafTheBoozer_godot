class_name TouchCamera
extends Camera2D

@export_group("Input Sensitivity")
@export var mouse_sensitivity: float = 1.0
@export var touch_sensitivity: float = 1.0
@export var wheel_zoom_sensitivity: float = 0.1
@export var pinch_zoom_sensitivity: float = 0.02

@export_group("Zoom Settings")
@export var min_zoom: float = 1
@export var max_zoom: float = 4
@export var zoom_speed: float = 0.1
@export var zoom_sensitivity: float = 400

@export_group("Target Following")
@export var target_return_enabled: bool = true
@export var target_return_rate: float = 0.02
@export var target_offset: Vector2 = Vector2.ZERO
@export var target_follow_delay: float = .5
@export var pixel_perfect: bool = true

@export_group("Camera Bounds")
#@export var camera_bounds: Rect2 = Rect2(-1000, -1000, 2000, 2000)
@export var elastic_bounds: bool = true
@export var elastic_force: float = 0.1

@export_group("Movement Settings")
@export var can_restore_drag: bool = true
@export var ignore_input: bool = false
@export var use_momentum: bool = true
@export var momentum_friction: float = 0.9
@export var zoom_dependent_speed: bool = true

# Internal variables
@onready var drag_enabled = self.drag_horizontal_enabled
@onready var target_zoom: float = self.zoom.x

var timer: Timer
var events = {}
var last_drag_distance: float = 0
var after_zoom: bool = false
var touch_events: bool = false
var timer_flag: bool = true
var target: Node2D
var zoom_tween: Tween
var smoothing_tween: Tween
var last_target_pos: Vector2
var teleport_threshold: float = 64.0  # Distance in pixels to consider as teleport
var default_drag_margins: Vector4  # left, right, top, bottom
var original_drag_margins: Vector4  # left, right, top, bottom
var is_adjusting_margins: bool = false

var velocity: Vector2 = Vector2.ZERO
var last_position: Vector2 = Vector2.ZERO
var elastic_offset: Vector2 = Vector2.ZERO
var base_movement_speed: float = 2.0
var min_movement_threshold: float = 0.001  # Prevents micro-movements
var max_movement_speed: float = 10.0  # Prevents too fast movement

func _ready() -> void:
	setup_timer()
	position_smoothing_enabled = true
	
	default_drag_margins = Vector4(
		drag_left_margin,
		drag_right_margin,
		drag_top_margin,
		drag_bottom_margin
	)
	
	original_drag_margins = Vector4(
		drag_left_margin,
		drag_right_margin,
		drag_top_margin,
		drag_bottom_margin
	)
	
	# Enable pixel-perfect rendering if needed
	if pixel_perfect:
		position_smoothing_enabled = false
		set_process_mode(Node.PROCESS_MODE_PAUSABLE)
	
	if target:
		last_target_pos = target.position

func setup_timer() -> void:
	timer = Timer.new()
	timer.wait_time = target_follow_delay
	timer.one_shot = true
	add_child(timer)
	timer.stop()
	timer.timeout.connect(func(): timer_flag = true)

func _physics_process(delta: float) -> void:
	if use_momentum:
		apply_momentum(delta)
	
	if elastic_bounds:
		apply_elastic_bounds(delta)
	
	if target and target_return_enabled and timer_flag:# and events.size() == 0:
		follow_target(delta)
	
	if pixel_perfect:
		position = position.round()

func apply_momentum(delta: float) -> void:
	if velocity.length_squared() > 0.1:
		var movement = velocity * delta
		position += movement
		velocity *= momentum_friction
	else:
		velocity = Vector2.ZERO

func apply_elastic_bounds(delta: float) -> void:
	var screen_size = get_viewport_rect().size
	var half_width = (screen_size.x / 2) / zoom.x
	var half_height = (screen_size.y / 2) / zoom.y
	
	var min_x = limit_left + half_width
	var max_x = limit_right - half_width
	var min_y = limit_top + half_height
	var max_y = limit_bottom - half_height
	
	if position.x < min_x:
		elastic_offset.x += (min_x - position.x) * elastic_force * delta
	elif position.x > max_x:
		elastic_offset.x += (max_x - position.x) * elastic_force * delta
	
	if position.y < min_y:
		elastic_offset.y += (min_y - position.y) * elastic_force * delta
	elif position.y > max_y:
		elastic_offset.y += (max_y - position.y) * elastic_force * delta
	
	elastic_offset *= 0.9
	position += elastic_offset

func follow_target(delta: float) -> void:
	if not target:
		return
	
	var target_pos = target.position + target_offset
	# Check if target has "teleported"
	if target_pos.distance_to(last_target_pos) > teleport_threshold:
		# Target has moved significantly, treat as teleport
		reduce_drag_margins()
	
	last_target_pos = target.position
	
	# Get the screen dimensions
	var screen_size = get_viewport_rect().size
	var half_width = (screen_size.x / 2) / zoom.x
	var half_height = (screen_size.y / 2) / zoom.y
	
	# Calculate distance to edges as a percentage
	var left_distance = (target_pos.x - (position.x - half_width)) / screen_size.x
	var right_distance = ((position.x + half_width) - target_pos.x) / screen_size.x
	var top_distance = (target_pos.y - (position.y - half_height)) / screen_size.y
	var bottom_distance = ((position.y + half_height) - target_pos.y) / screen_size.y
	
	# Adjust margins based on proximity to edges
	var edge_threshold = 0.1  # Start reducing margins when target is within 20% of edge
	var was_adjusting = is_adjusting_margins
	is_adjusting_margins = false
	
	if left_distance < edge_threshold:
		drag_left_margin = lerp(0.0, default_drag_margins.x, left_distance / edge_threshold)
		is_adjusting_margins = true
	elif right_distance < edge_threshold:
		drag_right_margin = lerp(0.0, default_drag_margins.y, right_distance / edge_threshold)
		is_adjusting_margins = true
	
	if top_distance < edge_threshold:
		drag_top_margin = lerp(0.0, default_drag_margins.z, top_distance / edge_threshold)
		is_adjusting_margins = true
	elif bottom_distance < edge_threshold:
		drag_bottom_margin = lerp(0.0, default_drag_margins.w, bottom_distance / edge_threshold)
		is_adjusting_margins = true
	
	# Restore margins if we're no longer near edges
	if was_adjusting and !is_adjusting_margins:
		restore_drag_margins()
	
	# Normal following behavior
	if position.distance_squared_to(target_pos) < 1:
		position = target_pos
		if can_restore_drag:
			restore_drag()
	else:
		var new_pos = position.lerp(target_pos, target_return_rate)
		position = clamp_position(new_pos)

func clamp_position(pos: Vector2) -> Vector2:
	var screen_size = get_viewport_rect().size
	var half_width = (screen_size.x / 2) / zoom.x
	var half_height = (screen_size.y / 2) / zoom.y
	
	# Add some margin to prevent the target from getting too close to the edge
	var margin = Vector2(half_width * 0.02, half_height * 0.02)
	
	var min_x = limit_left + half_width - margin.x
	var max_x = limit_right - half_width + margin.x
	var min_y = limit_top + half_height - margin.y
	var max_y = limit_bottom - half_height + margin.y
	
	# Only clamp if limits are set
	var clamped_x = pos.x
	var clamped_y = pos.y
	
	if limit_left < limit_right:  # Only clamp if horizontal limits are valid
		clamped_x = clamp(pos.x, min_x, max_x)
	
	if limit_top < limit_bottom:  # Only clamp if vertical limits are valid
		clamped_y = clamp(pos.y, min_y, max_y)
	
	return Vector2(clamped_x, clamped_y)

func reduce_drag_margins() -> void:
	# Reduce all margins to center the target
	drag_left_margin = default_drag_margins.x * 0.2
	drag_right_margin = default_drag_margins.y * 0.2
	drag_top_margin = default_drag_margins.z * 0.2
	drag_bottom_margin = default_drag_margins.w * 0.2

func restore_drag_margins() -> void:
	# Restore original margins
	drag_left_margin = default_drag_margins.x
	drag_right_margin = default_drag_margins.y
	drag_top_margin = default_drag_margins.z
	drag_bottom_margin = default_drag_margins.w

func _unhandled_input(event: InputEvent) -> void:
	if ignore_input:
		return
	
	if handle_touch_input(event) or handle_mouse_input(event):
		timer_flag = false
		timer.start(3)

func handle_touch_input(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		handle_screen_touch(event)
		return true
	elif event is InputEventScreenDrag:
		handle_screen_drag(event)
		return true
	return false

func handle_mouse_input(event: InputEvent) -> bool:
	if not touch_events:
		if event is InputEventMouseButton:
			handle_mouse_button(event)
			return true
		elif event is InputEventMouseMotion:
			handle_mouse_motion(event)
			return true
	return false

func handle_screen_touch(event: InputEventScreenTouch) -> void:
	touch_events = true
	if event.pressed:
		events[event.index] = event
		after_zoom = false
		velocity = Vector2.ZERO
		if events.size() == 1:
			disable_drag()
			last_position = event.position
		else:
			last_drag_distance = events[0].position.distance_squared_to(events[1].position)
	else:
		events.erase(event.index)
		handle_touch_release()

func handle_screen_drag(event: InputEventScreenDrag) -> void:
	events[event.index] = event
	if events.size() == 1:
		handle_single_finger_drag(event)
	elif events.size() == 2:
		handle_pinch_zoom()

func handle_single_finger_drag(event: InputEventScreenDrag) -> void:
	var movement_speed = base_movement_speed * touch_sensitivity
	if zoom_dependent_speed:
		movement_speed /= zoom.x
	
	# Clamp movement speed
	movement_speed = clamp(movement_speed, min_movement_threshold, max_movement_speed)
	
	var relative = event.relative.rotated(rotation)
	var movement = (relative * movement_speed) / zoom.x
	
	if movement.length_squared() > min_movement_threshold:
		if after_zoom:
			after_zoom = false
		else:
			position -= movement
			if use_momentum:
				velocity = -movement

func handle_pinch_zoom() -> void:
	var drag_distance = events[0].position.distance_squared_to(events[1].position)
	if abs(drag_distance - last_drag_distance) > zoom_sensitivity:
		var delta = pinch_zoom_sensitivity if drag_distance > last_drag_distance else -pinch_zoom_sensitivity
		last_drag_distance = drag_distance
		update_zoom(delta)

func handle_touch_release() -> void:
	if events.size() > 0:
		if 1 in events:
			events[0] = events[1]
			events.erase(1)
		last_drag_distance = 0
		after_zoom = true

func handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			events[event.button_index] = event
			disable_drag()
			velocity = Vector2.ZERO
			last_position = event.position
		else:
			events.erase(event.button_index)
	elif event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var zoom_delta = wheel_zoom_sensitivity if event.button_index == MOUSE_BUTTON_WHEEL_UP else -wheel_zoom_sensitivity
		update_zoom(zoom_delta)

func handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if events.size() == 1:
		var movement_speed = base_movement_speed * mouse_sensitivity
		if zoom_dependent_speed:
			movement_speed /= zoom.x
		
		# Clamp movement speed
		movement_speed = clamp(movement_speed, min_movement_threshold, max_movement_speed)
		
		var relative = event.relative.rotated(rotation)
		# Apply sensitivity and movement speed
		var movement = (relative * movement_speed) / zoom.x
		
		# Apply movement only if it's significant enough
		if movement.length_squared() > min_movement_threshold:
			position -= movement
			if use_momentum:
				velocity = -movement

func update_zoom(delta: float) -> void:
	var prev_zoom = zoom.x
	target_zoom = clamp(target_zoom + delta, min_zoom, max_zoom)
	
	if target_zoom != prev_zoom:
		if zoom_tween:
			zoom_tween.kill()
		zoom_tween = create_tween()
		zoom_tween.tween_property(self, "zoom", Vector2.ONE * target_zoom, 0.5)
		
		# Adjust position after zoom to maintain focus point
		var screen_size = get_viewport_rect().size
		var mouse_pos = get_viewport().get_mouse_position()
		var focus_point = position + ((mouse_pos - screen_size/2) / prev_zoom)
		var new_pos = focus_point - ((mouse_pos - screen_size/2) / target_zoom)
		zoom_tween.parallel().tween_property(self, "position", clamp_position(new_pos), 0.5)
		#position = clamp_position(new_pos)

func set_target(_target: Node2D) -> void:
	last_target_pos = _target.position
	target = _target
	go_to(_target.position, true)

func go_to(pos: Vector2, ignore_drag: bool = false) -> void:
	if ignore_drag:
		disable_drag(false)
	position = clamp_position(pos)
	if ignore_drag:
		get_tree().create_timer(0.5).timeout.connect(restore_drag)

func disable_drag(smooth: bool = true) -> void:
	if drag_enabled and drag_horizontal_enabled:
		drag_horizontal_enabled = false
		drag_vertical_enabled = false
		if not smooth:
			position_smoothing_enabled = false
		else:
			enable_smooth()

func restore_drag() -> void:
	if drag_enabled:
		drag_horizontal_enabled = true
		drag_vertical_enabled = true
		enable_smooth()

func enable_smooth(speed: float = 4.0) -> void:
	if not pixel_perfect:
		position_smoothing_enabled = true
		position_smoothing_speed = speed

func disable_smooth() -> void:
	position_smoothing_enabled = false

func offset_drag_margins(_offset: Vector4) -> void:
	default_drag_margins.x = _offset.x
	default_drag_margins.y = _offset.y
	default_drag_margins.z = _offset.z
	default_drag_margins.w = _offset.w
	drag_left_margin = default_drag_margins.x
	drag_right_margin = default_drag_margins.y
	drag_top_margin = default_drag_margins.z
	drag_bottom_margin = default_drag_margins.w
	
	restore_drag()

func restore_original_drag_margins() -> void:
	offset_drag_margins(original_drag_margins)
