class_name Player extends CharacterBody2D

static var instance:Player

# This is the AnimatedSprite2D node used for animations.
# The sprite_frames resource must be assigned to this node in the editor.
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
# --- Add References to Map and Ground Layer for Positioning ---
# Assuming Player is a sibling of Map under a common parent.
@onready var map_node = get_node("../Map")
# Assuming GroundLayer is a child of Map.
@onready var ground_layer_node = get_node("../Map/GroundLayer")
@onready var blood_particle:GPUParticles2D = $BloodParticle
@onready var coin_particle:GPUParticles2D = $CoinParticle
@onready var stream_player:AudioStreamPlayer = $StreamPlayer
# --- End Add References ---
@export var speed: float = 200 # Movement speed in pixels per second

var direction_name:String = "Face"
var coins = 0 # Keeps track of collected coins
var can_move:bool = false
var starting_point_reached:bool = false

func _ready():
	instance = self
	coin_particle.global_position = Vector2.ZERO
	coin_particle.emitting = true
	# --- Position Player at Bottom-Left of Map ---
	# Ensure required nodes and tile set are ready for positioning
	if map_node and ground_layer_node and ground_layer_node.tile_set and animated_sprite_2d and animated_sprite_2d.sprite_frames:

		var map_width = map_node.map_width # Get map width from the Map node's script
		var map_height = map_node.map_height # Get map height from the Map node's script

		var tile_size = ground_layer_node.tile_set.get_tile_size() # Get tile size

		# Get the global position of the map's top-left corner
		var map_global_origin = map_node.global_position

		# --- Get Player's Size ---
		var current_animation_name = animated_sprite_2d.animation # Get the name of the current animation
		var current_frame_index = animated_sprite_2d.frame # Get the index of the current frame
		var sprite_frames_resource: SpriteFrames = animated_sprite_2d.sprite_frames # Get SpriteFrames resource

		var player_size = Vector2.ZERO # Default size

		# Check if a valid texture exists for the current frame to get size
		if sprite_frames_resource.has_animation(current_animation_name) and sprite_frames_resource.get_frame_count(current_animation_name) > current_frame_index:
			var current_frame_texture: Texture2D = sprite_frames_resource.get_frame_texture(current_animation_name, current_frame_index)
			if current_frame_texture:
				player_size = current_frame_texture.get_size()

		if player_size != Vector2.ZERO:
			# Calculate half size only if player_size was successfully obtained
			var player_half_size = player_size / 2.0

			# Calculate the target global position for the player's CENTER
			# We want the player's BOTTOM-LEFT edge to be at the map's BOTTOM-LEFT pixel corner.
			# Map's bottom-left pixel corner global X: map_global_origin.x
			# Map's bottom-left pixel corner global Y: map_global_origin.y + map_height * tile_size.y

			# Player's center X = Map's left edge + Player's half width
			var target_global_pos_x = map_global_origin.x + player_half_size.x
			# Player's center Y = Map's bottom edge - Player's half height
			var target_global_pos_y = map_global_origin.y + map_height * tile_size.y - player_half_size.y

			# Set player's global position to the calculated bottom-left position
			global_position = Vector2(target_global_pos_x, target_global_pos_y)
			print("Player positioned at bottom-left.")
		else:
			print("Warning: Could not determine player size for initial positioning. Ensure AnimatedSprite2D has a valid SpriteFrames resource and animation/frame.")
	else:
		print("Error: Required nodes (Map, GroundLayer, TileSet) or AnimatedSprite2D/SpriteFrames not ready for initial positioning. Check scene structure and resource assignments.")
	# --- End Position Player ---
	Door.instance.global_position = global_position+Vector2(0,-40)
	get_viewport().get_camera_2d().global_position = global_position
	await get_tree().create_timer(.5).timeout
	can_move = true
	get_viewport().get_camera_2d().set_blocking_limit(true)


func _physics_process(_delta):
	if not can_move:
		return
	
	# Get the input direction vector
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Update the velocity based on the input vector and speed (instant movement)
	velocity = input_vector * speed

	# Move the character and handle collisions
	move_and_slide()

	# --- Animation Handling ---
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
			if input_vector.x < 0: # Use input_vector for animation direction when horizontal movement is dominant
				direction_name = "Left"
			elif input_vector.x > 0: # Use input_vector for animation direction when horizontal movement is dominant
				direction_name = "Right"

		animated_sprite_2d.play("Walk_"+direction_name)
	else:
		# If not moving, play idle animation
		animated_sprite_2d.play("Idle_"+direction_name)
	# --- End Animation Handling ---

func hit_player()->void:
	can_move = false
	if direction_name == "Back":
		blood_particle.z_index = 0
	blood_particle.emitting = true
	animated_sprite_2d.play("Dead")
	stream_player.play()

func collected_coin()->void:
	coins += 1
	SoundManager.play_coin()
	coin_particle.global_position = global_position
	coin_particle.emitting = true
	if GameManager.has_signal("coin_collected"):
		GameManager.coin_collected.emit()
	print("coin collected ",coins)
	
func has_collected_all_coins()->bool:
	return coins >= MapGeneration.instance.total_coins_generated

func has_reached_starting_point()->bool:
	return starting_point_reached

# --- Add Game Reset Method ---
# This method is called by the Enemy script when the player is hit.
func reset_game():
	print("Player hit! Resetting game...") # Print a message indicating the game is resetting
	# Get the path of the current scene file
	var current_scene_path = get_tree().current_scene.scene_file_path
	# Reload the current scene, effectively resetting the game state.
	get_tree().reload_current_scene()
# --- End Add Game Reset Method ---
