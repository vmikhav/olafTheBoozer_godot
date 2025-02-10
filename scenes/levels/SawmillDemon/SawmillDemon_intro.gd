extends BaseLevelIntro

const TILE_SIZE = 48

@onready var hero: DemolitonistSprite = $CanvasLayer/CenterContainer/MarginContainer/Hero
@onready var timer: Timer = $CanvasLayer/Timer

func _ready() -> void:
	hero.set_mode([defs.UnitTypeName[defs.UnitType.WORKER], false])

func play(init: bool = false):
	reset()
	timer.start()
	if init:
		await timer.timeout
	await timer.timeout
	hero.position.x += TILE_SIZE
	await timer.timeout
	hero.position.x += TILE_SIZE * 4
	await timer.timeout
	await timer.timeout
	await timer.timeout
	timer.stop()
	finished.emit()

func reset():
	hero.position.x = TILE_SIZE * .5
	timer.wait_time = 0.3
