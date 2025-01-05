extends BaseLevelIntro

const TILE_SIZE = 48

@onready var hero: DemolitonistSprite = $CanvasLayer/CenterContainer/MarginContainer/Hero
@onready var check: Sprite2D = $CanvasLayer/CenterContainer/MarginContainer/Check
@onready var villager: DemolitonistSprite = $CanvasLayer/CenterContainer/MarginContainer/Villager
@onready var timer: Timer = $CanvasLayer/Timer

func _ready() -> void:
	hero.set_mode([defs.UnitTypeName[defs.UnitType.WORKER], false])
	villager.set_mode([defs.UnitTypeName[defs.UnitType.PEASANT], false])
	villager.make_ghost(defs.GhostType.MEMORY)
	villager.set_orientation('left')

func play(init: bool = false):
	reset()
	timer.start()
	if init:
		await timer.timeout
		await timer.timeout
	hero.position.x += TILE_SIZE
	await timer.timeout
	villager.visible = false
	check.visible = true
	hero.position.x += TILE_SIZE
	await timer.timeout
	hero.position.x += TILE_SIZE
	await timer.timeout
	await timer.timeout
	timer.stop()
	finished.emit()

func reset():
	villager.visible = true
	villager.position.x = TILE_SIZE * 2.5
	hero.position.x = TILE_SIZE * .5
	check.visible = false
	timer.wait_time = 0.2
