extends HBoxContainer

@export var min_label_size: Vector2i = Vector2i(60, 0) : set = _set_min_label_size
@export var style: String = "GreenProgressBar" : set = _set_style
@export var total: int : set = _set_total
@export var progress: int = 0  : set = _set_progress

@onready var label = $MarginContainer/Label as Label
@onready var progressbar = $ProgressBar as ProgressBar

var bar_tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready():
	_set_min_label_size(min_label_size)
	_set_style(style)

func _set_min_label_size(size):
	custom_minimum_size = size
	if label:
		label.custom_minimum_size = size

func _set_style(new_style):
	style = new_style
	if progressbar:
		progressbar.set_theme_type_variation(new_style)

func _set_total(new_total):
	total = new_total
	label.text = prepare_label(0, total)
	progressbar.value = 0
	progressbar.max_value = total

func _set_progress(new_progress):
	if not progressbar:
		return
	progress = new_progress
	label.text = prepare_label(progress, total)
	if bar_tween:
		bar_tween.kill()
		bar_tween = null
	if progress == 0:
		progressbar.value = 0
	else:
		bar_tween = create_tween()
		bar_tween.tween_property(progressbar, "value", progress, 0.5)
	

func prepare_label(progress: int, total:int, add_offset: bool = false)-> String:
	var text = "%d/%d" % [progress, total]
	if add_offset and total >= 10 and progress < 10:
		text = " " + text
	return text
