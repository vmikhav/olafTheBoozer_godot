class_name LevelDefinitions
extends Object

enum GhostType {
	MEMORY,
	ENEMY,
	ENEMY_SPAWN,
}

enum UnitType {
	BLACKSMITH,BLACKSMITH_B,
	DEMOLITONIST,
	DEMONESS,
	GHOST,
	GRENADIER,
	IMP,
	OLD_MAN,
	PEASANT,
	SUCCUB,
	VILLAGER_WOMAN,
	WORKER,
	ORC_VETERAN
}

const UnitTypeName = {
	UnitType.BLACKSMITH: "blacksmith",
	UnitType.BLACKSMITH_B: "blacksmithB",
	UnitType.DEMOLITONIST: "demolitonist",
	UnitType.DEMONESS: "demoness",
	UnitType.GHOST: "ghost",
	UnitType.GRENADIER: "grenadier",
	UnitType.IMP: "imp",
	UnitType.OLD_MAN: "oldMan",
	UnitType.PEASANT: "peasant",
	UnitType.SUCCUB: "succub",
	UnitType.VILLAGER_WOMAN: "villagerWoman",
	UnitType.WORKER: "worker",
	UnitType.ORC_VETERAN: "orcVeteran",
}

const Demons = ["demoness", "imp", "succub"]

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

const DraggableItems = ["12,16", "13,16", "12,18", "14,16"]

enum LevelType {BACKWARD, FORWARD}

enum Layers {GROUND, FLOOR, WALLS, ITEMS, TREES, MOVABLE_ITEMS}
enum Walls {WOOD, STONE, BRICK, CLAY, BUSH, FENCE}
