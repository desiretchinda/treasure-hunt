# Extends the Camera2D node
extends Camera2D

@export var follow_speed = 5.0 # How quickly the camera follows the player. Higher is faster.

# Reference to the Map node which has the MapGeneration script and map dimensions
# Assuming Camera2D is a sibling of Map under a common parent.
@onready var map_node = get_node("../Map")

# Need a reference to one of the TileMapLayer nodes to get the tile size from its TileSet
# Assuming GroundLayer is a child of Map, and Camera2D is sibling of Map.
@onready var ground_layer_node = get_node("../Map/GroundLayer")

# Reference to the player node. Assuming Player is a sibling of Camera2D.
@onready var player:Player = get_node("../Player")

@export var limit:Array[CollisionShape2D] = []

func _ready() -> void:
	set_blocking_limit(false)

func _process(delta):
	# Ensure necessary nodes are valid
	if player and map_node and ground_layer_node and ground_layer_node.tile_set:

		# Get the desired position to move towards (player's global position)
		var target_position = player.global_position

		# Calculate the desired camera position after smoothing (lerp)
		var desired_position = global_position.lerp(target_position, follow_speed * delta)

		# --- Clamp Camera Position to Map Bounds ---

		# Get map dimensions from the map node (which has the MapGeneration script)
		# We can directly access map_width and map_height because the script is on map_node
		var map_width = map_node.map_width
		var map_height = map_node.map_height

		# Get tile size from the TileSet of the GroundLayer
		var tile_size = ground_layer_node.tile_set.get_tile_size()

		# Calculate map boundaries in global pixel coordinates
		# Assuming the top-left of the map grid is at the Map node's global position
		var map_global_origin = map_node.global_position # Top-left corner of the map in global coords
		var map_pixel_width = map_width * tile_size.x
		var map_pixel_height = map_height * tile_size.y
		var map_global_end = map_global_origin + Vector2(map_pixel_width, map_pixel_height) # Bottom-right corner

		# Get the size of the viewport (what the camera sees)
		var viewport_size = get_viewport_rect().size

		# Calculate the boundaries for the camera's center (global_position)
		# The camera's center can range from the map's edge + half the viewport size
		# to the map's end - half the viewport size.
		var camera_min_x = map_global_origin.x + viewport_size.x / 2.0
		var camera_max_x = map_global_end.x - viewport_size.x / 2.0
		var camera_min_y = map_global_origin.y + viewport_size.y / 2.0
		var camera_max_y = map_global_end.y - viewport_size.y / 2.0

		# Clamp the desired position to the calculated camera boundaries
		var clamped_position = Vector2.ZERO

		# Clamp X position
		if camera_min_x > camera_max_x: # If map is narrower than the viewport, center the camera
			clamped_position.x = (map_global_origin.x + map_global_end.x) / 2.0
		else:
			clamped_position.x = clamp(desired_position.x, camera_min_x, camera_max_x)

		# Clamp Y position
		if camera_min_y > camera_max_y: # If map is shorter than the viewport, center the camera
			clamped_position.y = (map_global_origin.y + map_global_end.y) / 2.0
		else:
			clamped_position.y = clamp(desired_position.y, camera_min_y, camera_max_y)

		# Update the camera's global position to the clamped position
		global_position = clamped_position


func set_blocking_limit(statuts:bool)->void:
	for c in limit:
		c.disabled = !statuts
