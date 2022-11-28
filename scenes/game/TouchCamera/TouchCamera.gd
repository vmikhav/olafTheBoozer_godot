class_name TouchCamera
extends Camera2D

@export var min_zoom: float = 1
@export var max_zoom: float = 4
@export var target_return_enabled: bool = true
@export var target_return_rate = 0.02

@onready var drag_enabled = self.drag_horizontal_enabled
@onready var target_zoom: float = self.zoom.x

var zoom_sensitivity = 10
var zoom_speed = 0.1

var events = {}
var last_drag_distance = 0
var target: Node2D
var zoom_tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if target and target_return_enabled and events.size() == 0:
		if position == target.position:
			return
		if  position.distance_squared_to(target.position) < 1000:
			position = target.position
			restore_drag()
		else:
			position = position.lerp(target.position, target_return_rate)

func _unhandled_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			events[event.index] = event
			disable_drag()
		else:
			events.erase(event.index)
			#restore_drag()

	if event is InputEventScreenDrag:
		events[event.index] = event
		if events.size() == 1:
			position -= event.relative.rotated(rotation) / zoom.x
		elif events.size() == 2:
			var drag_distance = events[0].position.distance_to(events[1].position)
			if abs(drag_distance - last_drag_distance) > zoom_sensitivity:
				last_drag_distance = drag_distance 
				var delta = (zoom_speed) if drag_distance < last_drag_distance else (-zoom_speed)
				update_zoom(delta)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				events[event.button_index] = event
				disable_drag()
			else:
				events.erase(event.button_index)
				#restore_drag()
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var delta = (zoom_speed) if event.button_index == MOUSE_BUTTON_WHEEL_UP else (-zoom_speed)
			update_zoom(delta)

	if event is InputEventMouseMotion:
		if events.size():
			position -= event.relative.rotated(rotation) / zoom.x

func update_zoom(delta: float):
	target_zoom = clamp(target_zoom + delta, min_zoom, max_zoom)
	if zoom_tween:
		zoom_tween.kill()
	zoom_tween = create_tween()
	zoom_tween.tween_property(self, "zoom", Vector2.ONE * target_zoom, 0.5)

func go_to(pos: Vector2, ignore_drag: bool = false):
	if ignore_drag:
		disable_drag(false)
	position = pos
	if ignore_drag:
		get_tree().create_timer(0.5).timeout.connect(restore_drag)

func disable_drag(smooth: bool = true):
	if drag_enabled and drag_horizontal_enabled:
		drag_horizontal_enabled = false
		drag_vertical_enabled = false
		if smooth:
			position_smoothing_enabled = true
			get_tree().create_timer(0.5).timeout.connect(
				func():
					position_smoothing_enabled = false
			)

func restore_drag():
	if drag_enabled:
		drag_horizontal_enabled = true
		drag_vertical_enabled = true
