# Extends the CharacterBody2D node
class_name Enemy extends CharacterBody2D

@export var speed = 100 # Movement speed of the enemy in pixels per second
@export var min_change_time = 1.0 # Minimum time in seconds before the enemy changes direction
@export var max_change_time = 3.0 # Maximum time in seconds before the enemy changes direction

var direction = Vector2.ZERO # The current movement direction vector (normalized)

# Get references to child nodes using @onready
@onready var change_direction_timer: Timer = $ChangeDirectionTimer # The Timer node used to control direction changes
@onready var hitbox: Area2D = $Hitbox # The Area2D node used to detect overlap with the player


func _ready():
	# Set a random initial movement direction when the enemy is ready in the scene tree
	randomize_direction()
	# Set the timer for the next direction change to a random duration
	set_change_direction_timer()

	# Connect the Area2D's 'body_entered' signal to the '_on_detection_area_body_entered' function.
	# This signal is emitted when a PhysicsBody2D (like the Player's CharacterBody2D) enters the Area2D.
	hitbox.body_entered.connect(_on_detection_area_body_entered)
	change_direction_timer.timeout.connect(_on_change_direction_timer_timeout)

func _physics_process(_delta):
	# Update the enemy's velocity based on its current direction and speed
	velocity = direction * speed
	# Move the enemy using Godot's physics engine and handle collisions
	move_and_slide()


# This function is called when the ChangeDirectionTimer times out
func _on_change_direction_timer_timeout():
	# Pick a new random direction for the enemy
	randomize_direction()
	# Reset the timer with a new random wait time for the next direction change
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


# This function is called when a body enters the detection_area Area2D
func _on_detection_area_body_entered(body):
	# Check if the body that entered the area is an instance of the Player class
	# This assumes your Player script has 'class_name Player'.
	if body is Player:
		# If the entering body is the player, trigger the game reset logic on the player script.
		# Ensure the Player script has a 'reset_game' method.
		print("Player touched")
		if body.has_method("reset_game"):
			body.reset_game.call_deferred()
		else:
			print("Error: Player script does not have a 'reset_game' method.")
