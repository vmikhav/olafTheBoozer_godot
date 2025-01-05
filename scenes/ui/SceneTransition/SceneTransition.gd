extends ColorRect

func fade_in(duration: float = 0.5):
	modulate.a8 = 255
	if SettingsManager.clear_color:
		RenderingServer.set_default_clear_color(SettingsManager.clear_color)
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color8(255, 255, 255, 0), duration)
	await tween.finished

func fade_out(duration: float = 0.5):
	SettingsManager.clear_color = RenderingServer.get_default_clear_color()
	modulate.a8 = 0
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color8(255, 255, 255, 255), duration)
	await tween.finished
	RenderingServer.set_default_clear_color(Color.BLACK)

func change_scene(scene: String, params = null):
	await fade_out()
	SceneSwitcher.change_scene_to_file(scene, params)
