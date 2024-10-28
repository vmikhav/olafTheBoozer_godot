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
@export var target_follow_delay: float = 1.5
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

var velocity: Vector2 = Vector2.ZERO
var last_position: Vector2 = Vector2.ZERO
var elastic_offset: Vector2 = Vector2.ZERO
var base_movement_speed: float = 2.0
var min_movement_threshold: float = 0.001  # Prevents micro-movements
var max_movement_speed: float = 10.0  # Prevents too fast movement

func _ready() -> void:
	setup_timer()
	position_smoothing_enabled = true
	
	# Enable pixel-perfect rendering if needed
	if pixel_perfect:
		position_smoothing_enabled = false
		set_process_mode(Node.PROCESS_MODE_PAUSABLE)

func setup_timer() -> void:
	timer = Timer.new()
	timer.wait_time = target_follow_delay
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(func(): timer_flag = true)

func _physics_process(delta: float) -> void:
	if use_momentum:
		apply_momentum(delta)
	
	if elastic_bounds:
		apply_elastic_bounds(delta)
	
	if target and target_return_enabled and events.size() == 0 and timer_flag:
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
	target_pos = clamp_position(target_pos)
	
	if position.distance_squared_to(target_pos) < 1:
		position = target_pos
		if can_restore_drag:
			restore_drag()
	else:
		position = position.lerp(target_pos, target_return_rate)

func clamp_position(pos: Vector2) -> Vector2:
	var screen_size = get_viewport_rect().size
	var half_width = (screen_size.x / 2) / zoom.x
	var half_height = (screen_size.y / 2) / zoom.y
	
	var min_x = limit_left + half_width
	var max_x = limit_right - half_width
	var min_y = limit_top + half_height
	var max_y = limit_bottom - half_height
	
	return Vector2(
		clamp(pos.x, min_x, max_x),
		clamp(pos.y, min_y, max_y)
	)

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
