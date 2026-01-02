# Scripts/Editor/LevelEditor.gd
extends Node2D
class_name LevelEditor

## Main level editor controller with full UI integration

signal level_modified
signal tool_changed(tool: EditorTool)
signal tile_selected(tile_info: TileInfo)
signal layer_changed(layer: BaseLevel.Layer)

# Node references
@onready var camera: Camera2D = $Camera2D
@onready var editable_level: Node2D = $EditableLevel
@onready var grid: EditorGrid = $EditorGrid
@onready var cursor: EditorCursor = $EditorCursor

# UI Components
@onready var tile_palette: TilePalette = $EditorUI/MainLayout/LeftPanel/TilePalette
@onready var layer_panel: LayerPanel = $EditorUI/MainLayout/RightPanel/EditorControls/LayerPanel
@onready var tool_grid: GridContainer = $EditorUI/MainLayout/RightPanel/EditorControls/ToolsPanel/ToolGrid
@onready var object_grid: GridContainer = $EditorUI/MainLayout/RightPanel/EditorControls/ObjectTools/ObjectGrid

# Status bar
@onready var coord_label: Label = $EditorUI/BottomBar/StatusBar/CoordsContainer/HBoxContainer/CoordsValue
@onready var zoom_label: Label = $EditorUI/BottomBar/StatusBar/ZoomContainer/HBoxContainer/ZoomValue
@onready var tile_label: Label = $EditorUI/BottomBar/StatusBar/TileContainer/HBoxContainer/TileValue
@onready var status_label: Label = $EditorUI/BottomBar/StatusBar/StatusContainer/StatusLabel

# Menu buttons
@onready var file_menu: MenuButton = $EditorUI/TopBar/MenuBar/FileMenu
@onready var edit_menu: MenuButton = $EditorUI/TopBar/MenuBar/EditMenu
@onready var view_menu: MenuButton = $EditorUI/TopBar/MenuBar/ViewMenu
@onready var objects_menu: MenuButton = $EditorUI/TopBar/MenuBar/ObjectsMenu

# Action buttons
@onready var test_button: Button = $EditorUI/TopBar/ActionsBar/TestButton
@onready var save_button: Button = $EditorUI/TopBar/ActionsBar/SaveButton

# TileMapLayers
var tilemaps: Array[TileMapLayer] = []

# Editor state
var tile_catalog: TileCatalog
var current_tile: TileInfo
var current_tool: EditorTool
var active_layer: BaseLevel.Layer = BaseLevel.Layer.WALLS
var mouse_grid_pos: Vector2i = Vector2i.ZERO

# Tools
var tools: Dictionary = {}
var tool_buttons: Dictionary = {}

# Systems
var changeset_editor: ChangesetEditor
var trigger_config: TriggerConfiguration

# Level data
var hero_position: Vector2i = Vector2i.ZERO
var ghosts: Array[Dictionary] = []
var triggers: Array[Trigger] = []
var changesets: Array[Changeset] = []
var teleports: Array[Dictionary] = []
var camera_limit: Rect2i = Rect2i(0, 0, 800, 600)

# Undo/redo
var undo_stack: Array[EditorAction] = []
var redo_stack: Array[EditorAction] = []
const MAX_UNDO_STEPS = 100

# Camera
var camera_pan_speed: float = 500.0
var camera_zoom_min: float = 0.5
var camera_zoom_max: float = 4.0
var camera_zoom_step: float = 0.1
var tile_size = Vector2i(16, 16)

func _ready():
	setup_tilemaps()
	load_tile_catalog()
	setup_tools()
	setup_systems()
	setup_ui_connections()
	setup_grid()
	setup_cursor()
	setup_menus()

func setup_tilemaps():
	"""Collect references to all TileMapLayers"""
	tilemaps = [
		$EditableLevel/Ground,
		$EditableLevel/Floor,
		$EditableLevel/PressPlates,
		$EditableLevel/Liquids,
		$EditableLevel/Walls,
		$EditableLevel/Trails,
		$EditableLevel/Items,
		$EditableLevel/Trees,
		$EditableLevel/BadItems,
		$EditableLevel/GoodItems,
		$EditableLevel/MovingItems
	]

