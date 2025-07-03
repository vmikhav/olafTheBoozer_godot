@tool
extends Node

@export var hint_spritesheet: Texture2D = preload("res://assets/images/input_prompts.png")
@export var sprite_size: Vector2i = Vector2i(16, 16)  # Size of each sprite in the sheet
@export var columns: int = 34  # Number of columns in the spritesheet
@export var sprite_gap: int = 1  # Gap between sprites in pixels

# Mapping of inputs to spritesheet positions and sizes
# Format: key -> {pos: Vector2i, size: Vector2i}
var texture_mappings: Dictionary = {}

func _ready():
	setup_default_mappings()

func setup_default_mappings():
	texture_mappings[str(KEY_R)] = {pos = Vector2i(20, 2), size = Vector2i(1, 1)}
	texture_mappings[str(KEY_Z)] = {pos = Vector2i(19, 4), size = Vector2i(1, 1)}
	texture_mappings[str(KEY_ENTER)] = {pos = Vector2i(32, 2), size = Vector2i(2, 2)}  # 2 tiles wide
	#texture_mappings[str(KEY_SPACE)] = {pos = Vector2i(31, 6), size = Vector2i(3, 1)}  # 3 tiles wide
	texture_mappings[str(KEY_SPACE)] = {pos = Vector2i(17, 4), size = Vector2i(1, 1)}  # 3 tiles wide
	texture_mappings[str(KEY_ESCAPE)] = {pos = Vector2i(17, 0), size = Vector2i(1, 1)}
	texture_mappings[str(KEY_TAB)] = {pos = Vector2i(19, 5), size = Vector2i(2, 1)}  # 2 tiles wide
	
	# Xbox controller mappings
	texture_mappings["xbox_a"] = {pos = Vector2i(4, 0), size = Vector2i(1, 1)}
	texture_mappings["xbox_b"] = {pos = Vector2i(5, 0), size = Vector2i(1, 1)}
	texture_mappings["xbox_x"] = {pos = Vector2i(6, 0), size = Vector2i(1, 1)}
	texture_mappings["xbox_y"] = {pos = Vector2i(7, 0), size = Vector2i(1, 1)}
	texture_mappings["xbox_lb"] = {pos = Vector2i(9, 16), size = Vector2i(1, 1)}
	texture_mappings["xbox_rb"] = {pos = Vector2i(10, 16), size = Vector2i(1, 1)}
	texture_mappings["xbox_start"] = {pos = Vector2i(5, 18), size = Vector2i(1, 1)}
	texture_mappings["xbox_back"] = {pos = Vector2i(4, 18), size = Vector2i(1, 1)}
	texture_mappings["xbox_lt"] = {pos = Vector2i(8, 2), size = Vector2i(1, 1)}
	texture_mappings["xbox_rt"] = {pos = Vector2i(9, 2), size = Vector2i(1, 1)}
	texture_mappings["xbox_dpad_up"] = {pos = Vector2i(10, 2), size = Vector2i(1, 1)}
	texture_mappings["xbox_dpad_down"] = {pos = Vector2i(11, 2), size = Vector2i(1, 1)}
	texture_mappings["xbox_dpad_left"] = {pos = Vector2i(12, 2), size = Vector2i(1, 1)}
	texture_mappings["xbox_dpad_right"] = {pos = Vector2i(13, 2), size = Vector2i(1, 1)}
	
	# PlayStation controller mappings
	texture_mappings["ps_cross"] = {pos = Vector2i(23, 16), size = Vector2i(1, 1)}
	texture_mappings["ps_circle"] = {pos = Vector2i(19, 16), size = Vector2i(1, 1)}
	texture_mappings["ps_square"] = {pos = Vector2i(21, 16), size = Vector2i(1, 1)}
	texture_mappings["ps_triangle"] = {pos = Vector2i(17, 16), size = Vector2i(1, 1)}
	texture_mappings["ps_l1"] = {pos = Vector2i(25, 18), size = Vector2i(1, 1)}
	texture_mappings["ps_r1"] = {pos = Vector2i(26, 18), size = Vector2i(1, 1)}
	texture_mappings["ps_options"] = {pos = Vector2i(5, 18), size = Vector2i(1, 1)}
	texture_mappings["ps_share"] = {pos = Vector2i(4, 18), size = Vector2i(1, 1)}
	texture_mappings["ps_l2"] = {pos = Vector2i(8, 3), size = Vector2i(1, 1)}
	texture_mappings["ps_r2"] = {pos = Vector2i(9, 3), size = Vector2i(1, 1)}
	texture_mappings["ps_dpad_up"] = {pos = Vector2i(10, 3), size = Vector2i(1, 1)}
	texture_mappings["ps_dpad_down"] = {pos = Vector2i(11, 3), size = Vector2i(1, 1)}
	texture_mappings["ps_dpad_left"] = {pos = Vector2i(12, 3), size = Vector2i(1, 1)}
	texture_mappings["ps_dpad_right"] = {pos = Vector2i(13, 3), size = Vector2i(1, 1)}
	
	# Nintendo Switch controller mappings
	texture_mappings["switch_b"] = {pos = Vector2i(14, 0), size = Vector2i(1, 1)}
	texture_mappings["switch_a"] = {pos = Vector2i(13, 0), size = Vector2i(1, 1)}
	texture_mappings["switch_y"] = {pos = Vector2i(16, 0), size = Vector2i(1, 1)}
	texture_mappings["switch_x"] = {pos = Vector2i(15, 0), size = Vector2i(1, 1)}
	texture_mappings["switch_l"] = {pos = Vector2i(15, 18), size = Vector2i(1, 1)}
	texture_mappings["switch_r"] = {pos = Vector2i(16, 18), size = Vector2i(1, 1)}
	texture_mappings["switch_plus"] = {pos = Vector2i(5, 20), size = Vector2i(1, 1)}
	texture_mappings["switch_minus"] = {pos = Vector2i(4, 20), size = Vector2i(1, 1)}
	texture_mappings["switch_zl"] = {pos = Vector2i(8, 4), size = Vector2i(1, 1)}
	texture_mappings["switch_zr"] = {pos = Vector2i(9, 4), size = Vector2i(1, 1)}
	texture_mappings["switch_dpad_up"] = {pos = Vector2i(10, 4), size = Vector2i(1, 1)}
	texture_mappings["switch_dpad_down"] = {pos = Vector2i(11, 4), size = Vector2i(1, 1)}
	texture_mappings["switch_dpad_left"] = {pos = Vector2i(12, 4), size = Vector2i(1, 1)}
	texture_mappings["switch_dpad_right"] = {pos = Vector2i(13, 4), size = Vector2i(1, 1)}
	
	# Steam Deck controller mappings
	texture_mappings["steamdeck_a"] = {pos = Vector2i(4, 0), size = Vector2i(1, 1)}
	texture_mappings["steamdeck_b"] = {pos = Vector2i(5, 0), size = Vector2i(1, 1)}
	texture_mappings["steamdeck_x"] = {pos = Vector2i(6, 0), size = Vector2i(1, 1)}
	texture_mappings["steamdeck_y"] = {pos = Vector2i(7, 0), size = Vector2i(1, 1)}
	texture_mappings["steamdeck_l1"] = {pos = Vector2i(25, 18), size = Vector2i(1, 1)}
	texture_mappings["steamdeck_r1"] = {pos = Vector2i(26, 18), size = Vector2i(1, 1)}
	texture_mappings["steamdeck_menu"] = {pos = Vector2i(5, 18), size = Vector2i(1, 1)}
	texture_mappings["steamdeck_view"] = {pos = Vector2i(4, 18), size = Vector2i(1, 1)}
	texture_mappings["steamdeck_l2"] = {pos = Vector2i(8, 5), size = Vector2i(1, 1)}
	texture_mappings["steamdeck_r2"] = {pos = Vector2i(9, 5), size = Vector2i(1, 1)}
	texture_mappings["steamdeck_dpad_up"] = {pos = Vector2i(10, 5), size = Vector2i(1, 1)}
	texture_mappings["steamdeck_dpad_down"] = {pos = Vector2i(11, 5), size = Vector2i(1, 1)}
	texture_mappings["steamdeck_dpad_left"] = {pos = Vector2i(12, 5), size = Vector2i(1, 1)}
	texture_mappings["steamdeck_dpad_right"] = {pos = Vector2i(13, 5), size = Vector2i(1, 1)}
	texture_mappings["steamdeck_l4"] = {pos = Vector2i(14, 5), size = Vector2i(1, 1)}  # Back paddle
	texture_mappings["steamdeck_r4"] = {pos = Vector2i(15, 5), size = Vector2i(1, 1)}  # Back paddle
	texture_mappings["steamdeck_l5"] = {pos = Vector2i(16, 5), size = Vector2i(1, 1)}  # Back paddle
	texture_mappings["steamdeck_r5"] = {pos = Vector2i(17, 5), size = Vector2i(1, 1)}  # Back paddle
	texture_mappings["steamdeck_trackpad_left"] = {pos = Vector2i(18, 5), size = Vector2i(1, 1)}
	texture_mappings["steamdeck_trackpad_right"] = {pos = Vector2i(19, 5), size = Vector2i(1, 1)}
	
	# Steam Controller mappings (row 6)
	texture_mappings["steam_controller_a"] = {pos = Vector2i(4, 0), size = Vector2i(1, 1)}
	texture_mappings["steam_controller_b"] = {pos = Vector2i(5, 0), size = Vector2i(1, 1)}
	texture_mappings["steam_controller_x"] = {pos = Vector2i(6, 0), size = Vector2i(1, 1)}
	texture_mappings["steam_controller_y"] = {pos = Vector2i(7, 0), size = Vector2i(1, 1)}
	texture_mappings["steam_controller_lb"] = {pos = Vector2i(9, 16), size = Vector2i(1, 1)}
	texture_mappings["steam_controller_rb"] = {pos = Vector2i(10, 16), size = Vector2i(1, 1)}
	texture_mappings["steam_controller_start"] = {pos = Vector2i(5, 18), size = Vector2i(1, 1)}
	texture_mappings["steam_controller_back"] = {pos = Vector2i(4, 18), size = Vector2i(1, 1)}
	texture_mappings["steam_controller_lt"] = {pos = Vector2i(8, 6), size = Vector2i(1, 1)}
	texture_mappings["steam_controller_rt"] = {pos = Vector2i(9, 6), size = Vector2i(1, 1)}
	texture_mappings["steam_controller_trackpad_left"] = {pos = Vector2i(10, 6), size = Vector2i(1, 1)}
	texture_mappings["steam_controller_trackpad_right"] = {pos = Vector2i(11, 6), size = Vector2i(1, 1)}
	
	# Generic controller fallbacks (row 7)
	texture_mappings["generic_0"] = {pos = Vector2i(6, 11), size = Vector2i(1, 1)}
	texture_mappings["generic_1"] = {pos = Vector2i(5, 11), size = Vector2i(1, 1)}
	texture_mappings["generic_2"] = {pos = Vector2i(4, 11), size = Vector2i(1, 1)}
	texture_mappings["generic_3"] = {pos = Vector2i(7, 11), size = Vector2i(1, 1)}
	texture_mappings["generic_4"] = {pos = Vector2i(9, 16), size = Vector2i(1, 1)}
	texture_mappings["generic_5"] = {pos = Vector2i(10, 16), size = Vector2i(1, 1)}
	texture_mappings["generic_6"] = {pos = Vector2i(5, 18), size = Vector2i(1, 1)}
	texture_mappings["generic_7"] = {pos = Vector2i(4, 18), size = Vector2i(1, 1)}

