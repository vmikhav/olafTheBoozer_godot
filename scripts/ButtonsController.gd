extends Node

var allow_grab := true

func _enter_tree() -> void:
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node:Node) -> void:
	if node is BaseButton and node.focus_mode == Control.FocusMode.FOCUS_ALL:
		# If the added node is a button we connect to its mouse_entered and pressed signals
		# and play a sound
		node.mouse_entered.connect(_play_hover.bind(node))
		node.button_down.connect(_play_pressed.bind(node))


func _play_hover(node: BaseButton) -> void:
	AudioController.play_sfx("mouse_moving")
	if allow_grab:
		node.grab_focus()


func _play_pressed(node: BaseButton) -> void:
	AudioController.play_sfx("mouse_click")
