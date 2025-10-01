extends Node2D

@onready var menu_button: Button = $CanvasLayer/MarginContainer2/MarginContainer2/Button
@onready var scene_transition = $CanvasLayer/SceneTransition
@onready var scroll: ScrollContainer = $CanvasLayer/MarginContainer/Panel/MarginContainer/ScrollContainer

@export var initial_delay: float = 6.0  # Seconds to wait before scrolling
@export var scroll_speed: float = 25.0  # Pixels per second

var _time_elapsed: float = 0.0
var _is_scrolling: bool = false
var _reached_end: bool = false
var _scroll_accumulator: float = 0.0

func _ready():
	AudioController.play_music('workshop')
	scene_transition.fade_in()
	menu_button.grab_focus.call_deferred()
	menu_button.pressed.connect(open_menu)
	scroll.scroll_vertical = 0
	_time_elapsed = 0

func _process(delta: float) -> void:
	_time_elapsed += delta
	
	# Wait for initial delay
	if _time_elapsed < initial_delay:
		return
	
	# Start scrolling
	if not _is_scrolling and not _reached_end:
		_is_scrolling = true
	
	# Perform scrolling
	if _is_scrolling:
		_scroll_accumulator += scroll_speed * delta
		scroll.scroll_vertical = int(_scroll_accumulator)
		
		# Check if reached the bottom
		var max_scroll = scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page
		if _scroll_accumulator >= max_scroll:
			_is_scrolling = false
			_reached_end = true
			scroll.scroll_vertical = max_scroll  # Clamp to max

func open_menu():
	scene_transition.change_scene("res://scenes/game/MainMenu/MainMenu.tscn", {})
