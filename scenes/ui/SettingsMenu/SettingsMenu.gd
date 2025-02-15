extends MarginContainer

@export var with_background: bool = true

@onready var sfx_slider: HSlider = %SFXSlider
@onready var voices_slider: HSlider = %VoicesSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var drink_selector: OptionButton = %DrinkOptionButton
@onready var language_selector: OptionButton = %LanguageOptionButton
@onready var touch_checkbox: CheckButton = %TouchCheckButton
@onready var close_button: Button = %CloseButton
@onready var background = $ColorRect
@onready var labels = [%SFXLabel, %VoicesLabel, %MusicLabel, %DrinkLabel, %LanguageLabel, %TouchLabel]

var timer_mark

signal close

# Called when the node enters the scene tree for the first time.
func _ready():
	sfx_slider.value = db_to_linear(SettingsManager.settings.sfx_volume)
	voices_slider.value = db_to_linear(SettingsManager.settings.voice_volume)
	music_slider.value = db_to_linear(SettingsManager.settings.music_volume)
	drink_selector.selected = 1 if SettingsManager.settings.burps_muted else 0
	language_selector.selected = SettingsManager.get_language_index()
	touch_checkbox.button_pressed = SettingsManager.get_touch_control()
	sfx_slider.value_changed.connect(update_sfx_volume)
	voices_slider.value_changed.connect(update_voice_volume)
	music_slider.value_changed.connect(update_music_volume)
	drink_selector.item_selected.connect(update_drink)
	language_selector.item_selected.connect(update_language)
	touch_checkbox.pressed.connect(update_touch_control)
	close_button.pressed.connect(close_modal)
	sfx_slider.mouse_entered.connect(sfx_slider.grab_focus)
	voices_slider.mouse_entered.connect(voices_slider.grab_focus)
	music_slider.mouse_entered.connect(music_slider.grab_focus)
	sfx_slider.focus_entered.connect(reset_label_highlight.bind(%SFXLabel))
	voices_slider.focus_entered.connect(reset_label_highlight.bind(%VoicesLabel))
	music_slider.focus_entered.connect(reset_label_highlight.bind(%MusicLabel))
	drink_selector.focus_entered.connect(reset_label_highlight.bind(%DrinkLabel))
	language_selector.focus_entered.connect(reset_label_highlight.bind(%LanguageLabel))
	touch_checkbox.focus_entered.connect(reset_label_highlight.bind(%TouchLabel))
	close_button.focus_entered.connect(reset_label_highlight)
	

func init_modal():
	background.visible = with_background
	modulate.a8 = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color8(255, 255, 255, 255), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if with_background:
		background.color.a8 = 0
		tween.parallel().tween_property(background, "color", Color8(0, 0, 0, 60), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	get_tree().create_timer(0.05, true).timeout.connect(sfx_slider.grab_focus)
	#reset_label_highlight.call_deferred(%SFXLabel)

func update_sfx_volume(value: float):
	var mute = value < 0.02
	SettingsManager.update_sfx_volume(linear_to_db(value))
	SettingsManager.update_sfx_mute(mute)
	var local_timer_mark = Time.get_ticks_msec()
	timer_mark = local_timer_mark
	await get_tree().create_timer(1).timeout
	if timer_mark == local_timer_mark:
		AudioController.play_sfx("pickup")

func update_voice_volume(value: float):
	var mute = value <= 0.05
	SettingsManager.update_voice_volume(linear_to_db(value))
	SettingsManager.update_voice_mute(mute)

func update_music_volume(value: float):
	var mute = value <= 0.05
	SettingsManager.update_music_volume(linear_to_db(value))
	SettingsManager.update_music_mute(mute)

func update_drink(value: int):
	SettingsManager.update_burp_mute(value > 0)

func update_language(value: int):
	SettingsManager.update_language(value)

func update_touch_control():
	SettingsManager.update_touch_control(touch_checkbox.button_pressed)

func close_modal():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color8(255, 255, 255, 0), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	if with_background:
		tween.parallel().tween_property(background, "color", Color8(0, 0, 0, 0), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	visible = false
	close.emit()

func reset_label_highlight(new_label: Label = null) -> void:
	for label in labels:
		label.position.x = 0
	
	if new_label != null:
		new_label.position.x = 10