func get_hint_texture(input_event: InputEvent, device_info: Dictionary) -> Texture2D:
	if not hint_spritesheet:
		return null
	
	var mapping_key = get_mapping_key(input_event, device_info)
	if not texture_mappings.has(mapping_key):
		return null
	
	var mapping_data = texture_mappings[mapping_key]
	return create_texture_from_spritesheet(mapping_data.pos, mapping_data.size)

func get_mapping_key(input_event: InputEvent, device_info: Dictionary) -> String:
	if input_event is InputEventKey:
		return str(input_event.physical_keycode if input_event.physical_keycode != 0 else input_event.keycode )
	elif input_event is InputEventJoypadButton:
		var controller_type = device_info.get("type", "generic")
		var button_index = input_event.button_index
		var is_steamdeck = device_info.get("is_steamdeck", false)
		
		# Prioritize Steam Deck detection over generic controller type
		if is_steamdeck or controller_type == "steamdeck":
			return get_steamdeck_button_name(button_index)
		
		match controller_type:
			"xbox":
				return get_xbox_button_name(button_index)
			"playstation":
				return get_playstation_button_name(button_index)
			"nintendo":
				return get_nintendo_button_name(button_index)
			"steam_controller":
				return get_steam_controller_button_name(button_index)
			_:
				return get_generic_button_name(button_index)
	
	return ""

