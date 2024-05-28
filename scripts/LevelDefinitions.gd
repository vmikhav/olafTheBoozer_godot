class_name LevelDefinitions
extends Object

enum GhostType {
	MEMORY,
	ENEMY,
	ENEMY_SPAWN,
}

enum UnitType {
	DEMOLITONIST,
	DEMONESS,
	IMP,
	PEASANT,
	SUCCUB,
	VILLAGER_WOMAN,
	WORKER,
}

const UnitTypeName = {
	UnitType.DEMOLITONIST: "demolitonist",
	UnitType.DEMONESS: "demoness",
	UnitType.IMP: "imp",
	UnitType.PEASANT: "peasant",
	UnitType.SUCCUB: "succub",
	UnitType.VILLAGER_WOMAN: "villagerWoman",
	UnitType.WORKER: "worker",
}

const TrailDirections = {
	side = [
		TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
		TileSet.CELL_NEIGHBOR_TOP_SIDE,
		TileSet.CELL_NEIGHBOR_LEFT_SIDE,
		TileSet.CELL_NEIGHBOR_RIGHT_SIDE
	],
	#5,19 up 6,19 down 5,20 right 6,20 left
	backward_tile = ["5,19", "6,19", "5,20", "6,20"],
	forward_tile = ["6,19", "5,19", "6,20", "5,20"],
}

enum Layers {GROUND, FLOOR, WALLS, ITEMS, TREES}
enum Walls {WOOD, STONE, BRICK, CLAY, BUSH, FENCE}
