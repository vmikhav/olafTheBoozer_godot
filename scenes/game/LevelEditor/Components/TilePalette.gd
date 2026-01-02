# Scripts/Editor/UI/TilePalette.gd
extends VBoxContainer
class_name TilePalette

## Tile palette for selecting tiles from catalog

signal tile_selected(tile_info: TileInfo)

var editor: LevelEditor
var tile_catalog: TileCatalog
var current_category: String = "all"
var selected_button: Button = null

@onready var category_dropdown: OptionButton = $CategoryDropdown
@onready var search_bar: LineEdit = $SearchBar
@onready var tile_grid: GridContainer = $ScrollContainer/TileGrid

func _ready():
	setup_signals()
	await get_tree().process_frame
	if editor:
		initialize()

func initialize():
	"""Initialize palette with catalog"""
	tile_catalog = editor.tile_catalog
	setup_categories()
	populate_tiles()

func setup_signals():
	"""Connect UI signals"""
	if category_dropdown:
		category_dropdown.item_selected.connect(_on_category_selected)
	
	if search_bar:
		search_bar.text_changed.connect(_on_search_changed)

func setup_categories():
	"""Populate category dropdown"""
	if not tile_catalog:
		return
	
	category_dropdown.clear()
	category_dropdown.add_item("All Tiles", 0)
	
	var categories = tile_catalog.get_categories()
	var idx = 1
	for cat in categories:
		if cat != "all":
			category_dropdown.add_item(cat.capitalize(), idx)
			category_dropdown.set_item_metadata(idx, cat)
			idx += 1

func populate_tiles(filter: String = ""):
	"""Populate tile grid with tiles"""
	# Clear existing
	for child in tile_grid.get_children():
		child.queue_free()
	
	if not tile_catalog:
		return
	
	# Get tiles
	var tiles: Array[TileInfo] = []
	if filter.is_empty():
		tiles = tile_catalog.get_tiles_by_category(current_category)
	else:
		tiles = tile_catalog.search_tiles(filter)
	
	# Create buttons
	for tile in tiles:
		var btn = create_tile_button(tile)
		tile_grid.add_child(btn)

func create_tile_button(tile: TileInfo) -> Button:
	"""Create a button for a tile"""
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(60, 60)
	btn.toggle_mode = true
	btn.text = tile.display_name[0] if tile.display_name.length() > 0 else "?"
	
	# Build tooltip
	var tooltip = tile.display_name
	if tile.has_broken_state:
		tooltip += "\n(Breakable)"
	tooltip += "\nLayers: " + tile.get_allowed_layers_display()
	btn.tooltip_text = tooltip
	
	# Connect signal
	btn.pressed.connect(func(): _on_tile_button_pressed(tile, btn))
	
	return btn

func _on_tile_button_pressed(tile: TileInfo, button: Button):
	"""Handle tile button press"""
	# Deselect previous
	if selected_button and selected_button != button:
		selected_button.button_pressed = false
	
	selected_button = button
	
	# Check if tile can be placed on current layer
	if editor and not tile.can_place_on_layer(editor.active_layer):
		var allowed = tile.get_allowed_layers_display()
		var current = BaseLevel.Layer.keys()[editor.active_layer]
		editor.status_label.text = "Warning: '%s' cannot be placed on %s. Allowed: %s" % [
			tile.display_name, current, allowed
		]
	
	tile_selected.emit(tile)

func _on_category_selected(index: int):
	"""Handle category selection"""
	if index == 0:
		current_category = "all"
	else:
		var idx = category_dropdown.get_item_index(index)
		current_category = category_dropdown.get_item_metadata(idx)
	
	search_bar.text = ""
	populate_tiles()

func _on_search_changed(text: String):
	"""Handle search text change"""
	populate_tiles(text)

func select_tile(tile: TileInfo):
	"""Programmatically select a tile"""
	# Find and press the button
	for child in tile_grid.get_children():
		if child is Button:
			# Compare tile IDs or references
			# This is a simplified version
			pass
