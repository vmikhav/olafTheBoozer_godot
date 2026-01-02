# Scripts/Editor/UI/LayerPanel.gd
extends VBoxContainer
class_name LayerPanel

## Layer selection panel

signal layer_selected(layer: BaseLevel.Layer)

var editor: LevelEditor
var active_layer: BaseLevel.Layer = BaseLevel.Layer.WALLS
var layer_buttons: Dictionary = {}

@onready var layer_list: VBoxContainer = $LayerList

func _ready():
	await get_tree().process_frame
	if editor:
		initialize()

func initialize():
	"""Create layer buttons"""
	var button_group = ButtonGroup.new()
	
	var layer_info = [
		{"layer": BaseLevel.Layer.GROUND, "name": "Ground", "color": Color(0.6, 0.4, 0.2)},
		{"layer": BaseLevel.Layer.FLOOR, "name": "Floor", "color": Color(0.7, 0.7, 0.5)},
		{"layer": BaseLevel.Layer.PRESS_PLATES, "name": "Press Plates", "color": Color(0.8, 0.6, 0.3)},
		{"layer": BaseLevel.Layer.LIQUIDS, "name": "Liquids", "color": Color(0.3, 0.5, 0.9)},
		{"layer": BaseLevel.Layer.WALLS, "name": "Walls", "color": Color(0.5, 0.5, 0.5)},
		{"layer": BaseLevel.Layer.TRAILS, "name": "Trails", "color": Color(0.9, 0.9, 0.3)},
		{"layer": BaseLevel.Layer.ITEMS, "name": "Items", "color": Color(0.9, 0.7, 0.3)},
		{"layer": BaseLevel.Layer.TREES, "name": "Trees", "color": Color(0.2, 0.7, 0.3)},
		{"layer": BaseLevel.Layer.BAD_ITEMS, "name": "Bad Items", "color": Color(0.9, 0.3, 0.3)},
		{"layer": BaseLevel.Layer.GOOD_ITEMS, "name": "Good Items", "color": Color(0.3, 0.9, 0.3)},
		{"layer": BaseLevel.Layer.MOVABLE_ITEMS, "name": "Movable Items", "color": Color(0.7, 0.5, 0.9)}
	]
	
	for info in layer_info:
		var btn = create_layer_button(info, button_group)
		layer_list.add_child(btn)
		layer_buttons[info.layer] = btn
		
		# Set WALLS as default
		if info.layer == BaseLevel.Layer.WALLS:
			btn.button_pressed = true
			active_layer = info.layer

func create_layer_button(info: Dictionary, button_group: ButtonGroup) -> Button:
	"""Create a layer selection button"""
	var btn = Button.new()
	btn.text = info.name
	btn.toggle_mode = true
	btn.button_group = button_group
	
	# Add color indicator
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2)
	style.border_width_left = 4
	style.border_color = info.color
	btn.add_theme_stylebox_override("normal", style)
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.3, 0.3, 0.35)
	style_pressed.border_width_left = 4
	style_pressed.border_color = info.color
	btn.add_theme_stylebox_override("pressed", style_pressed)
	
	# Connect signal
	var layer = info.layer
	btn.pressed.connect(func(): _on_layer_button_pressed(layer))
	
	return btn

func _on_layer_button_pressed(layer: BaseLevel.Layer):
	"""Handle layer button press"""
	active_layer = layer
	layer_selected.emit(layer)
	
	if editor:
		editor.status_label.text = BaseLevel.Layer.keys()[layer]

func set_active_layer(layer: BaseLevel.Layer):
	"""Programmatically set active layer"""
	if layer_buttons.has(layer):
		layer_buttons[layer].button_pressed = true
		active_layer = layer
		layer_selected.emit(layer)

func get_active_layer() -> BaseLevel.Layer:
	"""Get currently active layer"""
	return active_layer

func highlight_compatible_layers(tile: TileInfo):
	"""Highlight layers compatible with selected tile"""
	for layer in layer_buttons:
		var btn = layer_buttons[layer]
		if tile.can_place_on_layer(layer):
			btn.modulate = Color(1, 1, 1)  # Normal
		else:
			btn.modulate = Color(0.5, 0.5, 0.5)  # Dimmed

func clear_highlights():
	"""Clear all layer highlights"""
	for layer in layer_buttons:
		layer_buttons[layer].modulate = Color(1, 1, 1)
