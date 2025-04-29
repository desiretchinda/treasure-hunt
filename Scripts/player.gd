class_name Player extends CharacterBody2D

# This is the AnimatedSprite2D node used for animations.
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var speed: float = 200 # Movement speed in pixels per second

var direction_name:String = "Face"

func _physics_process(_delta):
	# Get the input direction vector
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Update the velocity based on the input vector and speed (instant movement)
	# This matches the style from your previous base script.
	velocity = input_vector * speed


	# Move the character and handle collisions
	move_and_slide()

	# --- Clamp Player Position to Camera Viewport logic is REMOVED as requested. ---
	# The code block that checked the camera and clamped the global_position is gone.


	# --- Animation Handling ---
	# (This part correctly uses animated_sprite_2d)
	# Animation trigger based on velocity length > 0
	if velocity.length() > 0:
		var direction = velocity.normalized()
		# Determine direction and play walk animation
		direction_name = "Face" # Default animation names based on your base script

		if direction.y < 0:
			direction_name = "Back"
		elif direction.y > 0:
			direction_name = "Face"

		if abs(direction.x) > abs(direction.y):
			if direction.x < 0:
				direction_name = "Left"
			elif direction.x > 0:
				direction_name = "Right"

		animated_sprite_2d.play("Walk_"+direction_name)
	else:
		# If not moving, play idle animation
		animated_sprite_2d.play("Idle_"+direction_name)
	# --- End Animation Handling ---
