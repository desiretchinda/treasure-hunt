class_name Player extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D # Get the AnimatedSprite2D node

@export var speed: float = 200 # Movement speed in pixels per second

var direction_name:String = "Face"

func _physics_process(_delta):
	# Get the input direction vector
	# The vector will be normalized if moving diagonally,
	# preventing faster diagonal movement.
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Update the velocity based on the input vector and speed
	velocity = input_vector * speed
	
	# --- Animation Handling ---
	if input_vector.length() > 0:
		# If moving, determine direction and play walk animation
		direction_name = "Face" # Default animation

		if input_vector.y < 0:
			direction_name = "Back"
		elif input_vector.y > 0:
			direction_name = "Face"

		# Prioritize left/right if moving horizontally more
		if abs(input_vector.x) > abs(input_vector.y):
			if input_vector.x < 0:
				direction_name = "Left"
			elif input_vector.x > 0:
				direction_name = "Right"

		animated_sprite_2d.play("Walk_"+direction_name)
	else:
		# If not moving, play idle animation
		animated_sprite_2d.play("Idle_"+direction_name)
	# --- End Animation Handling ---

	# Move the character and handle collisions
	move_and_slide()
