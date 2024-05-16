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

enum Layers {GROUND, FLOOR, WALLS, ITEMS, TREES}
enum Walls {WOOD, STONE, BRICK, CLAY, BUSH, FENCE}
