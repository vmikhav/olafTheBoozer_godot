extends MarginContainer

@onready var up_button = $VBoxContainer/MarginContainer/UpButton as TextureButton
@onready var left_button = $VBoxContainer/HBoxContainer/MarginContainer/LeftButton as TextureButton
@onready var right_button = $VBoxContainer/HBoxContainer/MarginContainer2/RightButton as TextureButton
@onready var down_button = $VBoxContainer/MarginContainer2/DownButton as TextureButton
@onready var buttons = {
	"step_up" = self.up_button,
	"step_left" = self.left_button,
	"step_right" = self.right_button,
	"step_down" = self.down_button,
}

signal actions(action: InputEventAction)

# Called when the node enters the scene tree for the first time.
func _ready():
	var keys = buttons.keys()
	for key in keys:
		buttons[key].button_down.connect(process_button_pressed.bind(key))
		buttons[key].button_up.connect(process_button_released.bind(key))

func process_button_pressed(direction: String):
	var input = InputEventAction.new()
	input.action = direction
	input.pressed = true
	actions.emit(input)

func process_button_released(direction: String):
	var input = InputEventAction.new()
	input.action = direction
	input.pressed = false
	actions.emit(input)
