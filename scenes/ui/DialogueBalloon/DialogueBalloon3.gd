class_name DialogueBalloon3 extends CanvasLayer
## A basic dialogue balloon for use with Dialogue Manager.

@export var max_dialogue_width_inches: float = 13.3333  # Maximum width in physical inches
@export var min_scale_factor: float = 0.7  # Minimum scale to maintain readability

## The action to use for advancing the dialogue
@export var next_action: StringName = &"ui_accept"

## The action to use to skip typing the dialogue
@export var skip_action: StringName = &"ui_cancel"

## The dialogue resource
var resource: DialogueResource

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false

## See if we are running a long mutation and should hide the balloon
var will_hide_balloon: bool = false

## A dictionary to store any ephemeral variables
var locals: Dictionary = {}

var _locale: String = TranslationServer.get_locale()

## The current line
var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			# The dialogue has finished so close the balloon
			queue_free()
	get:
		return dialogue_line

## A cooldown timer for delaying the balloon hide when encountering a mutation.
var mutation_cooldown: Timer = Timer.new()

## The base balloon anchor
@onready var balloon: Control = %Balloon

## The label showing the name of the currently speaking character
@onready var character_label: RichTextLabel = %CharacterLabel

## The label showing the currently spoken dialogue
@onready var dialogue_label: DialogueLabel = %DialogueLabel

## The menu of responses
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu

@onready var input_hint: InputHint = %BaloonInputHint


func _ready() -> void:
	balloon.hide()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	# If the responses menu doesn't have a next action set, use this one
	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)
	
	dialogue_label.spoke.connect(func(letter: String, letter_index: int, speed: float):
		if letter_index == 0:
			SpeechController.set_character(dialogue_line.character)
		SpeechController.speak(letter)
	)
	call_deferred("adjust_dialogue_size")


func _unhandled_input(_event: InputEvent) -> void:
	# Only the balloon is allowed to handle input while it's showing
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	## Detect a change of locale and update the current dialogue line to show the new language
	if what == NOTIFICATION_TRANSLATION_CHANGED and _locale != TranslationServer.get_locale() and is_instance_valid(dialogue_label):
		_locale = TranslationServer.get_locale()
		var visible_ratio = dialogue_label.visible_ratio
		self.dialogue_line = await resource.get_next_dialogue_line(dialogue_line.id)
		if visible_ratio < 1:
			dialogue_label.skip_typing()


## Start some dialogue
func start(dialogue_resource: DialogueResource, title: String, extra_game_states: Array = []) -> void:
	if not is_node_ready():
		await ready
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	resource = dialogue_resource
	self.dialogue_line = await resource.get_next_dialogue_line(title, temporary_game_states)


## Apply any changes to the balloon given a new [DialogueLine].
func apply_dialogue_line() -> void:
	# If the node isn't ready yet then none of the labels will be ready yet either
	if not is_node_ready():
		await ready
	input_hint.visible = false

	mutation_cooldown.stop()

	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	character_label.visible = not dialogue_line.character.is_empty()
	character_label.text = tr(dialogue_line.character, "dialogue")

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses

	# Show our balloon
	balloon.show()
	will_hide_balloon = false

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	# Wait for input
	if dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
	elif dialogue_line.time != "":
		var time = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()
		input_hint.visible = true
		input_hint.modulate.a = 0
		await input_hint.position_hint()
		input_hint.modulate.a = 1


## Go to the next line
func next(next_id: String) -> void:
	self.dialogue_line = await resource.get_next_dialogue_line(next_id, temporary_game_states)


#region Signals


func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()


func _on_mutated(_mutation: Dictionary) -> void:
	is_waiting_for_input = false
	will_hide_balloon = true
	mutation_cooldown.start(0.1)


func _on_balloon_gui_input(event: InputEvent) -> void:
	# See if we need to skip typing of the dialogue
	if dialogue_label.is_typing:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	# When there are no response options the balloon itself is the clickable thing
	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)


#endregion


func adjust_dialogue_size2():
	var screen_dpi = DisplayServer.screen_get_dpi()

	# Calculate maximum allowed width in pixels based on physical size
	var max_width_px = max_dialogue_width_inches * screen_dpi
	print(screen_dpi)
	print(max_width_px)
	var size = get_window().size * (get_viewport().size.x / 1280.0)
	print(size)
	
	# Only scale down if dialogue would be too wide physically
	var scale_factor = min(max_width_px / size.x, 1.0)
	
	# Apply minimum scale to ensure readability
	scale_factor = max(scale_factor, min_scale_factor)
	
	if scale_factor < 1.0:
		var panel = $HSplitContainer/HSplitContainer/Balloon/Panel
		panel.pivot_offset = Vector2(panel.size.x * 0.5, panel.size.y)
		panel.scale = Vector2(scale_factor, scale_factor)

func adjust_dialogue_size():
	var screen_dpi = DisplayServer.screen_get_dpi()
	var max_width_px = max_dialogue_width_inches * screen_dpi
	
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_size = get_window().size
	var viewport_to_screen_ratio = minf(screen_size.y / viewport_size.y, screen_size.x / viewport_size.x)
	var max_width_viewport = max_width_px / viewport_to_screen_ratio
	
	var panel = $HSplitContainer/HSplitContainer/Balloon/Panel
	var original_width = panel.size.x
	
	if original_width > max_width_viewport:
		# Set the maximum width
		panel.custom_minimum_size.x = max_width_viewport
		panel.size.x = max_width_viewport
		panel.position.x += int((original_width - max_width_viewport) / 2)
		
		# Let height adjust automatically by setting size flags
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
