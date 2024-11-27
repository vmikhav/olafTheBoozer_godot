extends Panel

@onready var items = $MarginContainer/VBoxContainer/Items
@onready var ghosts = $MarginContainer/VBoxContainer/Ghosts

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_items_count(count: int):
	items.total = count

func set_ghosts_count(count: int):
	ghosts.total = count

func items_progress(progress: int):
	items.progress = progress


func ghosts_progress(progress: int):
	ghosts.progress = progress
