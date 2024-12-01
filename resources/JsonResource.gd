class_name JsonResource
extends RefCounted


func to_json():
	var properties = get_property_list()
	var data = {}
	for property in properties:
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and not property.name.begins_with("_"):
			data[property.name] = self[property.name]
	return JSON.stringify(data)

func save_to_file(path: String):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(to_json())

func load_from_file(path: String):
	if not FileAccess.file_exists(path):
		return
	var file = FileAccess.open(path, FileAccess.READ)
	from_dictionary(JSON.parse_string(file.get_as_text()))

func from_dictionary(data: Dictionary):
	var properties = get_property_list()
	for property in properties:
		if property.usage == PROPERTY_USAGE_SCRIPT_VARIABLE and not property.name.begins_with("_"):
			if property.name in data:
				self[property.name] = data[property.name]
