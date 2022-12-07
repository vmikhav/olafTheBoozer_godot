extends Node

@export var actions_to_track: Array[String] = []: set = _set_actions
@export var repeat_delay_start: float = 0.5
@export var repeat_delay_continue: float = 0.2 
var actions_pressed: Array[bool] = []
var action_timers: Array[int] = []

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
