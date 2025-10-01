extends BaseLevelIntro

const TILE_SIZE = 48

@onready var hero: DemolitonistSprite = $CanvasLayer/CenterContainer/MarginContainer/Hero
@onready var check: Sprite2D = $CanvasLayer/CenterContainer/MarginContainer/Check
@onready var check2: Sprite2D = $CanvasLayer/CenterContainer/MarginContainer/Check2
@onready var villager2: DemolitonistSprite = $CanvasLayer/CenterContainer/MarginContainer/Villager2
@onready var villager3: DemolitonistSprite = $CanvasLayer/CenterContainer/MarginContainer/Villager3
@onready var timer: Timer = $CanvasLayer/Timer

func _ready() -> void:
	hero.set_mode([defs.UnitTypeName[defs.UnitType.WORKER], false])
	villager2.set_mode([defs.UnitTypeName[defs.UnitType.PEASANT], false])
	villager3.set_mode([defs.UnitTypeName[defs.UnitType.PEASANT], false])
	villager2.make_ghost(defs.GhostType.ENEMY)
	villager3.make_ghost(defs.GhostType.ENEMY_SPAWN)
	villager2.set_orientation('right')
	villager3.set_orientation('right')

func play(init: bool = false):
	reset()
	timer.start()
	if init:
		await timer.timeout
		await timer.timeout
	await timer.timeout
	hero.position.x += TILE_SIZE
	await timer.timeout
	await timer.timeout
	hero.position.x += TILE_SIZE
	check.visible = true
	var splash = splash_scene.instantiate() as Node2D
	$CanvasLayer/CenterContainer/MarginContainer.add_child(splash)
	splash.z_index = 150
	splash.scale = Vector2(2, 2)
	splash.position = hero.position + Vector2(0, -0.5) * TILE_SIZE
	await timer.timeout
	hero.position.x += TILE_SIZE
	villager2.sprite.material.set_shader_parameter("status_intensity", 0.0)
	villager2.sprite.material.set_shader_parameter("transparency", 1.0)
	villager2.make_follower()
	villager2.set_orientation('right')
	await timer.timeout
	await timer.timeout
	await timer.timeout
	hero.position.x += TILE_SIZE
	villager2.position.x += TILE_SIZE
	await timer.timeout
	hero.position.x += TILE_SIZE
	villager2.position.x += TILE_SIZE
	await timer.timeout
	hero.position.x += TILE_SIZE
	villager2.position.x += TILE_SIZE
	villager3.visible = false
	check2.visible = true
	splash = splash_scene.instantiate() as Node2D
	$CanvasLayer/CenterContainer/MarginContainer.add_child(splash)
	splash.z_index = 150
	splash.scale = Vector2(2, 2)
	splash.position = hero.position + Vector2(0, -0.5) * TILE_SIZE
	await timer.timeout
	await timer.timeout
	timer.stop()
	finished.emit()

func reset():
	villager3.visible = true
	villager2.position.x = TILE_SIZE * 3.5
	villager2.set_mode([defs.UnitTypeName[defs.UnitType.PEASANT], false])
	villager2.make_ghost(defs.GhostType.ENEMY)
	villager3.position.x = TILE_SIZE * 6.5
	hero.position.x = TILE_SIZE * 1.5
	check.visible = false
	check2.visible = false
	timer.wait_time = 0.2
