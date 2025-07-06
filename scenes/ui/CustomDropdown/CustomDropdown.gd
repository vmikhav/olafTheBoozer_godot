@tool
extends Button
class_name CustomDropdown

signal item_selected(index: int)

@export var items: Array[String] = [] : set = set_items
@export var selected_index: int = -1 : set = set_selected_index
@export var placeholder_text: String = "Select..." : set = set_placeholder_text

# Style properties
@export_group("Styling")
@export var max_visible_items: int = 8
@export var dropdown_button_style: StyleBox
@export var dropdown_button_hover_style: StyleBox
@export var dropdown_button_pressed_style: StyleBox
@export var panel_style: StyleBox

@export_group("Item Styling")
@export var item_height: float = 28.0
@export var item_style: StyleBox
@export var item_hover_style: StyleBox
@export var item_selected_style: StyleBox
@export var item_font: Font = preload("res://assets/fonts/press-start-2p-v6.woff2")
@export var item_font_size: int = 16

var dropdown_panel: Panel
var item_container: VBoxContainer
var item_buttons: Array[Button] = []
var is_dropdown_open: bool = false
var is_dropdown_created: bool = false
var dropdown_parent: Node = null

func _ready():
	# Set up button properties
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	focus_mode = Control.FOCUS_ALL
	
	_setup_dropdown_ui()
	_connect_signals()
	_update_items()
	
	# Apply default styles
	_apply_default_styles()

func _notification(what):
	match what:
		NOTIFICATION_RESIZED:
			_update_layout()
		NOTIFICATION_TRANSLATION_CHANGED:
			update_translations()

func _update_layout():
	if is_dropdown_open:
		_position_dropdown_panel()

# Clean up when the node is removed
func _exit_tree():
	if is_dropdown_open and dropdown_panel:
		if dropdown_parent and dropdown_panel.get_parent() == dropdown_parent:
			dropdown_parent.remove_child(dropdown_panel)
			add_child(dropdown_panel)
		_close_dropdown()

# Public method to call when language changes
func update_translations():
	if is_dropdown_created:
		_update_items()

func _setup_dropdown_ui():
	# Dropdown panel - initially a child, moves to appropriate parent when open
	dropdown_panel = Panel.new()
	dropdown_panel.visible = false
	dropdown_panel.z_index = 100
	dropdown_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dropdown_panel)
	
	# Scroll container for items
	var scroll_container = ScrollContainer.new()
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dropdown_panel.add_child(scroll_container)
	
	# Item container
	item_container = VBoxContainer.new()
	item_container.add_theme_constant_override("separation", 0)
	item_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(item_container)
	is_dropdown_created = true

func _find_dropdown_parent() -> Node:
	# Look for CanvasLayer in the parent chain
	var current = get_parent()
	while current:
		if current is CanvasLayer:
			return current
		current = current.get_parent()
	
	# If no CanvasLayer found, look for the topmost Control node
	current = get_parent()
	var topmost_control = null
	while current:
		if current is Control:
			topmost_control = current
		current = current.get_parent()
	
	# If we found a topmost Control, use it; otherwise fall back to viewport
	if topmost_control:
		return topmost_control
	else:
		return get_viewport()

func _apply_default_styles():
	if not dropdown_button_style:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.2, 1.0)
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.4, 0.4, 0.4, 1.0)
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		dropdown_button_style = style
	
	if not dropdown_button_hover_style:
		var style = dropdown_button_style.duplicate()
		style.bg_color = Color(0.25, 0.25, 0.25, 1.0)
		dropdown_button_hover_style = style
	
	if not dropdown_button_pressed_style:
		var style = dropdown_button_style.duplicate()
		style.bg_color = Color(0.15, 0.15, 0.15, 1.0)
		dropdown_button_pressed_style = style
	
	if not panel_style:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.15, 1.0)
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.4, 0.4, 0.4, 1.0)
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		panel_style = style
	
	if not item_style:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.15, 0.0)
		item_style = style
	
	if not item_hover_style:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.3, 0.3, 1.0)
		item_hover_style = style
	
	if not item_selected_style:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.4, 0.6, 0.8, 1.0)
		item_selected_style = style

func _connect_signals():
	# Connect to button's pressed signal (inherited from Button)
	pressed.connect(_on_button_pressed)
	focus_entered.connect(_on_button_focus_entered)
	
	# Connect to size changes to update positioning
	resized.connect(_on_resized)

func _on_resized():
	if is_dropdown_open:
		_position_dropdown_panel()

func _on_button_pressed():
	_toggle_dropdown()

func _on_button_focus_entered():
	if is_dropdown_open:
		_close_dropdown()

func _toggle_dropdown():
	if is_dropdown_open:
		_close_dropdown()
	else:
		_open_dropdown()

func _open_dropdown():
	if items.is_empty():
		return
	
	is_dropdown_open = true
	dropdown_panel.visible = true
	
	# Find the appropriate parent for the dropdown panel
	dropdown_parent = _find_dropdown_parent()
	
	# Move panel to the appropriate parent to avoid clipping
	if dropdown_panel.get_parent() != dropdown_parent:
		remove_child(dropdown_panel)
		dropdown_parent.add_child(dropdown_panel)
	
	_position_dropdown_panel()
	_update_button_styles()
	
	# Focus the selected item or first item
	var focus_index = selected_index if selected_index >= 0 else 0
	if focus_index < item_buttons.size():
		item_buttons[focus_index].grab_focus()

func _close_dropdown():
	is_dropdown_open = false
	dropdown_panel.visible = false
	
	# Move panel back to this control
	if dropdown_parent and dropdown_panel.get_parent() == dropdown_parent:
		dropdown_parent.remove_child(dropdown_panel)
		add_child(dropdown_panel)
	
	dropdown_parent = null
	_update_button_styles()
	grab_focus()  # Use inherited grab_focus instead of main_button.grab_focus()

