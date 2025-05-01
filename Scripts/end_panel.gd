# Extends the Control node
class_name WinPanel extends Control

static var instance:WinPanel

# Get references to child nodes using @onready
@onready var panel_container: Control = $Panel
@onready var play_again_button: Button = $Panel/RestartButton
@onready var play_next_button: Button = $Panel/NextButton
@onready var quit_button: TextureButton = $Panel/CloseButton
@onready var stream_player: AudioStreamPlayer = $StreamPlayer

# Removed: @onready var tween_node: Tween = $Tween # No longer add Tween node in editor


func _ready():
	instance = self

	# Connect button signals
	if play_again_button:
		play_again_button.pressed.connect(_on_play_again_button_pressed)

	if play_next_button:
		play_next_button.pressed.connect(_on_play_next_button_pressed)

	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)

	# Hide the panel by default and set initial state for tween
	modulate = Color(1, 1, 1, 0) # Start fully transparent for fading in
	hide()


# Shows the win panel with a tween animation
func show_panel():
	show() # Make the panel visible (it will be transparent initially)
	stream_player.play() # Play sound

	# Create a new tween instance
	var tween = create_tween()
	# Ensure the tween is stopped before starting a new one (though create_tween gives a new one each time)
	# tween.kill() # Not strictly necessary with create_tween() but can be useful if reusing tweens

	# Tween the modulate property from current (transparent) to fully opaque
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.5)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_QUAD)

	#also tween scale for a pop-in effect
	if panel_container: # Check if panel_container exists
		panel_container.scale = Vector2(0.8, 0.8)
		tween.tween_property(panel_container, "scale", Vector2(1.0, 1.0), 0.5)\
	 		.set_ease(Tween.EASE_OUT)\
	 		.set_trans(Tween.TRANS_BACK) # Or TRANS_ELASTIC, etc.


# Hides the win panel with a tween animation
func hide_panel():
	# Create a new tween instance for hiding
	var tween = create_tween()

	# Tween out before hiding completely
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.3)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_QUAD)

	# Connect the finished signal to hide the panel and unpause the game after the tween
	tween.finished.connect(_on_hide_tween_finished)


# Called when the hide tween animation finishes
func _on_hide_tween_finished():
	hide()
	get_tree().paused = false # Unpause the game


# Called when the "Play Again" button is pressed
func _on_play_again_button_pressed():
	# Assuming SoundManager is an Autoload
	if SoundManager:
		SoundManager.play_click()
	get_tree().reload_current_scene()


# Called when the "Play Next" button is pressed
func _on_play_next_button_pressed():
	# Assuming SoundManager is an Autoload
	if SoundManager:
		SoundManager.play_click()
	# Assuming GameManager is an Autoload
	if GameManager:
		GameManager.level += 1
		GameManager.save_game()
	get_tree().reload_current_scene()


# Called when the "Quit" button is pressed
func _on_quit_button_pressed():
	# Assuming SoundManager is an Autoload
	if SoundManager:
		SoundManager.play_click()
	get_tree().change_scene_to_file("res://Scenes/main_scene.tscn") # Change to your main menu scene path