func load_tile_catalog():
	"""Load the tile catalog resource"""
	var catalog_path = "res://scenes/game/LevelEditor/TileCatalog.tres"
	if ResourceLoader.exists(catalog_path):
		tile_catalog = load(catalog_path) as TileCatalog
	else:
		tile_catalog = TileCatalog.new()
		push_warning("TileCatalog not found at %s" % catalog_path)

func setup_tools():
	"""Initialize editing tools"""
	tools = {
		"pencil": PencilTool.new(self),
		"bucket": BucketTool.new(self),
		"line": LineTool.new(self),
		"rectangle": RectangleTool.new(self),
		"eraser": EraserTool.new(self),
		"eyedropper": EyedropperTool.new(self)
	}
	
	# Create tool buttons
	create_tool_buttons()
	
	# Select default tool
	select_tool("pencil")

func create_tool_buttons():
	"""Create UI buttons for tools"""
	var tool_names = {
		"pencil": "🖌 Pencil (P)",
		"bucket": "🪣 Bucket (B)",
		"line": "─ Line (L)",
		"rectangle": "▢ Rect (R)",
		"eraser": "🧹 Erase (E)",
		"eyedropper": "💧 Pick (I)"
	}
	
	var button_group = ButtonGroup.new()
	
	for tool_id in tools.keys():
		var btn = Button.new()
		btn.text = tool_names[tool_id]
		btn.custom_minimum_size = Vector2(90, 32)
		btn.toggle_mode = true
		btn.button_group = button_group
		
		btn.pressed.connect(func(): select_tool(tool_id))
		
		tool_grid.add_child(btn)
		tool_buttons[tool_id] = btn
		
		# Select pencil by default
		if tool_id == "pencil":
			btn.button_pressed = true

func setup_systems():
	"""Initialize changeset and trigger systems"""
	changeset_editor = ChangesetEditor.new(self)
	trigger_config = TriggerConfiguration.new(self)

func setup_ui_connections():
	"""Connect UI component signals"""
	# Connect tile palette
	if tile_palette:
		tile_palette.editor = self
		tile_palette.tile_selected.connect(_on_tile_selected)
	
	# Connect layer panel
	if layer_panel:
		layer_panel.editor = self
		layer_panel.layer_selected.connect(_on_layer_selected)
	
	# Connect action buttons
	if test_button:
		test_button.pressed.connect(_on_test_pressed)
	if save_button:
		save_button.pressed.connect(_on_save_pressed)

func setup_grid():
	"""Configure editor grid"""
	if grid:
		grid.set_tilemap(tilemaps[BaseLevel.Layer.GROUND])
		grid.show_coordinates = true
		grid.visible = true

func setup_cursor():
	"""Configure cursor preview"""
	if cursor:
		cursor.visible = true
		cursor.set_tile_size(tile_size)

func setup_menus():
	"""Setup menu items"""
	# File menu
	var file_popup = file_menu.get_popup()
	file_popup.add_item("New Level", 0)
	file_popup.add_item("Open Level...", 1)
	file_popup.add_separator()
	file_popup.add_item("Save", 2, KEY_S | KEY_MASK_CTRL)
	file_popup.add_item("Save As...", 3)
	file_popup.add_separator()
	file_popup.add_item("Export...", 4)
	file_popup.id_pressed.connect(_on_file_menu_pressed)
	
	# Edit menu
	var edit_popup = edit_menu.get_popup()
	edit_popup.add_item("Undo", 0, KEY_Z | KEY_MASK_CTRL)
	edit_popup.add_item("Redo", 1, KEY_Y | KEY_MASK_CTRL)
	edit_popup.add_separator()
	edit_popup.add_item("Clear Level", 2)
	edit_popup.id_pressed.connect(_on_edit_menu_pressed)
	
	# View menu
	var view_popup = view_menu.get_popup()
	view_popup.add_check_item("Show Grid", 0, KEY_G)
	view_popup.add_check_item("Show Coordinates", 1)
	view_popup.set_item_checked(0, true)
	view_popup.set_item_checked(1, true)
	view_popup.id_pressed.connect(_on_view_menu_pressed)
	
	# Objects menu
	var objects_popup = objects_menu.get_popup()
	objects_popup.add_item("Place Hero Position", 0)
	objects_popup.add_item("Place Ghost", 1)
	objects_popup.add_separator()
	objects_popup.add_item("Create Changeset", 2)
	objects_popup.add_item("Create Trigger", 3)
	objects_popup.add_item("Create Teleport", 4)
	objects_popup.id_pressed.connect(_on_objects_menu_pressed)

