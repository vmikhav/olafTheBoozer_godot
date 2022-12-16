extends MarginContainer

@export var with_background: bool = true

@onready var sfx_slider = $SettingsPanel/MarginContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/SoundsContainer/SFXSlider as HSlider
@onready var music_slider = $SettingsPanel/MarginContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/MusicContainer/MusicSlider as HSlider
@onready var drink_selector = $SettingsPanel/MarginContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/DrinkContainer/DrinkOptionButton as OptionButton
@onready var close_button = $SettingsPanel/MarginContainer/VBoxContainer/MarginContainer/CloseButton as Button
@onready var background = $ColorRect



signal close

# Called when the node enters the scene tree for the first time.
func _ready():
	sfx_slider.value = db_to_linear(SettingsManager.settings.sfx_volume)
	music_slider.value = db_to_linear(SettingsManager.settings.music_volume)
	drink_selector.selected = 1 if SettingsManager.settings.burps_muted else 0
	sfx_slider.value_changed.connect(update_sfx_volume)
	music_slider.value_changed.connect(update_music_volume)
	drink_selector.item_selected.connect(update_drink)
	close_button.pressed.connect(close_settings)
	init_background()

func init_background():
	$ColorRect.visible = with_background
	modulate.a8 = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color8(255, 255, 255, 255), 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if with_background:
		$ColorRect.color.a8 = 0
		tween.parallel().tween_property($ColorRect, "color", Color8(0, 0, 0, 60), 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func update_sfx_volume(value: float):
	var mute = value <= 0.05
	SettingsManager.update_sfx_volume(linear_to_db(value))
	SettingsManager.update_sfx_mute(mute)

func update_music_volume(value: float):
	var mute = value <= 0.05
	SettingsManager.update_music_volume(linear_to_db(value))
	SettingsManager.update_music_mute(mute)

func update_drink(value: int):
	SettingsManager.update_burp_mute(value > 0)

func close_settings():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color8(255, 255, 255, 0), 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if with_background:
		tween.parallel().tween_property($ColorRect, "color", Color8(0, 0, 0, 0), 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	close.emit()
