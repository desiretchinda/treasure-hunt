# Extends the Control node
class_name WinPanel extends Control

static var instance:WinPanel

# Get references to child nodes using @onready
@onready var play_again_button: Button = $Panel/RestartButton
@onready var play_next_button: Button = $Panel/NextButton
@onready var quit_button: TextureButton = $Panel/CloseButton
@onready var stream_player: AudioStreamPlayer2D = $StreamPlayer

func _ready():
	instance = self
	# Hide the panel by default
	
	# Connect button signals
	if play_again_button:
		play_again_button.pressed.connect(_on_play_again_button_pressed)

	if play_next_button:
		play_next_button.pressed.connect(_on_play_next_button_pressed)

	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)
	
	hide()

# Shows the win panel
func show_panel():
	show()
	stream_player.play()
	# Pause the game when the win panel is shown
	get_tree().paused = true


# Hides the win panel
func hide_panel():
	hide()
	# Unpause the game when the win panel is hidden
	get_tree().paused = false


# Called when the "Play Again" button is pressed
func _on_play_again_button_pressed():
	SoundManager.play_click()
	get_tree().reload_current_scene()


# Called when the "Play Next" button is pressed
func _on_play_next_button_pressed():
	SoundManager.play_click()
	get_tree().reload_current_scene()

# Called when the "Play Next" button is pressed
func _on_quit_button_pressed():
	SoundManager.play_click()
	get_tree().change_scene_to_file("res://Scenes/main_scene.tscn")
