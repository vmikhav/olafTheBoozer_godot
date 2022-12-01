extends ColorRect


func fade_in():
	modulate.a8 = 255
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color8(255, 255, 255, 0), 0.5)
	return tween

func fade_out():
	modulate.a8 = 0
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color8(255, 255, 255, 255), 0.5)
	return tween

func change_scene(scene: String, params = null):
	var tween = fade_out()
	await tween.finished
	SceneSwitcher.change_scene_to_file(scene, params)
