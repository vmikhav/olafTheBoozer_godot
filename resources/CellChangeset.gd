class_name CellChangeset
extends Resource

@export var position: Vector2i = Vector2i.ZERO
@export var layer: BaseLevel.Layer = BaseLevel.Layer.LIQUIDS
@export var old_coords: Vector2i = Vector2i(-1, -1)
@export var new_coords: Vector2i = Vector2i(-1, -1)
@export var old_alt: int = 0
@export var new_alt: int = 0
