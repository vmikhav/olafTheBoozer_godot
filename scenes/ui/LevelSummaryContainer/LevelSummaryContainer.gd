extends MarginContainer

@onready var panel = $LevelSummaryPanel as LevelSummaryPanel

var is_showed = false

signal restart
signal next
signal progress_filled

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
	panel.progress_filled.connect(func():
		if is_showed:
			progress_filled.emit()
	)

func display(level_report: LevelProgressReport = null):
	if is_showed:
		return
	panel.level_report = level_report
	panel.is_highscore = SettingsManager.is_new_highscore(level_report.level, level_report)
	SettingsManager.update_highscore(level_report.level, level_report)
	is_showed = true
	visible = true
	$ColorRect.color.a8 = 0
	var tween = create_tween()
	tween.tween_property($ColorRect, "color", Color8(0, 0, 0, 60), 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.5).timeout
	panel.display()

func dismiss(with_tween = true):
	if not is_showed:
		visible = false
		return
	is_showed = false
	if with_tween:
		await dismiss_panel()
	else:
		panel.dismiss()
	visible = false

func dismiss_panel():
	await panel.dismiss_tween()
