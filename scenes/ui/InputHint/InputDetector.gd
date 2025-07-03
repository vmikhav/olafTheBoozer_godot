extends Node

signal input_method_changed()

enum InputMethod {
	KEYBOARD,
	GAMEPAD
}

var instance: InputDetector
var current_input_method: InputMethod = InputMethod.KEYBOARD
var current_device_info: Dictionary = {}
var last_used_joy_index: int = -1

# Enhanced controller detection patterns including Steam Deck
var controller_patterns = {
	"xbox": ["xbox", "xinput", "microsoft"],
	"playstation": ["playstation", "ps3", "ps4", "ps5", "dualshock", "dualsense", "sony"],
	"nintendo": ["nintendo", "switch", "pro controller", "joy-con"],
	"steamdeck": ["steam", "deck", "valve"],
	"steam_controller": ["steam controller", "sc controller"]
}

func _ready():
	instance = self
	detect_initial_input_method()
	
	# Connect to input events
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _input(event: InputEvent):
	var previous_method = current_input_method
	
	if event is InputEventKey or event is InputEventMouseButton:
		current_input_method = InputMethod.KEYBOARD
		current_device_info = {"type": "keyboard"}
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		current_input_method = InputMethod.GAMEPAD
		last_used_joy_index = event.device
		update_gamepad_info(event.device)
	
	if previous_method != current_input_method:
		input_method_changed.emit()

func detect_initial_input_method():
	# Check if any controllers are connected
	var connected_joypads = Input.get_connected_joypads()
	if connected_joypads.size() > 0:
		current_input_method = InputMethod.GAMEPAD
		last_used_joy_index = connected_joypads[0]
		update_gamepad_info(connected_joypads[0])
	else:
		current_input_method = InputMethod.KEYBOARD
		current_device_info = {"type": "keyboard"}

func update_gamepad_info(joy_index: int):
	var joy_name = Input.get_joy_name(joy_index).to_lower()
	var controller_type = detect_controller_type(joy_name)
	
	current_device_info = {
		"type": controller_type,
		"name": Input.get_joy_name(joy_index),
		"index": joy_index,
		"is_steamdeck": is_steam_deck_controller(joy_name)
	}

func detect_controller_type(controller_name: String) -> String:
	for type in controller_patterns:
		for pattern in controller_patterns[type]:
			if controller_name.contains(pattern):
				return type
	return "generic"

func is_steam_deck_controller(controller_name: String) -> bool:
	# Steam Deck built-in controls detection
	return controller_name.contains("steam") or controller_name.contains("deck") or controller_name.contains("valve")

func is_running_on_steam_deck() -> bool:
	# Check if running on Steam Deck hardware
	# This is a basic check - you might want to enhance this
	return OS.get_name() == "Linux" and OS.get_environment("SteamDeck") != ""

func _on_joy_connection_changed(device_index: int, connected: bool):
	if connected and current_input_method == InputMethod.KEYBOARD:
		# Auto-switch to gamepad when one is connected
		current_input_method = InputMethod.GAMEPAD
		last_used_joy_index = device_index
		update_gamepad_info(device_index)
		input_method_changed.emit()
	elif not connected and device_index == last_used_joy_index:
		# Switch back to keyboard if current gamepad is disconnected
		current_input_method = InputMethod.KEYBOARD
		current_device_info = {"type": "keyboard"}
		input_method_changed.emit()

# Existing getter functions
func get_current_input_method() -> InputMethod:
	return current_input_method

func get_current_device_info() -> Dictionary:
	return current_device_info

func is_using_keyboard() -> bool:
	return current_input_method == InputMethod.KEYBOARD

func is_using_gamepad() -> bool:
	return current_input_method == InputMethod.GAMEPAD

func get_controller_type() -> String:
	return current_device_info.get("type", "keyboard")

# Additional Steam Deck specific functions
func is_steam_deck_device() -> bool:
	return current_device_info.get("is_steamdeck", false)

func get_recommended_input_hints() -> String:
	# Return appropriate button prompts based on detected controller
	match get_controller_type():
		"steamdeck":
			return "steam_deck_buttons"
		"xbox":
			return "xbox_buttons"
		"playstation":
			return "playstation_buttons"
		_:
			return "generic_buttons"