func _position_dropdown_panel():
	# Make sure we have the correct size from the container
	await get_tree().process_frame
	
	# Position dropdown panel relative to this button's global position
	var button_global_pos = global_position
	var button_size = size
	
	dropdown_panel.global_position = Vector2(button_global_pos.x, button_global_pos.y + button_size.y)
	dropdown_panel.size.x = button_size.x
	
	# Calculate dropdown height
	var visible_items = min(items.size(), max_visible_items)
	var panel_height = visible_items * item_height
	dropdown_panel.size.y = panel_height
	
	# Position scroll container
	var scroll = dropdown_panel.get_child(0) as ScrollContainer
	scroll.size = dropdown_panel.size

func _update_items():
	# Clear existing items
	for button in item_buttons:
		button.queue_free()
	item_buttons.clear()
	
	# Create new item buttons
	for i in range(items.size()):
		var item_button = Button.new()
		item_button.text = tr(items[i])  # Apply translation
		item_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		item_button.custom_minimum_size.y = item_height
		item_button.focus_mode = Control.FOCUS_ALL
		item_button.flat = true
		item_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_button.mouse_filter = Control.MOUSE_FILTER_STOP
		item_button.add_theme_font_override("font", item_font)
		item_button.add_theme_font_size_override("font_size", item_font_size)
		
		item_button.pressed.connect(_on_item_selected.bind(i))
		item_button.mouse_entered.connect(func (): item_button.grab_focus())
		item_button.focus_entered.connect(_on_item_focus_entered.bind(i))
		
		item_container.add_child(item_button)
		item_buttons.append(item_button)
	
	_update_item_styles()
	_update_button_text()

func _on_item_selected(index: int):
	selected_index = index
	_update_button_text()
	_close_dropdown()
	item_selected.emit(index)

func _on_item_focus_entered(index: int):
	_update_item_styles()

func _update_button_text():
	if selected_index >= 0 and selected_index < items.size():
		text = tr(items[selected_index])  # Use inherited text property
	else:
		text = tr(placeholder_text)  # Use inherited text property

func _update_button_styles():
	if is_dropdown_open:
		add_theme_stylebox_override("normal", dropdown_button_pressed_style)
		add_theme_stylebox_override("hover", dropdown_button_pressed_style)
		add_theme_stylebox_override("pressed", dropdown_button_pressed_style)
	else:
		add_theme_stylebox_override("normal", dropdown_button_style)
		add_theme_stylebox_override("hover", dropdown_button_hover_style)
		add_theme_stylebox_override("pressed", dropdown_button_pressed_style)

func _update_item_styles():
	dropdown_panel.add_theme_stylebox_override("panel", panel_style)
	
	for i in range(item_buttons.size()):
		var button = item_buttons[i]
		if i == selected_index:
			button.add_theme_stylebox_override("normal", item_selected_style)
			button.add_theme_stylebox_override("hover", item_hover_style)
			button.add_theme_stylebox_override("focus", item_hover_style)
		else:
			button.add_theme_stylebox_override("normal", item_style)
			button.add_theme_stylebox_override("hover", item_hover_style)
			button.add_theme_stylebox_override("focus", item_hover_style)

# Handle input for keyboard navigation and click outside
func _input(event):
	if not is_dropdown_open:
		return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				_close_dropdown()
				get_viewport().set_input_as_handled()
			KEY_ENTER, KEY_SPACE:
				if has_focus_in_dropdown():
					var focused_index = get_focused_item_index()
					if focused_index >= 0:
						_on_item_selected(focused_index)
						get_viewport().set_input_as_handled()
	
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Check if click is outside the dropdown
		var mouse_pos = get_global_mouse_position()
		var button_global_rect = Rect2(global_position, size)  # Use inherited properties
		var panel_global_rect = Rect2(dropdown_panel.global_position, dropdown_panel.size)
		
		if not button_global_rect.has_point(mouse_pos) and not panel_global_rect.has_point(mouse_pos):
			_close_dropdown()
			get_viewport().set_input_as_handled()

func has_focus_in_dropdown() -> bool:
	for button in item_buttons:
		if button.has_focus():
			return true
	return false

func get_focused_item_index() -> int:
	for i in range(item_buttons.size()):
		if item_buttons[i].has_focus():
			return i
	return -1

# Setters
func set_items(value: Array[String]):
	items = value
	if is_inside_tree():
		_update_items()

func set_selected_index(value: int):
	selected_index = value
	if is_inside_tree():
		_update_button_text()
		_update_item_styles()

func set_placeholder_text(value: String):
	placeholder_text = value
	if is_inside_tree():
		_update_button_text()

# Public methods
func add_item(item_text: String, index: int = -1):
	if index < 0 or index >= items.size():
		items.append(item_text)
	else:
		items.insert(index, item_text)
	_update_items()

func remove_item(index: int):
	if index >= 0 and index < items.size():
		items.remove_at(index)
		if selected_index == index:
			selected_index = -1
		elif selected_index > index:
			selected_index -= 1
		_update_items()

func clear():
	items.clear()
	selected_index = -1
	_update_items()

func get_item_text(index: int) -> String:
	if index >= 0 and index < items.size():
		return tr(items[index])  # Apply translation
	return ""

func get_item_count() -> int:
	return items.size()

func get_selected_text() -> String:
	if selected_index >= 0 and selected_index < items.size():
		return tr(items[selected_index])  # Apply translation
	return ""

func select(index: int):
	if index >= 0 and index < items.size():
		selected_index = index
		_update_button_text()
		_update_item_styles()
