extends MarginContainer

@onready var up_button = $VBoxContainer/MarginContainer/UpButton as TextureButton
@onready var left_button = $VBoxContainer/HBoxContainer/MarginContainer/LeftButton as TextureButton
@onready var right_button = $VBoxContainer/HBoxContainer/MarginContainer2/RightButton as TextureButton
@onready var down_button = $VBoxContainer/MarginContainer2/DownButton as TextureButton
@onready var buttons = {
	"up" = self.up_button,
	"left" = self.left_button,
	"right" = self.right_button,
	"down" = self.down_button,
}

var button_pressed = {}

signal navigate(direction: String)

# Called when the node enters the scene tree for the first time.
func _ready():
	navigate.connect(test)
	var keys = buttons.keys()
	for key in keys:
		button_pressed[key] = false
		buttons[key].button_down.connect(process_button_pressed.bind(key))
		buttons[key].button_up.connect(process_button_released.bind(key))

func test(direction):
	print(direction)

func process_button_pressed(direction: String):
	button_pressed[direction] = true
	navigate.emit(direction)
	await process_button_timer(direction, 0.75)
	while button_pressed[direction]:
		await process_button_timer(direction, 0.3)

func process_button_released(direction: String):
	button_pressed[direction] = false

func process_button_timer(direction: String, delay: float):
	await get_tree().create_timer(delay).timeout
	if button_pressed[direction]:
		navigate.emit(direction)
