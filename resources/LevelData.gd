class_name LevelData
extends Resource

@export var level_type: LevelDefinitions.LevelType = LevelDefinitions.LevelType.BACKWARD
@export var hero_start_position: Vector2i = Vector2i.ZERO

@export var camera_limit: Rect2i = Rect2i(0, 0, 800, 600)

@export var ghosts: Array[GhostData] = []
@export var patrols: Array[PatrolData] = []
@export var teleports: Array[TeleportData] = []
@export var triggers: Array[Trigger] = []
@export var changesets: Array[Changeset] = []
