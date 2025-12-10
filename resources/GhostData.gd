class_name GhostData
extends Resource

@export var position: Vector2i = Vector2i.ZERO
@export var type: LevelDefinitions.GhostType = LevelDefinitions.GhostType.MEMORY
@export var mode: LevelDefinitions.UnitType = LevelDefinitions.UnitType.WORKER

var unit: Unit