func get_xbox_button_name(button_index: int) -> String:
	match button_index:
		JOY_BUTTON_A: return "xbox_a"
		JOY_BUTTON_B: return "xbox_b"
		JOY_BUTTON_X: return "xbox_x"
		JOY_BUTTON_Y: return "xbox_y"
		JOY_BUTTON_LEFT_SHOULDER: return "xbox_lb"
		JOY_BUTTON_RIGHT_SHOULDER: return "xbox_rb"
		JOY_BUTTON_START: return "xbox_start"
		JOY_BUTTON_BACK: return "xbox_back"
		JOY_BUTTON_LEFT_STICK: return "xbox_ls"
		JOY_BUTTON_RIGHT_STICK: return "xbox_rs"
		JOY_BUTTON_DPAD_UP: return "xbox_dpad_up"
		JOY_BUTTON_DPAD_DOWN: return "xbox_dpad_down"
		JOY_BUTTON_DPAD_LEFT: return "xbox_dpad_left"
		JOY_BUTTON_DPAD_RIGHT: return "xbox_dpad_right"
		_: return "xbox_" + str(button_index)

func get_playstation_button_name(button_index: int) -> String:
	match button_index:
		JOY_BUTTON_A: return "ps_cross"  # Bottom button
		JOY_BUTTON_B: return "ps_circle"  # Right button
		JOY_BUTTON_X: return "ps_square"  # Left button
		JOY_BUTTON_Y: return "ps_triangle"  # Top button
		JOY_BUTTON_LEFT_SHOULDER: return "ps_l1"
		JOY_BUTTON_RIGHT_SHOULDER: return "ps_r1"
		JOY_BUTTON_START: return "ps_options"
		JOY_BUTTON_BACK: return "ps_share"
		JOY_BUTTON_LEFT_STICK: return "ps_l3"
		JOY_BUTTON_RIGHT_STICK: return "ps_r3"
		JOY_BUTTON_DPAD_UP: return "ps_dpad_up"
		JOY_BUTTON_DPAD_DOWN: return "ps_dpad_down"
		JOY_BUTTON_DPAD_LEFT: return "ps_dpad_left"
		JOY_BUTTON_DPAD_RIGHT: return "ps_dpad_right"
		_: return "ps_" + str(button_index)

