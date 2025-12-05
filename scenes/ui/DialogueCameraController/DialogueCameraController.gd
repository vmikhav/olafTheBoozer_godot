extends Node2D
class_name DialogueCameraController

## Controls camera transitions during dialogue sequences
## Integrates with DialogueManager addon and processes custom tags

@export var main_camera: Camera2D
@export var dialogue_camera: Camera2D
@export var transition_duration: float = 0.8
@export var transition_ease: Tween.EaseType = Tween.EASE_IN_OUT
@export var transition_trans: Tween.TransitionType = Tween.TRANS_CUBIC

# Default zoom levels for different camera modes
@export_group("Zoom Presets")
@export var close_zoom: Vector2 = Vector2(1.8, 1.8)
@export var medium_zoom: Vector2 = Vector2(1.3, 1.3)
@export var wide_zoom: Vector2 = Vector2(0.9, 0.9)
@export var normal_zoom: Vector2 = Vector2(1.0, 1.0)

var _active_tween: Tween
var _is_dialogue_active: bool = false
var _character_registry: Dictionary[String, Unit] = {} 


func _ready() -> void:
	if not dialogue_camera:
		push_error("DialogueCameraController: dialogue_camera not assigned!")
		return
	
	if not main_camera:
		push_error("DialogueCameraController: main_camera not assigned!")
		return
	
	# Start with dialogue camera disabled
	dialogue_camera.enabled = false
	
	# Connect to DialogueManager if available
	_connect_to_dialogue_manager()


func _connect_to_dialogue_manager() -> void:
	# Wait for DialogueManager to be ready
	await get_tree().process_frame
	
	if not Engine.has_singleton("DialogueManager"):
		# Try to find it in the scene tree
		var dialogue_manager = get_node_or_null("/root/DialogueManager")
		if dialogue_manager:
			_setup_dialogue_signals(dialogue_manager)
	else:
		# If it's an autoload singleton
		var dialogue_manager = DialogueManager
		if dialogue_manager:
			_setup_dialogue_signals(dialogue_manager)


func _setup_dialogue_signals(dialogue_manager: DialogueManager) -> void:
	# Connect to dialogue events
	if dialogue_manager.has_signal("dialogue_started"):
		dialogue_manager.dialogue_started.connect(_on_dialogue_started)
	
	if dialogue_manager.has_signal("dialogue_ended"):
		dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)
	
	# This is the key signal for processing tags
	#if dialogue_manager.has_signal("got_dialogue"):
	dialogue_manager.got_dialogue.connect(_on_dialogue_line)
	
	print("DialogueCameraController: Connected to DialogueManager")


## Register a character for camera and emote control
## Call this during scene setup for each NPC/character
func register_character(character_id: String, character_node: Unit) -> void:
	_character_registry[character_id] = character_node
	print("Registered character: ", character_id)


## Unregister a character (e.g., when they leave the scene)
func unregister_character(character_id: String) -> void:
	_character_registry.erase(character_id)

func reset_characters() -> void:
	_character_registry.clear()

## Get a registered character node
func get_character(character_id: String) -> Unit:
	return _character_registry.get(character_id, null)

func _on_dialogue_line(line: DialogueLine) -> void:
	if line.tags.size() > 0:
		for tag in line.tags:
			_on_dialogue_tag(tag)

## Process dialogue tags from DialogueManager
func _on_dialogue_tag(tag: String) -> void:
	# Tags come in format like "camera:focus:npc1" or "emote:x;y:npc1"
	var parts = tag.split(":", false)
	if parts.is_empty():
		return
	
	var command = parts[0].to_lower()
	
	match command:
		"camera":
			_process_camera_tag(parts)
		"emote":
			_process_emote_tag(parts)
		"cam":  # Shorthand
			_process_camera_tag(parts)


## Process camera control tags
func _process_camera_tag(parts: Array) -> void:
	if parts.size() < 2:
		return
	
	var action = parts[1].to_lower()
	
	match action:
		"focus":
			# camera:focus:npc1 or camera:focus:npc1:close
			if parts.size() >= 3:
				var character_id = parts[2]
				var zoom_preset = parts[3] if parts.size() >= 4 else "default"
				_focus_on_character(character_id, _get_zoom_preset(zoom_preset))
		
		"group":
			# camera:group:npc1,npc2,player
			if parts.size() >= 3:
				var character_ids = parts[2].split(";", false)
				var zoom_preset = parts[3] if parts.size() >= 4 else "wide"
				_focus_on_group(character_ids, _get_zoom_preset(zoom_preset))
		
		"position":
			# camera:position:x,y or camera:position:x,y:zoom
			if parts.size() >= 3:
				var coords = parts[2].split(";", false)
				if coords.size() >= 2:
					var pos = Vector2(float(coords[0]), float(coords[1]))
					var zoom_preset = parts[3] if parts.size() >= 4 else "normal"
					start_dialogue(pos, _get_zoom_preset(zoom_preset))
		
		"reset":
			# camera:reset - return to main camera
			end_dialogue()
		
		"zoom":
			# camera:zoom:close (change zoom without moving)
			if parts.size() >= 3:
				var zoom_preset = parts[2]
				_change_zoom(_get_zoom_preset(zoom_preset))


