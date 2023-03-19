class_name LevelSummaryPanel
extends MarginContainer

@onready var restart_button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/RestartButton as Button
@onready var next_button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer2/NextButton as Button
@onready var progress_bar = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer2/MarginContainer/MarginContainer2/ProgressBar as ProgressBar
@onready var highscore_label = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer3/HighscoreLabel as Label
@onready var cups = [
	$PanelContainer/MarginContainer/VBoxContainer/MarginContainer2/MarginContainer/MarginContainer/Cup,
	$PanelContainer/MarginContainer/VBoxContainer/MarginContainer2/MarginContainer/MarginContainer/Cup2,
	$PanelContainer/MarginContainer/VBoxContainer/MarginContainer2/MarginContainer/MarginContainer/Cup3,
]

var cups_values = [25, 60, 90]

var level_report: LevelProgressReport
var is_highscore = false
var is_visible = false
var is_progress_bar_change_connected = false
var burps: Array[String] = ["burp_9", "burp_13", "burp_15", "burp_16", "burp_17", "burp_18", "burp_19", "burp_20"]

signal restart
signal next
signal progress_filled

# Called when the node enters the scene tree for the first time.
func _ready():
	restart_button.pressed.connect(func():
		restart.emit()
	)
	next_button.pressed.connect(func():
		next.emit()
	)


func display():
	is_visible = true
	progress_bar.value = 0
	highscore_label.modulate = Color8(255, 255, 255, 0)
	for i in cups.size():
		cups[i].reset()
	add_theme_constant_override("margin_top", -400)
	var tween = create_tween()
	tween.tween_property(self, "theme_override_constants/margin_top", 10, 1.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	get_tree().create_timer(1.4).timeout.connect(fill_progress_bar)
	await tween.finished

func dismiss_tween():
	var tween = create_tween()
	tween.tween_property(self, "theme_override_constants/margin_top", -400, 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	reset_progress()
	await tween.finished

func dismiss():
	add_theme_constant_override("margin_top", -400)
	reset_progress()

func reset_progress():
	is_visible = false
	if is_progress_bar_change_connected:
		progress_bar.value_changed.disconnect(adjuct_cups_state)
		is_progress_bar_change_connected = false

func fill_progress_bar():
	if not is_visible:
		return
	var tween = create_tween()
	var time = level_report.score * 0.04
	tween.tween_property(progress_bar, "value", level_report.score, time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	progress_bar.value_changed.connect(adjuct_cups_state)
	is_progress_bar_change_connected = true

func adjuct_cups_state(value: float):
	for i in cups.size():
		if cups_values[i] <= value and not cups[i].is_empty:
			cups[i].drink()
	if value == level_report.score:
		var timeout = 1.0
		if not SettingsManager.settings.burps_muted:
			timeout = 0.5
			AudioController.play_sfx(burps[randi_range(0, burps.size()-1)])
		if is_highscore:
			var tween = create_tween()
			tween.tween_property(highscore_label, "modulate", Color8(255, 255, 255, 255), 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			timeout += 0.5
		await get_tree().create_timer(timeout).timeout
		progress_filled.emit()