func get_nintendo_button_name(button_index: int) -> String:
	match button_index:
		JOY_BUTTON_A: return "switch_b"  # Nintendo layout is different
		JOY_BUTTON_B: return "switch_a"
		JOY_BUTTON_X: return "switch_y"
		JOY_BUTTON_Y: return "switch_x"
		JOY_BUTTON_LEFT_SHOULDER: return "switch_l"
		JOY_BUTTON_RIGHT_SHOULDER: return "switch_r"
		JOY_BUTTON_START: return "switch_plus"
		JOY_BUTTON_BACK: return "switch_minus"
		JOY_BUTTON_LEFT_STICK: return "switch_ls"
		JOY_BUTTON_RIGHT_STICK: return "switch_rs"
		JOY_BUTTON_DPAD_UP: return "switch_dpad_up"
		JOY_BUTTON_DPAD_DOWN: return "switch_dpad_down"
		JOY_BUTTON_DPAD_LEFT: return "switch_dpad_left"
		JOY_BUTTON_DPAD_RIGHT: return "switch_dpad_right"
		_: return "switch_" + str(button_index)

func get_steamdeck_button_name(button_index: int) -> String:
	match button_index:
		JOY_BUTTON_A: return "steamdeck_a"
		JOY_BUTTON_B: return "steamdeck_b"
		JOY_BUTTON_X: return "steamdeck_x"
		JOY_BUTTON_Y: return "steamdeck_y"
		JOY_BUTTON_LEFT_SHOULDER: return "steamdeck_l1"
		JOY_BUTTON_RIGHT_SHOULDER: return "steamdeck_r1"
		JOY_BUTTON_START: return "steamdeck_menu"
		JOY_BUTTON_BACK: return "steamdeck_view"
		JOY_BUTTON_LEFT_STICK: return "steamdeck_ls"
		JOY_BUTTON_RIGHT_STICK: return "steamdeck_rs"
		JOY_BUTTON_DPAD_UP: return "steamdeck_dpad_up"
		JOY_BUTTON_DPAD_DOWN: return "steamdeck_dpad_down"
		JOY_BUTTON_DPAD_LEFT: return "steamdeck_dpad_left"
		JOY_BUTTON_DPAD_RIGHT: return "steamdeck_dpad_right"
		# Steam Deck specific buttons (these might vary based on how Steam Input maps them)
		14: return "steamdeck_l4"  # Back paddle
		15: return "steamdeck_r4"  # Back paddle
		16: return "steamdeck_l5"  # Back paddle
		17: return "steamdeck_r5"  # Back paddle
		18: return "steamdeck_trackpad_left"
		19: return "steamdeck_trackpad_right"
		_: return "steamdeck_" + str(button_index)

