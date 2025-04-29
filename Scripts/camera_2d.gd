# Extends the Camera2D node
class_name Camera extends Camera2D

@export var follow_speed = 5.0 # How quickly the camera follows the player. Higher is faster.

# Need a reference to the player node.
# This assumes the player node is a sibling of the Camera2D node
# or can be accessed via a path from the Camera2D.
@onready var player = get_parent().get_node("Player")

func _process(delta):
	# Ensure the player node is valid before trying to follow
	if player:
		# Get the target position (the player's global position)
		var target_position = player.global_position

		# Smoothly move the camera's global position towards the target position using linear interpolation (lerp).
		global_position = global_position.lerp(target_position, follow_speed * delta)
