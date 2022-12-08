extends MarginContainer

@onready var panel = $LevelSummaryPanel as LevelSummaryPanel

var is_showed = false

signal restart
signal next

# Called when the node enters the scene tree for the first time.
func _ready():
	panel.restart.connect(func():
		if is_showed:
			restart.emit()
	)
	panel.next.connect(func():
		if is_showed:
			next.emit()
	)

func show():
	if is_showed:
		return
	is_showed = true
	visible = true
	$ColorRect.color.a8 = 0
	var tween = create_tween()
	tween.tween_property($ColorRect, "color", Color8(0, 0, 0, 60), 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.5).timeout
	panel.show()

func hide(with_tween = true):
	if not is_showed:
		visible = false
		return
	is_showed = false
	if with_tween:
		await hide_panel()
	else:
		panel.hide()
	visible = false

func hide_panel():
	await panel.hide_tween()
