@tool
extends Control
class_name InputHint

@export_group("Hint")
@export var action_name: String = "ui_accept"  # The input action to show hint for
@export var show_only_when_focused: bool = true  # Show hint only when button is focused
@export var hint_offset: Vector2 = Vector2(0, 0)  # Offset from bottom-right corner
@export var hint_scale: float = 2  # Scale of the hint sprite

var hint_sprite: Sprite2D
var parent_button: Control
var input_detector: InputDetector

func _ready():
	if Engine.is_editor_hint():
		# In editor, create a simple preview
		setup_hint_sprite()
		if hint_sprite:
			# Show a placeholder in editor
			hint_sprite.modulate = Color(1, 1, 1, 0.5)
			var placeholder = ImageTexture.new()
			var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
			image.fill(Color.GRAY)
			placeholder.set_image(image)
			hint_sprite.texture = placeholder
			parent_button = get_parent() as Control
			if parent_button:
				position_hint()
		return
	
	# Get the parent button
	parent_button = get_parent() as Control
	if not parent_button:
		push_error("InputHintComponent must be a child of a Control node")
		return
	
	parent_button.resized.connect(_on_parent_resized)
	# Also connect to minimum_size_changed if available
	if parent_button.has_signal("minimum_size_changed"):
		parent_button.minimum_size_changed.connect(_on_parent_resized)
	
	# Get the input detector singleton
	input_detector = InputDetector.instance
	if not input_detector:
		push_error("InputDetector singleton not found")
		return
	
	# Create the hint sprite
	setup_hint_sprite()
	
	# Connect signals
	if parent_button.has_signal("focus_entered"):
		parent_button.focus_entered.connect(_on_focus_entered)
	if parent_button.has_signal("focus_exited"):
		parent_button.focus_exited.connect(_on_focus_exited)
	
	# Connect to input method changes
	input_detector.input_method_changed.connect(_on_input_method_changed)
	
	# Initial update
	update_hint_display()

func _on_parent_resized():
	position_hint()

func setup_hint_sprite():
	hint_sprite = Sprite2D.new()
	hint_sprite.name = "InputHint"
	hint_sprite.scale = Vector2(hint_scale, hint_scale)
	add_child(hint_sprite)
	
	# Position at bottom-right of parent
	position_hint()

func position_hint():
	if not parent_button or not hint_sprite:
		return
	
	await get_tree().process_frame
	
	# Position this component at bottom-right of parent
	var parent_size = parent_button.size
	position = Vector2(parent_size.x, parent_size.y) + hint_offset
	
	# Center the sprite on this position
	hint_sprite.position = Vector2.ZERO

func _on_focus_entered():
	update_hint_display()

func _on_focus_exited():
	update_hint_display()

func _on_input_method_changed():
	update_hint_display()

func update_hint_display():
	if Engine.is_editor_hint():
		return  # Skip in editor
		
	if not hint_sprite or not input_detector:
		return
	
	# Check if we should show the hint
	var should_show = true
	if show_only_when_focused and parent_button:
		should_show = parent_button.has_focus()
	
	if not should_show:
		hint_sprite.visible = false
		return
	
	# Get the appropriate hint texture
	var hint_texture = get_hint_texture_for_action(action_name)
	if hint_texture:
		hint_sprite.texture = hint_texture
		hint_sprite.visible = true
	else:
		hint_sprite.visible = false

func get_hint_texture_for_action(action: String) -> Texture2D:
	if Engine.is_editor_hint() or not input_detector:
		return null
	
	var current_method = input_detector.get_current_input_method()
	var device_info = input_detector.get_current_device_info()
	
	# Get the input events for this action
	var events = InputMap.action_get_events(action)
	if events.is_empty():
		return null
	
	# Find the appropriate event for current input method
	var target_event: InputEvent = null
	
	match current_method:
		InputDetector.InputMethod.KEYBOARD:
			for event in events:
				if event is InputEventKey:
					target_event = event
					break
		InputDetector.InputMethod.GAMEPAD:
			for event in events:
				if event is InputEventJoypadButton or event is InputEventJoypadMotion:
					target_event = event
					break
	
	if not target_event:
		return null
	
	# Get texture from HintTextureManager
	return HintTextureManager.get_hint_texture(target_event, device_info)
