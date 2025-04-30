# Extends the CharacterBody2D node
class_name Enemy extends CharacterBody2D

@export var speed = 100 # Movement speed of the enemy in pixels per second
@export var min_change_time = 1.0 # Minimum time in seconds before the enemy changes direction
@export var max_change_time = 3.0 # Maximum time in seconds before the enemy changes direction
@export var attack_duration = 0.5 # Duration of the attack animation in seconds

var direction = Vector2.ZERO # The current movement direction vector (normalized)
var is_attacking = false # Flag to indicate if the enemy is currently attacking

# Get references to child nodes using @onready
@onready var change_direction_timer: Timer = $ChangeDirectionTimer # The Timer node used to control random direction changes
@onready var hitbox: Area2D = $Hitbox # The Area2D node used to detect overlap with the player
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D # Reference to the AnimatedSprite2D node for animations


func _ready():
	# Ensure the AnimatedSprite2D node is present and has a SpriteFrames resource
	if not animated_sprite_2d or not animated_sprite_2d.sprite_frames:
		print("Error: AnimatedSprite2D node or SpriteFrames resource not assigned to Enemy.")
		set_process(false) # Disable processing if animation setup is missing
		return

	# Set a random initial movement direction when the enemy is ready in the scene tree
	randomize_direction()
	# Set the timer for the next direction change to a random duration
	set_change_direction_timer()

	# Connect signals
	hitbox.body_entered.connect(_on_hitbox_body_entered) # Corrected Area2D signal connection
	change_direction_timer.timeout.connect(_on_change_direction_timer_timeout)

	# Add the enemy to a group for easier management (e.g., for clearing enemies on map regeneration)
	# Make sure you have created a group named "Enemies" in your project settings or editor.
	add_to_group("Enemies")

	# Start with the Idle animation
	play_animation("Idle")


func _physics_process(_delta):
	# Only move if not attacking
	if not is_attacking:
		# Update the enemy's velocity based on its current direction and speed
		velocity = direction * speed
		# Move the enemy using Godot's physics engine and handle collisions
		move_and_slide()
		# Play the walk animation if moving
		if velocity.length() > 0:
			play_animation("Walk")
		else:
			# Play idle animation if not moving and not attacking
			play_animation("Idle")


# This function is called when the ChangeDirectionTimer times out
func _on_change_direction_timer_timeout():
	# Only change direction if not attacking
	if not is_attacking:
		# Pick a new random direction for the enemy
		randomize_direction()
		# Set the timer with a new random wait time for the next direction change
		set_change_direction_timer()


# Picks a random direction vector
func randomize_direction():
	# Pick a random angle in radians between 0 (inclusive) and 2*PI (exclusive)
	var random_angle = randf() * TAU # TAU is a constant representing 2 * PI

	# Convert the random angle to a unit vector representing the direction
	direction = Vector2(cos(random_angle), sin(random_angle)).normalized()


# Sets the ChangeDirectionTimer's wait time to a random value
func set_change_direction_timer():
	# Set the timer's wait time to a random float value between min_change_time and max_change_time
	change_direction_timer.wait_time = randf_range(min_change_time, max_change_time)
	# Start or restart the timer
	change_direction_timer.start()


# This function is called when a body enters the hitbox Area2D
func _on_hitbox_body_entered(body):
	# Check if the body that entered the area is an instance of the Player class
	# This assumes your Player script has 'class_name Player'.
	if body is Player:
		print("Player touched")
		body.can_move = false
		# Start the attack animation and logic
		start_attack()


# Starts the attack animation and sets the attacking flag
func start_attack():
	is_attacking = true
	play_animation("Attack")
	# Create a one-shot timer to end the attack animation after its duration
	var attack_timer = Timer.new()
	add_child(attack_timer) # Add the timer as a child so it's managed by the scene tree
	attack_timer.wait_time = attack_duration
	attack_timer.one_shot = true
	attack_timer.timeout.connect(end_attack)
	attack_timer.start()


# Ends the attack state and returns to idle/walk animation
func end_attack():
	is_attacking = false
	# If the entering body is the player, trigger the game reset logic on the player script.
	# Ensure the Player script has a 'reset_game' method.
	if Player.instance.has_method("reset_game"):
		# Use call_deferred to avoid issues with physics engine during collision callback
		Player.instance.reset_game.call_deferred()
	else:
		print("Error: Player script does not have a 'reset_game' method.")
	# After attacking, decide whether to go back to walk or idle based on current velocity
	if velocity.length() > 0:
		play_animation("Walk")
	else:
		play_animation("Idle")


# Plays the specified animation on the AnimatedSprite2D
func play_animation(anim_name: String):
	# Only play the animation if it's not already playing
	if animated_sprite_2d and animated_sprite_2d.animation != anim_name:
		animated_sprite_2d.play(anim_name)
