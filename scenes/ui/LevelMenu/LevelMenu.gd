extends MarginContainer

@onready var restore_button = $PanelContainer/MarginContainer/VBoxContainer/RestoreButton as Button
@onready var restart_button = $PanelContainer/MarginContainer/VBoxContainer/RestartButton as Button
@onready var skip_button = $PanelContainer/MarginContainer/VBoxContainer/SkipButton as Button
@onready var settings_button = $PanelContainer/MarginContainer/VBoxContainer/SettingsButton as Button
@onready var wishlist_button = $PanelContainer/MarginContainer/VBoxContainer/WishlistButton as Button
@onready var world_button = $PanelContainer/MarginContainer/VBoxContainer/PanelContainer/MarginContainer/WorldButton as Button
@onready var background = $ColorRect as ColorRect
@onready var settings_menu = $SettingsMenu
@onready var timer: Timer = $Timer

signal close
signal restart
signal skip
signal exit
signal settings

var previous_focused_node: Control
var settings_visible = false
var allow_hotkey_close = false

func _ready():
	restore_button.pressed.connect(close_modal)
	restart_button.pressed.connect(restart_level)
	skip_button.pressed.connect(skip_level)
	world_button.pressed.connect(exit_level)
	settings_button.pressed.connect(open_settings)
	settings_menu.close.connect(close_settings)
	wishlist_button.pressed.connect(open_steam)
	timer.timeout.connect(func():
		allow_hotkey_close = true
	)

func _process(delta):
	if allow_hotkey_close and Input.is_action_just_pressed("toggle_menu"):
		close_modal()

func init_modal():
	previous_focused_node = get_viewport().gui_get_focus_owner()
	visible = true
	modulate.a8 = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color8(255, 255, 255, 255), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	background.color.a8 = 0
	tween.parallel().tween_property(background, "color", Color8(0, 0, 0, 60), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	restore_button.grab_focus()
	timer.start()

func open_settings():
	var tween = create_tween()
	tween.tween_property($PanelContainer, "modulate", Color8(255, 255, 255, 0), .25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	settings_menu.visible = true
	settings_visible = true
	allow_hotkey_close = false
	settings_menu.init_modal()


func close_settings():
	settings_menu.visible = false
	settings_visible = false
	allow_hotkey_close = true
	var tween = create_tween()
	tween.tween_property($PanelContainer, "modulate", Color8(255, 255, 255, 255), .25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	settings.emit()
	settings_button.grab_focus()

func exit_level():
	exit.emit()

func restart_level():
	restart.emit()
	close_modal()

func skip_level():
	skip.emit()
	close_modal()

func open_steam():
	OS.shell_open("https://store.steampowered.com/app/3001110")

func close_modal():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color8(255, 255, 255, 0), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(background, "color", Color8(0, 0, 0, 0), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	visible = false
	timer.stop()
	allow_hotkey_close = false
	close.emit()
	if previous_focused_node != null and is_instance_valid(previous_focused_node):
		previous_focused_node.grab_focus()
		previous_focused_node = null
