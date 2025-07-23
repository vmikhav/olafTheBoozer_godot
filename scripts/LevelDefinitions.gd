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

#const TrailDirections = {
#	side = [
#		TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
#		TileSet.CELL_NEIGHBOR_TOP_SIDE,
#		TileSet.CELL_NEIGHBOR_LEFT_SIDE,
#		TileSet.CELL_NEIGHBOR_RIGHT_SIDE
#	],
#	#5,19 up 6,19 down 5,20 right 6,20 left
#	backward_tile = ["5,19", "6,19", "5,20", "6,20"],
#	forward_tile = ["6,19", "5,19", "6,20", "5,20"],
#}
const TrailDirections = {
	directions = {
		"6,19": [TileSet.CELL_NEIGHBOR_TOP_SIDE],
		"5,19": [TileSet.CELL_NEIGHBOR_BOTTOM_SIDE],
		"6,20": [TileSet.CELL_NEIGHBOR_RIGHT_SIDE],
		"5,20": [TileSet.CELL_NEIGHBOR_LEFT_SIDE],
		
		"35,12": [TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE],
		"36,12": [TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_RIGHT_SIDE],
		"37,12": [TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_LEFT_SIDE],
		"38,12": [TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_RIGHT_SIDE],
		"39,12": [TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_LEFT_SIDE],
		"40,12": [TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_RIGHT_SIDE],
		"41,12": [TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_RIGHT_SIDE],
		"42,12": [TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_LEFT_SIDE],
		"43,12": [TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_LEFT_SIDE],
		"44,12": [TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_RIGHT_SIDE],
		"45,12": [TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_RIGHT_SIDE],
	},
	sides = [TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_RIGHT_SIDE],
	tiles = {
		# Single directions
		"DOWN": "5,19",
		"UP": "6,19",
		"LEFT": "5,20",
		"RIGHT": "6,20",
		
		# Two directions
		"DOWN,TOP": "35,12",
		"LEFT,RIGHT": "36,12",
		"DOWN,LEFT": "37,12",
		"DOWN,RIGHT": "38,12",
		"LEFT,UP": "39,12",
		"RIGHT,UP": "40,12",
		
		# Three directions
		"DOWN,LEFT,RIGHT": "41,12",
		"LEFT,RIGHT,UP": "42,12",
		"DOWN,LEFT,UP": "43,12",
		"DOWN,RIGHT,UP": "44,12",
		
		# Four directions
		"DOWN,LEFT,RIGHT,UP": "45,12",
	}
}

const DraggableItems = ["12,16", "13,16", "12,18", "14,16"]

enum LevelType {BACKWARD, FORWARD}

enum Layers {GROUND, FLOOR, WALLS, ITEMS, TREES, MOVABLE_ITEMS}
enum Walls {WOOD, STONE, BRICK, CLAY, BUSH, FENCE}
