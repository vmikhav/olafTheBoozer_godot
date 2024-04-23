extends Node2D

@onready var lyricsLabel = %LyricsLabel
@onready var world = $WorldMap
@onready var tavern = $Tavern
var world_duration = 5.75
var world_positionA = Vector2(-1035, -400)
var world_positionB = Vector2(100, 200)
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
		tween3.tween_property(tavern, "position", Vector2(-330, -100), .75)
		tween3.tween_interval(0.5)
		tween3.parallel().tween_property($Tavern/FixedDrinks, "modulate", Color(1, 1, 1, 1), 1)
		tween3.parallel().tween_property($Tavern/BrokenDrinks, "modulate", Color(1, 1, 1, 0), 1)
		tween3.tween_interval(1)
		tween3.tween_property($Tavern/FixedDrinks, "modulate", Color(1, 1, 1, 0), 1)
		tween3.parallel().tween_property($Tavern/BrokenDrinks, "modulate", Color(1, 1, 1, 1), 1)
	)
	get_tree().create_timer(26).timeout.connect(func():
		switch_lyrics()
	)
	get_tree().create_timer(29).timeout.connect(func():
		switch_lyrics()
	)
	get_tree().create_timer(32.5).timeout.connect(func():
		switch_lyrics()
	)
	get_tree().create_timer(36).timeout.connect(func():
		switch_lyrics()
	)
	get_tree().create_timer(40).timeout.connect(func():
		switch_lyrics()
	)
	#tween.tween_property(world, "position", Vector2(-500, 10), 3.0).set_ease(Tween.EASE_OUT)
	#tween.tween_property(world, "position", Vector2(100, 200), 6.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)



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
	