func get_steam_controller_button_name(button_index: int) -> String:
	match button_index:
		JOY_BUTTON_A: return "steam_controller_a"
		JOY_BUTTON_B: return "steam_controller_b"
		JOY_BUTTON_X: return "steam_controller_x"
		JOY_BUTTON_Y: return "steam_controller_y"
		JOY_BUTTON_LEFT_SHOULDER: return "steam_controller_lb"
		JOY_BUTTON_RIGHT_SHOULDER: return "steam_controller_rb"
		JOY_BUTTON_START: return "steam_controller_start"
		JOY_BUTTON_BACK: return "steam_controller_back"
		JOY_BUTTON_LEFT_STICK: return "steam_controller_ls"
		JOY_BUTTON_RIGHT_STICK: return "steam_controller_rs"
		_: return "steam_controller_" + str(button_index)

func get_generic_button_name(button_index: int) -> String:
	if button_index <= 7:
		return "generic_" + str(button_index)
	else:
		return "generic_" + str(button_index % 8)

# Helper function to handle trigger inputs (analog triggers)
func get_trigger_hint_texture(trigger_axis: int, device_info: Dictionary) -> Texture2D:
	if not hint_spritesheet:
		return null
	
	var controller_type = device_info.get("type", "generic")
	var is_steamdeck = device_info.get("is_steamdeck", false)
	var mapping_key = ""
	
	if is_steamdeck or controller_type == "steamdeck":
		mapping_key = "steamdeck_l2" if trigger_axis == JOY_AXIS_TRIGGER_LEFT else "steamdeck_r2"
	elif controller_type == "xbox":
		mapping_key = "xbox_lt" if trigger_axis == JOY_AXIS_TRIGGER_LEFT else "xbox_rt"
	elif controller_type == "playstation":
		mapping_key = "ps_l2" if trigger_axis == JOY_AXIS_TRIGGER_LEFT else "ps_r2"
	elif controller_type == "nintendo":
		mapping_key = "switch_zl" if trigger_axis == JOY_AXIS_TRIGGER_LEFT else "switch_zr"
	elif controller_type == "steam_controller":
		mapping_key = "steam_controller_lt" if trigger_axis == JOY_AXIS_TRIGGER_LEFT else "steam_controller_rt"
	
	if mapping_key != "" and texture_mappings.has(mapping_key):
		var mapping_data = texture_mappings[mapping_key]
		return create_texture_from_spritesheet(mapping_data.pos, mapping_data.size)
	
	return null

func create_texture_from_spritesheet(sprite_pos: Vector2i, sprite_count: Vector2i) -> Texture2D:
	# For single tiles, use simple AtlasTexture
	if sprite_count.x == 1 and sprite_count.y == 1:
		var atlas_texture = AtlasTexture.new()
		atlas_texture.atlas = hint_spritesheet
		
		# Calculate position accounting for gaps
		var x = sprite_pos.x * (sprite_size.x + sprite_gap)
		var y = sprite_pos.y * (sprite_size.y + sprite_gap)
		
		atlas_texture.region = Rect2i(x, y, sprite_size.x, sprite_size.y)
		return atlas_texture
	
	# For multi-tile sprites, we need to composite them without gaps
	var final_width = sprite_count.x * sprite_size.x
	var final_height = sprite_count.y * sprite_size.y
	
	# Create a new ImageTexture to composite the tiles
	var composite_image = Image.create(final_width, final_height, false, Image.FORMAT_RGBA8)
	var source_image = hint_spritesheet.get_image()
	
	# Copy each tile individually, skipping gaps
	for tile_y in range(sprite_count.y):
		for tile_x in range(sprite_count.x):
			# Calculate source position for this tile (including gaps)
			var source_x = (sprite_pos.x + tile_x) * (sprite_size.x + sprite_gap)
			var source_y = (sprite_pos.y + tile_y) * (sprite_size.y + sprite_gap)
			
			# Calculate destination position (no gaps)
			var dest_x = tile_x * sprite_size.x
			var dest_y = tile_y * sprite_size.y
			
			# Copy this tile
			var tile_rect = Rect2i(source_x, source_y, sprite_size.x, sprite_size.y)
			composite_image.blit_rect(source_image, tile_rect, Vector2i(dest_x, dest_y))
	
	# Create texture from the composite image
	var composite_texture = ImageTexture.new()
	composite_texture.set_image(composite_image)
	return composite_texture
