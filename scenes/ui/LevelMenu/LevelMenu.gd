extends MarginContainer

@onready var restore_button = $PanelContainer/MarginContainer/VBoxContainer/RestoreButton as Button
@onready var restart_button = $PanelContainer/MarginContainer/VBoxContainer/RestartButton as Button
@onready var settings_button = $PanelContainer/MarginContainer/VBoxContainer/SettingsButton as Button
@onready var world_button = $PanelContainer/MarginContainer/VBoxContainer/PanelContainer/MarginContainer/WorldButton as Button
@onready var background = $ColorRect as ColorRect
@onready var settings_menu = $SettingsMenu

signal close
signal restart
signal exit

func _ready():
	restore_button.pressed.connect(close_modal)
	restart_button.pressed.connect(restart_level)
	world_button.pressed.connect(exit_level)
	settings_button.pressed.connect(open_settings)
	settings_menu.close.connect(close_settings)

func init_modal():
	visible = true
	modulate.a8 = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color8(255, 255, 255, 255), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	background.color.a8 = 0
	tween.parallel().tween_property(background, "color", Color8(0, 0, 0, 60), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func open_settings():
	var tween = create_tween()
	tween.tween_property($PanelContainer, "modulate", Color8(255, 255, 255, 0), .25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	settings_menu.visible = true
	settings_menu.init_modal()


func close_settings():
	settings_menu.visible = false
	var tween = create_tween()
	tween.tween_property($PanelContainer, "modulate", Color8(255, 255, 255, 255), .25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func exit_level():
	exit.emit()

func restart_level():
	restart.emit()
	close_modal()

func close_modal(aux_signal = null):
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color8(255, 255, 255, 0), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(background, "color", Color8(0, 0, 0, 0), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	visible = false
	close.emit()
