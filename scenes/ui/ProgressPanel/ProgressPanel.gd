extends Panel

@onready var items_label = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/Label as Label
@onready var ghosts_label = $MarginContainer/VBoxContainer/HBoxContainer2/MarginContainer/Label as Label
@onready var items_progressbar = $MarginContainer/VBoxContainer/HBoxContainer/ProgressBar as ProgressBar
@onready var ghosts_progressbar = $MarginContainer/VBoxContainer/HBoxContainer2/ProgressBar as ProgressBar

var items_count = 0
var items_tween: Tween
var ghosts_count = 0
var ghosts_tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_items_count(count: int):
	items_count = count
	items_label.text = prepare_label(0, items_count)
	items_progressbar.value = 0
	items_progressbar.max_value = count

func set_ghosts_count(count: int):
	ghosts_count = count
	ghosts_label.text = prepare_label(0, ghosts_count)
	ghosts_progressbar.value = 0
	ghosts_progressbar.max_value = count

func items_progress(progress: int):
	items_label.text = prepare_label(progress, items_count)
	if items_tween:
		items_tween.kill()
		items_tween = null
	if progress == 0:
		items_progressbar.value = 0
	else:
		items_tween = create_tween()
		items_tween.tween_property(items_progressbar, "value", progress, 0.5)


func ghosts_progress(progress: int):
	ghosts_label.text = prepare_label(progress, ghosts_count)
	if ghosts_tween:
		ghosts_tween.kill()
		ghosts_tween = null
	if progress == 0:
		ghosts_progressbar.value = progress
	else:
		ghosts_tween = create_tween()
		ghosts_tween.tween_property(ghosts_progressbar, "value", progress, 0.5)

func prepare_label(progress: int, total:int, add_offset: bool = false)-> String:
	var text = "%d/%d" % [progress, total]
	if add_offset and total >= 10 and progress < 10:
		text = " " + text
	return text
