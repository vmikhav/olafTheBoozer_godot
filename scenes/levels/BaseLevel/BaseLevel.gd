class_name BaseLevel
extends Node2D

const TILE_SIZE = 16
const TILE_OFFSET = Vector2i(8, 10)

enum LAYERS {
	GROUND, FLOOR, WALLS, ITEMS, TREES, BAD_ITEMS, GOOD_ITEMS
}

var hero_position: Vector2i
var tilemap: TileMap
var hero: Node2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func move_hero_to_position(position: Vector2i):
	if hero_position.x > position.x:
		hero.set_orientation('right')
	
	if hero_position.x < position.x:
		hero.set_orientation('left')
	
	hero_position = position
	hero.position = position * TILE_SIZE + TILE_OFFSET


func skip_step():
	pass

func navigate(direction: TileSet.CellNeighbor):
	if direction == TileSet.CELL_NEIGHBOR_RIGHT_SIDE:
		hero.set_orientation('right')
	if direction == TileSet.CELL_NEIGHBOR_LEFT_SIDE:
		hero.set_orientation('left')
	
	
