# Resources/TileCatalog.gd
extends Resource
class_name TileCatalog

## Simple collection of tiles for editor palette

@export var tiles: Array[TileInfo] = []
@export var name: String = "Tile Catalog"
@export var version: String = "1.0"

## Get tiles by category
func get_tiles_by_category(category: String) -> Array[TileInfo]:
	if category == "all":
		return tiles.duplicate()
	
	var result: Array[TileInfo] = []
	for tile in tiles:
		if tile.category == category or tile.category.begins_with(category + "."):
			result.append(tile)
	return result

## Get tile by ID
func get_tile(id: String) -> TileInfo:
	for tile in tiles:
		if tile.id == id:
			return tile
	return null

## Add tile
func add_tile(tile: TileInfo) -> bool:
	if get_tile(tile.id):
		push_warning("Tile with ID '%s' already exists" % tile.id)
		return false
	tiles.append(tile)
	return true

## Search tiles
func search_tiles(query: String) -> Array[TileInfo]:
	query = query.to_lower()
	var result: Array[TileInfo] = []
	
	for tile in tiles:
		if tile.display_name.to_lower().contains(query):
			result.append(tile)
		elif tile.id.to_lower().contains(query):
			result.append(tile)
		else:
			for tag in tile.tags:
				if tag.to_lower().contains(query):
					result.append(tile)
					break
	
	return result

## Get all used categories
func get_categories() -> Array[String]:
	var cats: Array[String] = ["all"]
	for tile in tiles:
		if tile.category not in cats:
			cats.append(tile.category)
	cats.sort()
	return cats

## Get breakable tiles
func get_breakable_tiles() -> Array[TileInfo]:
	var result: Array[TileInfo] = []
	for tile in tiles:
		if tile.has_broken_state:
			result.append(tile)
	return result
