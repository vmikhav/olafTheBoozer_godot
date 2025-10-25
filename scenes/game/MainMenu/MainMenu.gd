extends Node2D

@onready var play_button: Button = %Play
@onready var settings_button: Button = %Settings
@onready var wishlist_button: Button = %Wishlist
@onready var credits_button: Button = %Credits
@onready var exit_button: Button = %Exit
@onready var scene_transition = $UiLayer/SceneTransition
@onready var settings_menu = $UiLayer/SettingsMenu

var settings_visible = false

var base_size: Vector2
var base_position: Vector2
var idle_time := 0.0
var idle_speed := 2.0 # how fast it “breathes”
var idle_strength := 0.025 # how much it scales (5%)

# Called when the node enters the scene tree for the first time.
func _ready():
	AudioController.play_music('workshop')
	scene_transition.fade_in()
	play_button.grab_focus.call_deferred()
	play_button.pressed.connect(start_game)
	exit_button.pressed.connect(exit)
	wishlist_button.pressed.connect(open_steam)
	credits_button.pressed.connect(open_credits)
	settings_button.pressed.connect(open_settings)
	settings_menu.close.connect(close_settings)
	if OS.has_feature("web"):
		wishlist_button.hide()
		exit_button.hide()
	else:
		get_window().grab_focus()
	base_size = wishlist_button.size
	base_position = wishlist_button.position
	wishlist_button.pivot_offset = wishlist_button.size / 2

func _process(delta: float) -> void:
	# Apply gentle idle breathing animation when not hovered
	idle_time += delta * idle_speed
	var width_offset = max(base_size.x * sin(idle_time) * idle_strength, 0)
	wishlist_button.size.x = base_size.x + width_offset
	wishlist_button.position.x = base_position.x - (width_offset / 2)


func start_game():
	StoryProgress.clear_progress()
	#scene_transition.change_scene("res://scenes/game/Intro/Intro.tscn")
	#scene_transition.change_scene("res://scenes/world/WolrdMap/WorldMapInteractive.tscn")
	scene_transition.change_scene("res://scenes/game/AdventurePlayground/AdventurePlayground.tscn", {
		levels = ["Tutorial0"],
		#levels = ["Tutorial0", "Kitchen", "Library", "Cellar", "Tavern"],
	})

func open_credits():
	scene_transition.change_scene("res://scenes/ui/Credits/Credits.tscn", {})


func open_settings():
	#var tween = create_tween()
	#tween.tween_property($UiLayer/MarginContainer, "modulate", Color8(255, 255, 255, 0), .25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	#await tween.finished
	settings_menu.visible = true
	settings_visible = true
	settings_menu.init_modal()


func close_settings():
	settings_menu.visible = false
	settings_visible = false
	#var tween = create_tween()
	#tween.tween_property($UiLayer/MarginContainer, "modulate", Color8(255, 255, 255, 255), .25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	settings_button.grab_focus()

func open_steam():
	OS.shell_open("https://store.steampowered.com/app/3001110")

func exit():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
