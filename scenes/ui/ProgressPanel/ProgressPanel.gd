extends Panel

@onready var items_label = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/Label as Label
@onready var ghosts_label = $MarginContainer/VBoxContainer/HBoxContainer2/MarginContainer/Label as Label
@onready var items_progressbar = $MarginContainer/VBoxContainer/HBoxContainer/ProgressBar as ProgressBar
@onready var ghosts_progressbar = $MarginContainer/VBoxContainer/HBoxContainer2/ProgressBar as ProgressBar

var items_count = 0
var ghosts_count = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_items_count(count: int):
	items_count = count
	items_label.text = "%d/%d" % [0, count]
	items_progressbar.value = 0
	items_progressbar.max_value = count

func set_ghosts_count(count: int):
	ghosts_count = count
	ghosts_label.text = "%d/%d" % [0, count]
	ghosts_progressbar.value = 0
	ghosts_progressbar.max_value = count

func items_progress(progress: int):
	items_label.text = "%d/%d" % [progress, items_count]
	items_progressbar.value = progress

func ghosts_progress(progress: int):
	ghosts_label.text = "%d/%d" % [progress, ghosts_count]
	ghosts_progressbar.value = progress
