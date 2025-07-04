@tool

extends DialogueLabel

@export var short_pause_at_characters: String = ","

# Store word boundaries for word-by-word display
var _word_boundaries: Array = []
var _internal_char_counter: int = 0

# Override _type_next to implement word-by-word typing
func _type_next(delta: float, seconds_needed: float) -> void:
	if _is_awaiting_mutation: return

	if _internal_char_counter >= get_total_character_count():
		return

	# Initialize word parsing if needed
	if _word_boundaries.is_empty():
		_parse_words()

	# Handle mutations
	if _last_mutation_index != _internal_char_counter:
		_last_mutation_index = _internal_char_counter
		_mutate_inline_mutations(_internal_char_counter)
		if _is_awaiting_mutation: return
	
	# Handle pauses at the current position
	var additional_waiting_seconds: float = _get_pause(_internal_char_counter)
	
	# Pause on characters like "."
	if _internal_char_counter > 0 and get_parsed_text()[_internal_char_counter - 1] in pause_at_characters.split():
		var should_pause = true
		
		# Skip pause if followed by a non-pause character
		if _internal_char_counter < get_parsed_text().length() and get_parsed_text()[_internal_char_counter] in skip_pause_at_character_if_followed_by.split():
			should_pause = false
			
		# Skip pause for abbreviations
		if get_parsed_text()[_internal_char_counter - 1] == "." and _is_abbreviation(_internal_char_counter - 1):
			should_pause = false
			
		if should_pause:
			if get_parsed_text()[_internal_char_counter - 1] in short_pause_at_characters.split():
				additional_waiting_seconds += seconds_per_pause_step / 3
			else:
				additional_waiting_seconds += seconds_per_pause_step
	
	# Handle explicit waits
	if _last_wait_index != _internal_char_counter and additional_waiting_seconds > 0:
		_last_wait_index = _internal_char_counter
		_waiting_seconds += additional_waiting_seconds
		paused_typing.emit(_get_pause(_internal_char_counter))
		return
	
	# Find which word we're currently in
	var current_word_index = _find_word_index(_internal_char_counter)
	
	# If this is the first character of a new word, display the entire word
	if current_word_index >= 0 and _word_boundaries[current_word_index][0] == _internal_char_counter:
		visible_characters = _word_boundaries[current_word_index][1] + 1
	
	# Always emit the signal for the current character
	var parsed_text = get_parsed_text()
	if _internal_char_counter < parsed_text.length():
		spoke.emit(parsed_text[_internal_char_counter], _internal_char_counter, _get_speed(_internal_char_counter))
	
	# Move to the next character internally
	_internal_char_counter += 1
	
	# Add proper waiting time
	seconds_needed += seconds_per_step * (1.0 / _get_speed(_internal_char_counter - 1))
	if seconds_needed > delta:
		_waiting_seconds += seconds_needed
	else:
		_type_next(delta, seconds_needed)

# Find which word contains the given character index
# Returns the index in the _word_boundaries array or -1 if not found
func _find_word_index(char_index: int) -> int:
	for i in range(_word_boundaries.size()):
		var word_start = _word_boundaries[i][0]
		var word_end = _word_boundaries[i][1]
		if char_index >= word_start and char_index <= word_end:
			return i
	return -1

# Check if a period is part of an abbreviation
func _is_abbreviation(period_index: int) -> bool:
	if period_index < 1: return false
	
	var text = get_parsed_text()
	for abbreviation in skip_pause_at_abbreviations:
		if period_index >= abbreviation.length():
			var previous_chars = text.substr(period_index - abbreviation.length(), abbreviation.length())
			if previous_chars == abbreviation:
				return true
	return false

# Parse the text into words and store their boundaries
func _parse_words() -> void:
	_word_boundaries.clear()
	
	var parsed_text = get_parsed_text()
	var in_bbcode = false
	var in_word = false
	var word_start = 0
	
	for i in range(parsed_text.length()):
		var character = parsed_text[i]
		
		# Skip BBCode tags when determining word boundaries
		if character == "[":
			in_bbcode = true
			continue
		elif character == "]" and in_bbcode:
			in_bbcode = false
			continue
		elif in_bbcode:
			continue
		
		# Determine word boundaries
		if character.strip_edges() == "":  # Space or whitespace
			if in_word:
				_word_boundaries.append([word_start, i - 1])  # [start, end] of word
				in_word = false
		elif character in pause_at_characters.split():  # Pause character
			if in_word:
				_word_boundaries.append([word_start, i - 1])  # End before the pause character
				in_word = false
			
			# Add the pause character as its own "word"
			_word_boundaries.append([i, i])
		else:
			if not in_word:
				word_start = i
				in_word = true
	
	# Add the last word if there is one
	if in_word:
		_word_boundaries.append([word_start, parsed_text.length() - 1])

# Override type_out to reset word processing
func type_out() -> void:
	# Reset word-related variables
	_word_boundaries.clear()
	_internal_char_counter = 0
	
	# Call the parent implementation
	super.type_out()

# Override skip_typing to properly handle skipping
func skip_typing() -> void:
	# Make sure we've "processed" all characters
	_internal_char_counter = get_total_character_count()
	
	# Call the parent implementation
	super.skip_typing()
