extends Node2D

var map: TileMap
var history: Array[Array] = []
var history_pointer: int = 0
var transaction: Array[CellHistory] = []

func init(_map: TileMap):
	map = _map

func begin_transaction():
	transaction = []

func set_cell(layer: int, coords: Vector2i, source_id: int = -1, atlas_coords: Vector2i = Vector2i(-1, -1), alternative_tile: int = 0):
	var _new = CellData.new(source_id, atlas_coords, alternative_tile)
	var _changed = false
	for item in transaction:
		if item.layer == layer and is_same(item.coords, coords):
			item.new = _new
			_changed = true
			break
	if not _changed:
		var _old = CellData.new(
			map.get_cell_source_id(layer, coords),
			map.get_cell_atlas_coords(layer, coords),
			map.get_cell_alternative_tile(layer, coords)
		)
		var _item = CellHistory.new()
		_item.layer = layer
		_item.coords = coords
		_item.old = _old
		_item.new = _new
		transaction.push_back(_item)
	map.set_cell(layer, coords, source_id, atlas_coords, alternative_tile)

func commit():
	if transaction.size():
		while history.size() > history_pointer:
			history.pop_back()
		history.push_back(transaction)
		history_pointer = history.size()
		transaction = []

func undo():
	if not history.size() or history_pointer == 0:
		return
	history_pointer -= 1
	var _transaction: Array[CellHistory] = history[history_pointer]
	for _item in _transaction:
		map.set_cell(_item.layer, _item.coords, _item.old.source_id, _item.old.atlas_coords, _item.old.alternative_tile)

func redo():
	if history_pointer >= history.size():
		return
	history_pointer += 1
	var _transaction: Array[CellHistory] = history[history_pointer]
	for _item in _transaction:
		map.set_cell(_item.layer, _item.coords, _item.new.source_id, _item.new.atlas_coords, _item.new.alternative_tile)
