extends Node

var allow_grab := true
var focus_indicator_scene = preload("res://scenes/sprites/OlafPortrait/OlafPortrait.tscn")
var current_focus_indicator = null

func _enter_tree() -> void:
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node:Node) -> void:
	if node is BaseButton and node.focus_mode == Control.FocusMode.FOCUS_ALL:
		if node is Button and node.flat:
			return
		# If the added node is a button we connect to its mouse_entered and pressed signals
		# and play a sound
		node.mouse_entered.connect(_play_hover.bind(node))
		node.button_down.connect(_play_pressed.bind(node))
		
		if node is Button and !(node is OptionButton or node is CheckButton or node is CustomDropdown):
			# Connect to focus signals to show/hide the animated sprite
			node.focus_entered.connect(_on_button_focus_entered.bind(node))
			node.focus_exited.connect(_on_button_focus_exited.bind(node))


func _play_hover(node: BaseButton) -> void:
	AudioController.play_sfx("mouse_moving")
	if allow_grab:
		node.grab_focus()


func _play_pressed(node: BaseButton) -> void:
	AudioController.play_sfx("mouse_click")

func _on_button_focus_entered(button: BaseButton) -> void:
	# Remove any existing focus indicator
	if current_focus_indicator != null:
		current_focus_indicator.queue_free()
		current_focus_indicator = null
	
	# Create a new focus indicator
	current_focus_indicator = focus_indicator_scene.instantiate()
	
	# Add it to the scene
	button.add_child(current_focus_indicator)
	
	# Position it in front of the button
	# You may need to adjust this positioning based on your specific needs
	current_focus_indicator.position = Vector2(-16 - 12, button.size.y / 2)

func _on_button_focus_exited(button: BaseButton) -> void:
	# Remove the focus indicator when the button loses focus
	if current_focus_indicator != null:
		current_focus_indicator.queue_free()
		current_focus_indicator = null
