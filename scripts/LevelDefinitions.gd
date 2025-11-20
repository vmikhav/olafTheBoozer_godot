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
	ORC_VETERAN,
	REAPER,
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
	UnitType.REAPER: "reaper",
}

const Demons = ["demoness", "imp", "succub"]

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
const SlipperyTiles = [
	"38,14", "39,14", "40,14", "41,14", "42,14", "43,14", "44,14", "45,14", "46,14",
	"38,15", "39,15", "40,15", "41,15", "42,15", "43,15", "44,15", "45,15", "46,15",
	"38,16", "39,16", "40,16", "41,16", "42,16", "43,16", "44,16", "45,16", "46,16",
	"38,18", "39,18", "40,18", "41,18", "42,18", "43,18", "44,18",
	"38,19", "39,19", "40,19", "41,19", "42,19",
	"38,20", "39,20", "40,20", "41,20", "42,20",
	"38,21", "39,21", "40,21", "41,21", "42,21",
]
const Levers = [
	{ "off": Vector2i(32,12), "mid": Vector2i(33,12), "on": Vector2i(34,12) }
]
const PressPlates = [
	{ "off": Vector2i(33,14), "on": Vector2i(34,14) },
	{ "off": Vector2i(35,14), "on": Vector2i(36,14) },
	{ "off": Vector2i(33,15), "on": Vector2i(34,15) },
	{ "off": Vector2i(35,15), "on": Vector2i(36,15) },
	{ "off": Vector2i(33,16), "on": Vector2i(34,16) },
]

enum LevelType {BACKWARD, FORWARD}

enum Layers {
	GROUND, FLOOR, WALLS, TRAILS, ITEMS, TREES, MOVABLE_ITEMS
}
enum Walls {WOOD, STONE, BRICK, CLAY, BUSH, FENCE}



static func get_direction_key(direction: TileSet.CellNeighbor) -> String:
	match direction:
		TileSet.CELL_NEIGHBOR_TOP_SIDE:
			return "UP"
		TileSet.CELL_NEIGHBOR_BOTTOM_SIDE:
			return "DOWN"
		TileSet.CELL_NEIGHBOR_LEFT_SIDE:
			return "LEFT"
		TileSet.CELL_NEIGHBOR_RIGHT_SIDE:
			return "RIGHT"
	return ""


static func get_opposite_direction(direction: TileSet.CellNeighbor) -> TileSet.CellNeighbor:
	match direction:
		TileSet.CELL_NEIGHBOR_RIGHT_SIDE:
			return TileSet.CELL_NEIGHBOR_LEFT_SIDE
		TileSet.CELL_NEIGHBOR_LEFT_SIDE:
			return TileSet.CELL_NEIGHBOR_RIGHT_SIDE
		TileSet.CELL_NEIGHBOR_BOTTOM_SIDE:
			return TileSet.CELL_NEIGHBOR_TOP_SIDE
		TileSet.CELL_NEIGHBOR_TOP_SIDE:
			return TileSet.CELL_NEIGHBOR_BOTTOM_SIDE
	return direction  # Default case, shouldn't happen
