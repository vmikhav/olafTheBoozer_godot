extends Node2D

@onready var lyricsLabel = %LyricsLabel
@onready var world = $WorldMap
@onready var tavern = $Tavern
var world_duration = 5.75
var world_positionA = Vector2(-1035, -400)
var world_positionB = Vector2(120, 200)
var world_positionC = Vector2(-500, 10)
var t = 0
var phase = ""
var lyrics = -1

var song: Array[String] = [
	"Olaf the Boozer, with a beard full of crumbs",
	"Wakes in a tavern, feeling quite numb",
	"Last night's a blank slate, a hangover's worst fear,",
	"Did he cause some trouble?",
	"Did he drink all the beer?",
	"Roll back the time, retrace every track,",
	"Find the lost moments, bring them all back.",
	"Clues are around him, a boozy trail leads,",
	"Can Olaf the Boozer undo all his deeds?",
	"Wishlist 'Olaf the Boozer' on Steam!",
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().create_timer(10).timeout.connect(func():
		play()
	)

func play() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), true)
	$Wishlist/CanvasLayer.visible = false
	
	$Playground1/TouchCamera.zoom = Vector2(3, 3)
	$Playground1.load_level("Library")
	$Playground1/UiLayer.visible = false
	$Playground1/TouchCamera.enabled = false
	$Playground1.level.move_hero_to_position(Vector2(19, 7))
	
	$Playground2/TouchCamera.zoom = Vector2(3, 3)
	$Playground2.load_level("Kitchen")
	$Playground2/UiLayer.visible = false
	$Playground2/TouchCamera.enabled = false
	$Playground2.level.move_hero_to_position(Vector2(11, 8))
	
	$Playground3/TouchCamera.zoom = Vector2(3, 3)
	$Playground3.load_level("Library")
	$Playground3/UiLayer.visible = false
	$Playground3/TouchCamera.enabled = false
	$Playground3.level.move_hero_to_position(Vector2(11, 12))
	
	$Playground4/TouchCamera.zoom = Vector2(3, 3)
	$Playground4.load_level("Tutorial0")
	$Playground4/UiLayer.visible = false
	$Playground4/TouchCamera.enabled = false
	
	
	var tween = get_tree().create_tween()
	tween.tween_interval(6.5)
	tween.tween_property(world, "modulate", Color(1, 1, 1, 0), .5)
	tween.parallel().tween_property(tavern, "position", Vector2(0, 0), 6)
	var tween2 = get_tree().create_tween()
	tween2.tween_interval(11.5)
	tween2.tween_property($Tavern/Roof, "modulate", Color(1, 1, 1, 0), 1)
	tween2.parallel().tween_callback(tavern.run)
	tween.tween_interval(.5)
	tween.tween_property(tavern, "scale", Vector2(4, 4), 4)
	tween.parallel().tween_property(tavern, "position", Vector2(-130, -50), 4)
	
	get_tree().create_timer(1).timeout.connect(func():
		phase = "world"
		$AudioStreamPlayer.play()
		switch_lyrics()
	)
	get_tree().create_timer(7).timeout.connect(func():
		phase = "tavern"
		switch_lyrics()
	)
	get_tree().create_timer(13).timeout.connect(func():
		switch_lyrics()
	)
	get_tree().create_timer(18.5).timeout.connect(func():
		switch_lyrics()
		var tween3 = get_tree().create_tween()
		tween3.tween_interval(.5)
		tween3.tween_property(tavern, "scale", Vector2(5, 5), 1)
		tween3.parallel().tween_property(tavern, "position", Vector2(130, -100), 1)
		tween3.parallel().tween_property($Tavern/FixedItems, "modulate", Color(1, 1, 1, 1), 1)
		tween3.parallel().tween_property($Tavern/BrokenItems, "modulate", Color(1, 1, 1, 0), 1)
		tween3.tween_interval(1)
		tween3.tween_property($Tavern/FixedItems, "modulate", Color(1, 1, 1, 0), 1)
		tween3.parallel().tween_property($Tavern/BrokenItems, "modulate", Color(1, 1, 1, 1), 1)
	)
	get_tree().create_timer(21.5).timeout.connect(func():
		switch_lyrics()
		var tween3 = get_tree().create_tween()
		tween3.tween_interval(0.5)
		tween3.tween_property(tavern, "position", Vector2(-350, -100), .75)
		tween3.tween_interval(0.25)
		tween3.parallel().tween_property($Tavern/FixedDrinks, "modulate", Color(1, 1, 1, 1), 1)
		tween3.parallel().tween_property($Tavern/BrokenDrinks, "modulate", Color(1, 1, 1, 0), 1)
		tween3.tween_interval(1)
		tween3.tween_property($Tavern/FixedDrinks, "modulate", Color(1, 1, 1, 0), 1)
		tween3.parallel().tween_property($Tavern/BrokenDrinks, "modulate", Color(1, 1, 1, 1), 1)
		tween3.tween_interval(.1)
		tween3.tween_property(tavern, "modulate", Color(1, 1, 1, 0), .25)
	)
	get_tree().create_timer(26).timeout.connect(func():
		switch_lyrics()
		await get_tree().create_timer(.5).timeout
		$Playground1.modulate = Color(1, 1, 1, 0)
		$Playground1.visible = true
		$Playground1/TouchCamera.enabled = true
		$Playground1/TouchCamera.go_to($Playground1.level.hero.position, true)
		$Playground1/TouchCamera.reset_smoothing()
		$Playground1/TouchCamera.make_current()
		$Camera2D.enabled = false
		var playgroud = $Playground1
		var tween3 = get_tree().create_tween()
		#tween3.tween_interval(0.5)
		tween3.tween_property(playgroud, "modulate", Color(1, 1, 1, 1), .25)
		tween3.tween_callback(playgroud.move_hero.bind("ui_up"))
		tween3.tween_interval(0.3)
		tween3.tween_callback(playgroud.move_hero.bind("ui_right"))
		tween3.tween_interval(0.25)
		tween3.tween_callback(playgroud.move_hero.bind("ui_down"))
		tween3.tween_interval(0.3)
		tween3.tween_callback(playgroud.move_hero.bind("ui_down"))
		tween3.tween_interval(0.25)
		tween3.tween_callback(playgroud.move_hero.bind("ui_left"))
		tween3.tween_interval(0.3)
		tween3.tween_callback(playgroud.move_hero.bind("ui_down"))
		tween3.tween_interval(0.25)
		tween3.tween_callback(playgroud.move_hero.bind("ui_down"))
		tween3.tween_interval(0.3)
		tween3.tween_callback(playgroud.move_hero.bind("ui_right"))
		tween3.tween_interval(0.3)
		tween3.tween_callback(playgroud.move_hero.bind("ui_up"))
		tween3.tween_interval(0.1)
		tween3.tween_property(playgroud, "modulate", Color(1, 1, 1, 0), .35)
	)
	get_tree().create_timer(29).timeout.connect(func():
		switch_lyrics()
		await get_tree().create_timer(.5).timeout
		$Playground2.modulate = Color(1, 1, 1, 0)
		$Playground2.visible = true
		$Playground2/TouchCamera.enabled = true
		$Playground2/TouchCamera.go_to($Playground2.level.hero.position, true)
		$Playground2/TouchCamera.reset_smoothing()
		$Playground2/TouchCamera.make_current()
		$Playground1/TouchCamera.enabled = false
		var playgroud = $Playground2
		var tween3 = get_tree().create_tween()
		#tween3.tween_interval(0.5)
		tween3.tween_property(playgroud, "modulate", Color(1, 1, 1, 1), .25)
		tween3.tween_callback(playgroud.move_hero.bind("ui_right"))
		tween3.tween_interval(0.3)
		tween3.tween_callback(playgroud.move_hero.bind("ui_right"))
		tween3.tween_interval(0.25)
		tween3.tween_callback(playgroud.move_hero.bind("ui_right"))
		tween3.tween_interval(0.3)
		tween3.tween_callback(playgroud.move_hero.bind("ui_right"))
		tween3.tween_interval(0.25)
		tween3.tween_callback(playgroud.move_hero.bind("ui_right"))
		tween3.tween_interval(0.3)
		tween3.tween_callback(playgroud.move_hero.bind("ui_up"))
		tween3.tween_interval(0.25)
		tween3.tween_callback(playgroud.move_hero.bind("ui_up"))
		tween3.tween_interval(0.3)
		tween3.tween_callback(playgroud.move_hero.bind("ui_right"))
		tween3.tween_interval(0.3)
		tween3.tween_callback(playgroud.move_hero.bind("ui_right"))
		tween3.tween_interval(0.3)
		tween3.tween_property(playgroud, "modulate", Color(1, 1, 1, 0), .35)
	)
	get_tree().create_timer(32.5).timeout.connect(func():
		switch_lyrics()
		await get_tree().create_timer(.5).timeout
		$Playground3.modulate = Color(1, 1, 1, 0)
		$Playground3.visible = true
		$Playground3/TouchCamera.enabled = true
		$Playground3/TouchCamera.go_to($Playground3.level.hero.position, true)
		$Playground3/TouchCamera.reset_smoothing()
		$Playground3/TouchCamera.make_current()
		$Playground2/TouchCamera.enabled = false
		var playgroud = $Playground3
		var tween3 = get_tree().create_tween()
		#tween3.tween_interval(0.5)
		tween3.tween_property(playgroud, "modulate", Color(1, 1, 1, 1), .25)
		tween3.tween_callback(playgroud.move_hero.bind("ui_left"))
		tween3.tween_interval(0.3)
		tween3.tween_callback(playgroud.move_hero.bind("ui_up"))
		tween3.tween_interval(0.25)
		tween3.tween_callback(playgroud.move_hero.bind("ui_up"))
		tween3.tween_interval(0.3)
		tween3.tween_callback(playgroud.move_hero.bind("ui_up"))
		tween3.tween_interval(1.5)
		tween3.tween_property(playgroud, "modulate", Color(1, 1, 1, 0), .35)
	)
	get_tree().create_timer(36).timeout.connect(func():
		switch_lyrics()
		await get_tree().create_timer(.5).timeout
		$Playground4.modulate = Color(1, 1, 1, 0)
		$Playground4.visible = true
		$Playground4/TouchCamera.enabled = true
		$Playground4/TouchCamera.go_to($Playground4.level.hero.position, true)
		$Playground4/TouchCamera.reset_smoothing()
		$Playground4/TouchCamera.make_current()
		$Playground3/TouchCamera.enabled = false
		var playgroud = $Playground4
		var tween3 = get_tree().create_tween()
		#tween3.tween_interval(0.5)
		tween3.tween_property(playgroud, "modulate", Color(1, 1, 1, 1), .25)
		tween3.tween_callback(playgroud.move_hero.bind("ui_left"))
		tween3.tween_interval(0.3)
		tween3.tween_callback(playgroud.move_hero.bind("ui_left"))
		tween3.tween_interval(0.3)
		tween3.tween_callback(playgroud.move_hero.bind("ui_left"))
		tween3.tween_interval(0.3)
		tween3.tween_callback(playgroud.move_hero.bind("ui_right"))
		tween3.tween_interval(0.25)
		tween3.tween_callback(playgroud.move_hero.bind("ui_right"))
		tween3.tween_interval(0.25)
		tween3.tween_callback(playgroud.move_hero.bind("ui_down"))
		tween3.tween_interval(0.3)
		tween3.tween_callback(playgroud.move_hero.bind("ui_right"))
		tween3.tween_interval(0.25)
		tween3.tween_callback(playgroud.move_hero.bind("ui_up"))
		tween3.tween_interval(0.3)
		tween3.tween_callback(playgroud.move_hero.bind("ui_right"))
		tween3.tween_interval(0.25)
		tween3.tween_callback(playgroud.move_hero.bind("ui_down"))
		tween3.tween_interval(0.35)
		tween3.tween_callback(playgroud.move_hero.bind("ui_right"))
		tween3.tween_property(playgroud, "modulate", Color(1, 1, 1, 0), .35)
	)
	get_tree().create_timer(40).timeout.connect(func():
		switch_lyrics()
		await get_tree().create_timer(.5).timeout
		$Camera2D.enabled = true
		$Camera2D.make_current()
		$Playground4/TouchCamera.enabled = false
		$Wishlist/CanvasLayer/CanvasModulate.color = Color(1, 1, 1, 0)
		$Wishlist.visible = true
		$Wishlist/CanvasLayer.visible = true
		var tween3 = get_tree().create_tween()
		tween3.tween_property($Wishlist/CanvasLayer/CanvasModulate, "color", Color(1, 1, 1, 1), .25)
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if phase == "world":
		t += delta / world_duration
		var q0 = world_positionA.lerp(world_positionC, min(t, 1.0))
		var q1 = world_positionC.lerp(world_positionB, min(t, 1.0))
		world.position = q0.lerp(q1, min(t, 1.0))

func switch_lyrics():
	var tween = get_tree().create_tween()
	if lyrics >= 0:
		tween.tween_property(lyricsLabel, "modulate", Color(1, 1, 1, 0), .25)
	if lyrics < song.size() - 1:
		tween.tween_callback(func():
			lyrics += 1
			lyricsLabel.text = song[lyrics]
		)
		tween.tween_interval(0.1)
		tween.tween_property(lyricsLabel, "modulate", Color(1, 1, 1, 1), .25)
	
