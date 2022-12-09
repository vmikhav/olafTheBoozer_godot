class_name LevelSummaryPanel
extends MarginContainer

@onready var restart_button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/RestartButton as Button
@onready var next_button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer2/NextButton as Button

signal restart
signal next

# Called when the node enters the scene tree for the first time.
func _ready():
	restart_button.pressed.connect(func():
		restart.emit()
	)
	next_button.pressed.connect(func():
		next.emit()
	)


func show():
	add_theme_constant_override("margin_top", -400)
	var tween = create_tween()
	tween.tween_property(self, "theme_override_constants/margin_top", 10, 1.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await tween.finished

func hide_tween():
	var tween = create_tween()
	tween.tween_property(self, "theme_override_constants/margin_top", -400, 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished

func hide():
	add_theme_constant_override("margin_top", -400)