## Process emote tags
func _process_emote_tag(parts: Array) -> void:
	if parts.size() < 3:
		return
	
	var coords = parts[1].split(";", false)
	var emote_x = int(coords[0])
	var emote_y = int(coords[1])
	
	var character_id = parts[2]
	
	var duration: float = 0.6 if parts.size() < 4 else float(parts[3])
	var pause = 0.05 if parts.size() < 5 else float(parts[4])
	
	var character_node = get_character(character_id)
	if not character_node:
		push_warning("Character not found for emote: ", character_id)
		return
	
	character_node.play_emote(emote_x, emote_y, duration, pause)


## Get zoom preset by name
func _get_zoom_preset(preset_name: String) -> Vector2:
	match preset_name.to_lower():
		"close", "closeup":
			return close_zoom
		"medium", "mid":
			return medium_zoom
		"wide", "far":
			return wide_zoom
		"normal", "default":
			return normal_zoom
		_:
			# Try to parse as custom zoom value (e.g., "1.5")
			var zoom_value = float(preset_name)
			if zoom_value > 0:
				return Vector2(zoom_value, zoom_value)
			return medium_zoom


## Focus camera on a registered character
func _focus_on_character(character_id: String, zoom_level: Vector2) -> void:
	var character = get_character(character_id)
	if character:
		focus_on_node(character, zoom_level)
	else:
		push_warning("Character not registered for camera focus: ", character_id)


## Focus camera on multiple characters
func _focus_on_group(character_ids: Array, zoom_level: Vector2) -> void:
	var characters: Array[Node2D] = []
	
	for char_id in character_ids:
		var character = get_character(char_id.strip_edges())
		if character:
			characters.append(character)
	
	if not characters.is_empty():
		focus_on_nodes(characters, zoom_level)


## Change zoom without changing position
func _change_zoom(new_zoom: Vector2) -> void:
	if not _is_dialogue_active:
		return
	
	if _active_tween:
		_active_tween.kill()
	
	_active_tween = create_tween()
	_active_tween.set_ease(transition_ease)
	_active_tween.set_trans(transition_trans)
	_active_tween.tween_property(dialogue_camera, "zoom", new_zoom, transition_duration * 0.5)


## Called when dialogue starts (optional, for auto-setup)
func _on_dialogue_started(resource) -> void:
	# You can add automatic behavior here if needed
	pass


## Called when dialogue ends
func _on_dialogue_ended(resource) -> void:
	# Automatically return to main camera when dialogue ends
	if _is_dialogue_active:
		end_dialogue()
	for id in _character_registry:
		_character_registry[id].reset_emote()


## Start dialogue mode - transitions to target position
func start_dialogue(target_position: Vector2, target_zoom: Vector2 = Vector2.ONE) -> void:
	if _is_dialogue_active:
		# If already active, just transition to new position
		_transition_to_position(target_position, target_zoom)
		return
	
	_is_dialogue_active = true
	
	# Copy current main camera parameters to dialogue camera
	dialogue_camera.global_position = main_camera.global_position
	dialogue_camera.zoom = main_camera.zoom
	dialogue_camera.offset = main_camera.offset
	dialogue_camera.rotation = main_camera.rotation
	
	# Enable dialogue camera (this makes it active)
	main_camera.enabled = false
	dialogue_camera.enabled = true
	
	# Tween to target position
	_transition_to_position(target_position, target_zoom)


## Transition to a new position (used internally)
func _transition_to_position(target_position: Vector2, target_zoom: Vector2) -> void:
	if _active_tween:
		_active_tween.kill()
	if dialogue_camera.global_position != target_position:
		target_position.y += ceili(8 * target_zoom.y)
	
	_active_tween = create_tween()
	_active_tween.set_parallel(true)
	_active_tween.set_ease(transition_ease)
	_active_tween.set_trans(transition_trans)
	
	_active_tween.tween_property(dialogue_camera, "global_position", target_position, transition_duration)
	_active_tween.tween_property(dialogue_camera, "zoom", target_zoom, transition_duration)


## End dialogue mode - returns to main camera
func end_dialogue() -> void:
	if not _is_dialogue_active:
		return
	
	# Tween back to main camera's current position
	if _active_tween:
		_active_tween.kill()
	
	_active_tween = create_tween()
	_active_tween.set_parallel(true)
	_active_tween.set_ease(transition_ease)
	_active_tween.set_trans(transition_trans)
	
	_active_tween.tween_property(dialogue_camera, "global_position", main_camera.global_position, transition_duration)
	_active_tween.tween_property(dialogue_camera, "zoom", main_camera.zoom, transition_duration)
	
	# When tween finishes, disable dialogue camera and re-enable main camera
	_active_tween.finished.connect(_on_return_tween_finished, CONNECT_ONE_SHOT)


func _on_return_tween_finished() -> void:
	dialogue_camera.enabled = false
	main_camera.enabled = true
	_is_dialogue_active = false


## Focus on a specific node (like an NPC)
func focus_on_node(target_node: Node2D, zoom_level: Vector2 = Vector2(1.5, 1.5)) -> void:
	start_dialogue(target_node.global_position, zoom_level)


## Focus on multiple nodes (centers camera between them)
func focus_on_nodes(target_nodes: Array[Node2D], zoom_level: Vector2 = Vector2(1.2, 1.2)) -> void:
	if target_nodes.is_empty():
		return
	
	var center_position := Vector2.ZERO
	for node in target_nodes:
		center_position += node.global_position
	
	center_position /= target_nodes.size()
	start_dialogue(center_position, zoom_level)


## Check if dialogue camera is active
func is_dialogue_active() -> bool:
	return _is_dialogue_active