func _process(_delta):
	# Update mouse position
	var mouse_world_pos = get_global_mouse_position()
	var new_grid_pos = world_to_grid(mouse_world_pos)
	
	if new_grid_pos != mouse_grid_pos:
		mouse_grid_pos = new_grid_pos
		_update_cursor()
		_update_status_bar()

func _update_cursor():
	"""Update cursor position and preview"""
	if cursor and current_tile and current_tool:
		cursor.position = grid_to_world(mouse_grid_pos)
		cursor.show_tile_preview(current_tile)
	elif cursor:
		cursor.hide_preview()

func _update_status_bar():
	"""Update status bar labels"""
	if coord_label:
		coord_label.text = "(%d, %d)" % [mouse_grid_pos.x, mouse_grid_pos.y]
	
	if zoom_label:
		zoom_label.text = "%d%%" % int(camera.zoom.x * 100)
	
	if tile_label:
		var layer_name = BaseLevel.Layer.keys()[active_layer]
		if current_tile:
			tile_label.text = "%s | Tile: %s" % [layer_name, current_tile.display_name]
		else:
			tile_label.text = "%s | Tile: None" % layer_name

func _input(event):
	# Tool shortcuts
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_P: select_tool("pencil")
			KEY_B: select_tool("bucket")
			KEY_L: select_tool("line")
			KEY_R: select_tool("rectangle")
			KEY_E: select_tool("eraser")
			KEY_I: select_tool("eyedropper")
			KEY_G: 
				if grid:
					grid.toggle_grid(!grid.visible)
			KEY_Z:
				if event.ctrl_pressed:
					if event.shift_pressed:
						redo()
					else:
						undo()
	
	# Camera controls
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(camera_zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(-camera_zoom_step)
	
	elif event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			camera.position -= event.relative / camera.zoom
	
	# Pass to current tool
	if current_tool:
		current_tool.handle_input(event, mouse_grid_pos)

## Tool management

func select_tool(tool_id: String):
	"""Select a tool"""
	if not tools.has(tool_id):
		return
	
	if current_tool:
		current_tool.deactivate()
	
	current_tool = tools[tool_id]
	current_tool.activate()
	
	tool_changed.emit(current_tool)
	if status_label:
		status_label.text = "Tool: %s" % tool_id.capitalize()

func select_tile(tile_info: TileInfo):
	"""Select a tile"""
	current_tile = tile_info
	tile_selected.emit(tile_info)
	
	# Highlight compatible layers
	if layer_panel:
		layer_panel.highlight_compatible_layers(tile_info)
	
	_update_status_bar()

func select_layer(layer: BaseLevel.Layer):
	"""Select active layer"""
	active_layer = layer
	layer_changed.emit(layer)
	_update_status_bar()

func zoom_camera(delta: float):
	"""Zoom camera"""
	var new_zoom = clamp(camera.zoom.x + delta, camera_zoom_min, camera_zoom_max)
	camera.zoom = Vector2(new_zoom, new_zoom)
	_update_status_bar()

func world_to_grid(world_pos: Vector2) -> Vector2i:
	"""Convert world to grid"""
	return Vector2i(
		int(floor(world_pos.x / tile_size.x)),
		int(floor(world_pos.y / tile_size.y))
	)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	"""Convert grid to world"""
	return Vector2(grid_pos) * Vector2(tile_size)

## Painting functions

func paint_tile(grid_pos: Vector2i):
	"""Paint tile with layer restriction check"""
	if not current_tile:
		if status_label:
			status_label.text = "No tile selected"
		return
	
	# Check layer restriction
	if not current_tile.can_place_on_layer(active_layer):
		var allowed = current_tile.get_allowed_layers_display()
		if status_label:
			status_label.text = "Can't place '%s' on %s. Allowed: %s" % [
				current_tile.display_name,
				BaseLevel.Layer.keys()[active_layer],
				allowed
			]
		return
	
	# Create action
	var action = PaintAction.new()
	action.editor = self
	action.layer = active_layer
	action.tile_info = current_tile
	action.positions = [grid_pos] as Array[Vector2i]
	
	action.execute()
	add_undo_action(action)
	
	level_modified.emit()

func erase_tile(grid_pos: Vector2i):
	"""Erase tile"""
	var action = EraseAction.new()
	action.editor = self
	action.layer = active_layer
	action.positions = [grid_pos] as Array[Vector2i]
	
	action.execute()
	add_undo_action(action)
	
	level_modified.emit()

func add_undo_action(action: EditorAction):
	"""Add action to undo stack"""
	undo_stack.append(action)
	if undo_stack.size() > MAX_UNDO_STEPS:
		undo_stack.pop_front()
	redo_stack.clear()

func undo():
	"""Undo"""
	if undo_stack.is_empty():
		if status_label:
			status_label.text = "Nothing to undo"
		return
	
	var action = undo_stack.pop_back()
	action.undo()
	redo_stack.append(action)
	
	if status_label:
		status_label.text = "Undo"
	level_modified.emit()

func redo():
	"""Redo"""
	if redo_stack.is_empty():
		if status_label:
			status_label.text = "Nothing to redo"
		return
	
	var action = redo_stack.pop_back()
	action.execute()
	undo_stack.append(action)
	
	if status_label:
		status_label.text = "Redo"
	level_modified.emit()

## Level data management

func get_trigger(id: String) -> Trigger:
	for trigger in triggers:
		if trigger.id == id:
			return trigger
	return null

func has_trigger(id: String) -> bool:
	return get_trigger(id) != null

func add_trigger(trigger: Trigger):
	triggers.append(trigger)
	level_modified.emit()

func get_changeset(id: String) -> Changeset:
	for changeset in changesets:
		if changeset.id == id:
			return changeset
	return null

func has_changeset(id: String) -> bool:
	return get_changeset(id) != null

func add_changeset(changeset: Changeset):
	changesets.append(changeset)
	level_modified.emit()

## Signal handlers

func _on_tile_selected(tile_info: TileInfo):
	select_tile(tile_info)

func _on_layer_selected(layer: BaseLevel.Layer):
	select_layer(layer)

func _on_file_menu_pressed(id: int):
	match id:
		0: new_level()
		1: open_level_dialog()
		2: save_level_current()
		3: save_level_as_dialog()
		4: export_level_dialog()

func _on_edit_menu_pressed(id: int):
	match id:
		0: undo()
		1: redo()
		2: clear_level()

func _on_view_menu_pressed(id: int):
	var view_popup = view_menu.get_popup()
	match id:
		0:  # Toggle grid
			if grid:
				grid.toggle_grid(!grid.visible)
				view_popup.set_item_checked(0, grid.visible)
		1:  # Toggle coordinates
			if grid:
				grid.toggle_coordinates(!grid.show_coordinates)
				view_popup.set_item_checked(1, grid.show_coordinates)

func _on_objects_menu_pressed(id: int):
	match id:
		0: print("TODO: Hero position tool")
		1: print("TODO: Ghost tool")
		2: print("TODO: Changeset editor")
		3: print("TODO: Trigger editor")
		4: print("TODO: Teleport tool")

func _on_test_pressed():
	if status_label:
		status_label.text = "Testing level..."

func _on_save_pressed():
	save_level_current()

## Level operations

func new_level():
	"""Create new level"""
	for tilemap in tilemaps:
		if tilemap:
			tilemap.clear()
	
	triggers.clear()
	changesets.clear()
	ghosts.clear()
	teleports.clear()
	undo_stack.clear()
	redo_stack.clear()
	
	if status_label:
		status_label.text = "New level created"

func open_level_dialog():
	"""Open level dialog"""
	# TODO: Implement file dialog
	if status_label:
		status_label.text = "Open level..."

func save_level_current():
	"""Save current level"""
	# TODO: Implement save
	if status_label:
		status_label.text = "Level saved"

func save_level_as_dialog():
	"""Save as dialog"""
	# TODO: Implement save as
	if status_label:
		status_label.text = "Save as..."

func export_level_dialog():
	"""Export level dialog"""
	# TODO: Implement export
	if status_label:
		status_label.text = "Export..."

func clear_level():
	"""Clear all tiles"""
	new_level()
