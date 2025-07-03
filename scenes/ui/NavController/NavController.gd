extends Node

@export var actions_to_track: Array[String] = []: set = _set_actions
@export var repeat_delay_start: float = 0.35
@export var repeat_delay_continue: float = 0.2 
@export var joystick_deadzone: float = 0.5
var actions_pressed: Array[bool] = []
var action_timers: Array[int] = []
var last_joystick_dir := Vector2.ZERO	

signal actions(action: String)


func _set_actions(new_actions):
	actions_to_track = new_actions
	actions_pressed = []
	action_timers = []
	for i in actions_to_track.size():
		actions_pressed.push_back(false)
		action_timers.push_back(0)

func _input(event):
	for i in actions_to_track.size():
		if event.is_action_pressed(actions_to_track[i]):
			process_action_pressed(i)
		if event.is_action_released(actions_to_track[i]):
			process_button_released(i)
	#if event is InputEventJoypadMotion:
	#	var stick_input := Vector2.ZERO
	#	
	#	# Assuming default joy axis bindings: 0 = left stick X, 1 = left stick Y
	#	if event.axis == JOY_AXIS_LEFT_X:
	#		stick_input.x = event.axis_value
	#		stick_input.y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	#	elif event.axis == JOY_AXIS_LEFT_Y:
	#		stick_input.x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	#		stick_input.y = event.axis_value
	#	else:
	#		return
	#		
	#	# Apply deadzone
	#	if stick_input.length() < joystick_deadzone:
	#		stick_input = Vector2.ZERO
	#	
	#	process_joystick_direction(stick_input)
	#else:
	#	for i in actions_to_track.size():
	#		if event.is_action_pressed(actions_to_track[i]):
	#			process_action_pressed(i)
	#		if event.is_action_released(actions_to_track[i]):
	#			process_button_released(i)

func process_action_pressed(index: int):
	actions_pressed[index] = true
	actions.emit(actions_to_track[index])
	if repeat_delay_start > 0:
		var timer_check = await process_action_timer(index, repeat_delay_start)
		while actions_pressed[index] and timer_check:
			timer_check = await process_action_timer(index, repeat_delay_continue)

func process_button_released(index: int):
	actions_pressed[index] = false

func process_action_timer(index: int, delay: float):
	action_timers[index] += 1
	await get_tree().create_timer(delay).timeout
	action_timers[index] -= 1
	if action_timers[index] > 0:
		return false
	if actions_pressed[index]:
		actions.emit(actions_to_track[index])
	return actions_pressed[index]

func process_joystick_direction(stick_input: Vector2):
	# Reset all joystick-related actions if stick is in neutral position
	if stick_input == Vector2.ZERO:
		for i in actions_to_track.size():
			if actions_pressed[i]:
				process_button_released(i)
		last_joystick_dir = Vector2.ZERO
		return
	
	# Determine primary direction
	var dominant_dir := Vector2.ZERO
	if abs(stick_input.x) > abs(stick_input.y):
		dominant_dir.x = sign(stick_input.x)
	else:
		dominant_dir.y = sign(stick_input.y)
	
	# Only process direction if it changed
	if dominant_dir != last_joystick_dir:
		# Release old direction
		for i in actions_to_track.size():
			process_button_released(i)
			
		# Press new direction
		var action_to_trigger = ""
		if dominant_dir.x > 0 and "ui_right" in actions_to_track:
			action_to_trigger = "ui_right"
		elif dominant_dir.x < 0 and "ui_left" in actions_to_track:
			action_to_trigger = "ui_left"
		elif dominant_dir.y > 0 and "ui_down" in actions_to_track:
			action_to_trigger = "ui_down"
		elif dominant_dir.y < 0 and "ui_up" in actions_to_track:
			action_to_trigger = "ui_up"
		
		if action_to_trigger:
			process_action_pressed(actions_to_track.find(action_to_trigger))
			
		last_joystick_dir = dominant_dir
