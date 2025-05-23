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
@export var zoom_speed: float = 0.5

@export_group("Target Following")
@export var target_return_enabled: bool = true
@export var target_return_rate: float = 0.02
@export var target_offset: Vector2 = Vector2.ZERO
@export var target_follow_delay: float = .15

@export_group("Drag Margins")
@export var default_margins: Vector4 = Vector4(0.7, 0.7, 0.6, 0.7)  # left, right, top, bottom

@export_group("Movement Settings")
@export var use_momentum: bool = true
@export var momentum_friction: float = 0.9
@export var zoom_dependent_speed: bool = true
@export var pixel_perfect: bool = true

# Internal variables
var target: Node2D
var events = {}
var velocity: Vector2 = Vector2.ZERO
var target_zoom: float = 1.0
var last_drag_distance: float = 0.0
var zoom_tween: Tween
var follow_timer: Timer
var can_follow: bool = true
var screen_size: Vector2
var last_target_pos: Vector2
var base_movement_speed: float = 2.0
var force_center: bool = false
var limits_rect: Rect2i = Rect2i(-10000, -10000, 20000, 20000)

func _ready() -> void:
	follow_timer = Timer.new()
	follow_timer.one_shot = true
	follow_timer.wait_time = target_follow_delay
	follow_timer.timeout.connect(func(): can_follow = true)
	add_child(follow_timer)
	
	
	target_zoom = zoom.x
	screen_size = get_viewport_rect().size
	
	if pixel_perfect:
		position_smoothing_enabled = false
	else:
		position_smoothing_enabled = true
	
	# Set initial drag margins
	set_drag_margins(default_margins)

func _physics_process(delta: float) -> void:
	if use_momentum:
		apply_momentum(delta)
	
	if target and target_return_enabled and can_follow and events.is_empty():
		follow_target(delta)
	
	if pixel_perfect:
		position = position.round()
		
	position = get_clamped_position(position)

func apply_momentum(delta: float) -> void:
	if velocity.length_squared() > 0.1:
		position += velocity * delta
		velocity *= momentum_friction
	else:
		velocity = Vector2.ZERO

func follow_target(delta: float) -> void:
	if not target:
		return
		
	var target_pos = target.position + target_offset
	
	# When force_center is true, ignore drag margins
	if force_center:
		position = position.lerp(target_pos, target_return_rate)
		if position.distance_squared_to(target_pos) < 1:
			force_center = false
		return
	
	# Calculate screen boundaries with drag margins
	var half_screen = get_screen_center_offset()
	var margin_left = half_screen.x * (1 - drag_left_margin)
	var margin_right = half_screen.x * (1 - drag_right_margin)
	var margin_top = half_screen.y * (1 - drag_top_margin)
	var margin_bottom = half_screen.y * (1 - drag_bottom_margin)
	
	var view_rect = Rect2(
		position - half_screen + Vector2(margin_left, margin_top),
		Vector2(screen_size.x / zoom.x - margin_left - margin_right, 
				screen_size.y / zoom.x - margin_top - margin_bottom) 
	)
	
	# Only move camera if target is outside drag margin bounds
	if not view_rect.has_point(target_pos):
		position = position.lerp(target_pos, target_return_rate)

func get_screen_center_offset() -> Vector2:
	return (screen_size / 2) / zoom.x

func get_clamped_position(pos: Vector2) -> Vector2:
	var half_screen = get_screen_center_offset()
	var clamped_pos = pos
	
	if limit_left < limit_right:
		var min_x = limit_left + half_screen.x
		var max_x = limit_right - half_screen.x
		
		if max_x - min_x < 0:
			clamped_pos.x = (limit_left + limit_right) / 2
		else:
			clamped_pos.x = clamp(pos.x, min_x, max_x)
	
	if limit_top < limit_bottom:
		var min_y = limit_top + half_screen.y
		var max_y = limit_bottom - half_screen.y
		
		if max_y - min_y < 0:
			clamped_pos.y = (limit_top + limit_bottom) / 2
		else:
			clamped_pos.y = clamp(pos.y, min_y, max_y)
	
	return clamped_pos

func _unhandled_input(event: InputEvent) -> void:
	match event:
		var e when e is InputEventScreenTouch:
			handle_touch(e)
		var e when e is InputEventScreenDrag:
			handle_drag(e)
		var e when e is InputEventMouseButton:
			handle_mouse_button(e)
		var e when e is InputEventMouseMotion:
			handle_mouse_motion(e)

func handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		events[event.index] = event
		velocity = Vector2.ZERO
		if events.size() == 2:
			last_drag_distance = events[0].position.distance_to(events[1].position)
	else:
		events.erase(event.index)
		if events.size() == 1 and event.index == 1:
			events[0] = events[1]
			events.erase(1)
	
	can_follow = false
	follow_timer.start()

func handle_drag(event: InputEventScreenDrag) -> void:
	events[event.index] = event
	
	if events.size() == 1:
		var movement = calculate_movement(event.relative, touch_sensitivity)
		apply_movement(movement)
	elif events.size() == 2:
		handle_pinch_zoom()

func handle_mouse_button(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			if event.pressed:
				events[event.button_index] = event
				velocity = Vector2.ZERO
			else:
				events.erase(event.button_index)
			can_follow = false
			follow_timer.start()
		MOUSE_BUTTON_WHEEL_UP:
			update_zoom(wheel_zoom_sensitivity)
		MOUSE_BUTTON_WHEEL_DOWN:
			update_zoom(-wheel_zoom_sensitivity)

func handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if events.size() == 1:
		var movement = calculate_movement(event.relative, mouse_sensitivity)
		apply_movement(movement)

func calculate_movement(relative: Vector2, sensitivity: float) -> Vector2:
	var movement_speed = base_movement_speed * sensitivity
	if zoom_dependent_speed:
		movement_speed /= zoom.x
	return (relative.rotated(rotation) * movement_speed) / zoom.x

func apply_movement(movement: Vector2) -> void:
	position -= movement
	if use_momentum:
		velocity = -movement

func handle_pinch_zoom() -> void:
	var new_distance = events[0].position.distance_to(events[1].position)
	var delta = (new_distance - last_drag_distance) * pinch_zoom_sensitivity
	last_drag_distance = new_distance
	update_zoom(delta)

func update_zoom(delta: float) -> void:
	var prev_zoom = zoom.x
	target_zoom = clamp(target_zoom + delta, min_zoom, max_zoom)
	
	if target_zoom != prev_zoom:
		if zoom_tween:
			zoom_tween.kill()
		
		zoom_tween = create_tween()
		zoom_tween.tween_property(self, "zoom", Vector2.ONE * target_zoom, zoom_speed)
		
		var mouse_pos = get_viewport().get_mouse_position()
		var focus_point = position + ((mouse_pos - screen_size/2) / prev_zoom)
		var new_pos = focus_point - ((mouse_pos - screen_size/2) / target_zoom)
		zoom_tween.parallel().tween_property(self, "position", get_clamped_position(new_pos), zoom_speed)

func set_target(_target: Node2D) -> void:
	target = _target
	if target:
		last_target_pos = target.position
		center_on_target()

func center_on_target() -> void:
	if target:
		force_center = true
		position = get_clamped_position(target.position + target_offset)

func set_drag_margins(margins: Vector4) -> void:
	drag_left_margin = margins.x
	drag_right_margin = margins.y
	drag_top_margin = margins.z
	drag_bottom_margin = margins.w

func set_drag_offset(_offset: Vector2) -> void:
	set_drag_margins(default_margins + Vector4(-_offset.x, _offset.x, -_offset.y, _offset.y))

func set_limits(rect: Rect2i) -> void:
	limits_rect = rect
	update_limits_by_zoom()

func update_limits_by_zoom() -> void:
	var new_limit_pos = limits_rect.position
	var new_limit_end = limits_rect.end
	var mapped_screen_size = screen_size / zoom

	# Horizontally
	if limits_rect.size.x < mapped_screen_size.x:
		var expand_x = ceili((mapped_screen_size.x - limits_rect.size.x) / 2)
		new_limit_pos.x -= expand_x
		new_limit_end.x += expand_x

	# Vertically
	if limits_rect.size.y < mapped_screen_size.y:
		var expand_y = ceili((mapped_screen_size.y - limits_rect.size.y) / 2)
		new_limit_pos.y -= expand_y
		new_limit_end.y += expand_y

	# Apply the adjusted limits
	limit_left = new_limit_pos.x
	limit_top = new_limit_pos.y
	limit_right = new_limit_end.x
	limit_bottom = new_limit_end.y
