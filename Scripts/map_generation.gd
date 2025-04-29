# Extends a parent node like Node2D
class_name MapGeneration extends Node2D

# --- Map Dimensions ---
@export var map_width = 50 # Width of the tilemap in tiles
@export var map_height = 50 # Height of the tilemap in tiles

# --- Tile Atlas Coordinates (REPLACE WITH YOURS) ---
# These are for the Ground Layer TileSet source
@export var base_dirt_atlas_coords = Vector2i(4, 0) # Atlas coordinates of your base dirt tile (this will form roads where no grass is)
@export var grass_atlas_coords = Vector2i(0, 0) # Atlas coordinates of your small grass tile


# --- TileMap Pattern Indices for Obstacles (Get these from your Obstacle TileSet Patterns tab) ---
# These are for the Obstacle Layer TileSet source. Each array holds the indices of patterns for a specific obstacle type within the TileSet.
# You will need to know the index of each pattern you created in the TileSet editor.
@export var tree_pattern_indices: Array[int] = [] # Example: [0, 1] if your first two patterns are trees
@export var rock_pattern_indices: Array[int] = [] # Example: [2] if your third pattern is a rock
@export var tuft_pattern_indices: Array[int] = [] # Example: [3, 4, 5]
@export var water_pattern_indices: Array[int] = [] # Example: [6]


# --- Noise Parameters for Grass Placement ---
# Using FastNoiseLite for generating organic patterns on the ground layer
var noise = FastNoiseLite.new()

# Seed for the noise generator AND the general random number generator (for obstacle placement)
@export var generation_seed = 123 # Change this value to generate a different map


@export var noise_frequency = 0.05 # Controls the size of grass patches. Lower is larger patches.
@export var grass_threshold = 0.1 # Noise value threshold for placing grass (-1 to 1). Higher means more grass.


# --- Spawn Chances (0 to 1) for Each Obstacle Type ---
# Probabilities are checked sequentially for obstacle placement. Total chance of an obstacle instance is the sum of these.
@export var tree_spawn_chance = 0.008 # Probability of attempting to place a tree instance
@export var rock_spawn_chance = 0.004 # Probability of attempting to place a rock instance
@export var tuft_spawn_chance = 0.01 # Probability of attempting to place a tuft of grass instance
@export var water_spawn_chance = 0.003 # Probability of attempting to place a water instance


# --- Coin Parameters ---
@export var coin_scene: PackedScene # Drag your Coin.tscn scene file here in the Inspector
@export var coin_density = 0.02 # Probability (0 to 1) of a coin appearing in a cell
@export var coin_boundary_margin = 2 # Number of tiles from the edge where coins won't spawn


# --- Coin Counters ---
var total_coins_generated = 0 # Variable to store the total number of coins generated


# --- Node References ---
# Get references to the TileMapLayer nodes
# Make sure the node names here match the names in your scene tree
@onready var ground_layer_node: TileMapLayer = $GroundLayer # Ground layer (base dirt and grass)
@onready var obstacle_layer_node: TileMapLayer = $ObstacleLayer # Obstacle layer (trees, rocks, etc.)

# --- Tile Set Source IDs ---
# These refer to the Source ID within the TileSet resources assigned to each layer.
# Adjust these if your TileSets have multiple sources.
var tile_set_ground_source_id = 0 # Assuming ground tiles are in the first source (ID 0) of GroundLayer's TileSet
# Note: When using patterns accessed by index from the TileSet resource,
# the source ID is implicitly handled by the pattern itself.


# --- Ready Function ---
func _ready():
	# --- Seed the random number generators ---
	seed(generation_seed) # Use the user-provided seed for Godot's general RNG (used by randf(), randi() etc. for obstacle chances)
	noise.seed = generation_seed # Also use the seed for the noise object (used for terrain patterns on the ground layer)

	# --- Configure Noise ---
	noise.frequency = noise_frequency
	# Add other noise parameters here (e.g., noise.fractal_octaves, noise.fractal_lacunarity)
	# as needed for more complex noise patterns.

	# Generate the map across all layers and place coins
	generate_map()


# --- Map Generation Function ---
func generate_map():
	print("Generating tilemap...")
	# Clear existing tiles from ALL TileMapLayer nodes
	ground_layer_node.clear()
	obstacle_layer_node.clear()

	# Reset the total coins generated counter
	total_coins_generated = 0

	# Get tile size once for positioning coins and checking obstacle pattern size
	var tile_size = Vector2.ONE # Default to 1 just in case
	if ground_layer_node and ground_layer_node.tile_set:
		tile_size = ground_layer_node.tile_set.get_tile_size()

	# Loop through each cell in the map grid
	for y in range(map_height):
		for x in range(map_width):
			var cell_coords = Vector2i(x, y) # The current cell's map coordinates

			# --- Ground Layer Placement (Base Dirt and Grass based on Noise) ---
			var noise_value = noise.get_noise_2d(x, y) # Get noise value for this cell

			var current_ground_tile_coords # Variable to hold the chosen tile coordinates

			# If the noise value is above the grass threshold, place grass
			if noise_value > grass_threshold:
				current_ground_tile_coords = grass_atlas_coords
			# Otherwise, place the base dirt tile (this forms the "roads")
			else:
				current_ground_tile_coords = base_dirt_atlas_coords

			ground_layer_node.set_cell(cell_coords, tile_set_ground_source_id, current_ground_tile_coords)
			# --- End Ground Layer Placement ---


			# --- Obstacle Layer Placement (Various Multi-Tile Types using Patterns - deterministic) ---
			var random_obstacle_chooser = randf() # Random value to decide which obstacle type (if any) to place

			var chosen_obstacle_type = "" # To store the name of the chosen type
			var chosen_pattern_indices_list: Array[int] = [] # To store the list of pattern indices for the type

			# --- Determine Obstacle Type based on Chances ---
			# Probabilities are checked sequentially
			if random_obstacle_chooser < tree_spawn_chance:
				chosen_obstacle_type = "tree"
				chosen_pattern_indices_list = tree_pattern_indices
			elif random_obstacle_chooser < tree_spawn_chance + rock_spawn_chance:
				chosen_obstacle_type = "rock"
				chosen_pattern_indices_list = rock_pattern_indices
			elif random_obstacle_chooser < tree_spawn_chance + rock_spawn_chance + tuft_spawn_chance:
				chosen_obstacle_type = "tuft"
				chosen_pattern_indices_list = tuft_pattern_indices
			elif random_obstacle_chooser < tree_spawn_chance + rock_spawn_chance + tuft_spawn_chance + water_spawn_chance:
				chosen_obstacle_type = "water"
				chosen_pattern_indices_list = water_pattern_indices

			# --- If an Obstacle Type was Chosen and Patterns Exist ---
			var obstacle_placed = false # Flag to check if an obstacle was successfully placed starting at this cell
			if chosen_obstacle_type != "" and not chosen_pattern_indices_list.is_empty():
				# Get the TileSet resource from the obstacle layer node
				var obstacle_tile_set: TileSet = obstacle_layer_node.tile_set

				if obstacle_tile_set: # Ensure the TileSet is assigned
					# Choose a random pattern index for the obstacle type
					var chosen_pattern_index = chosen_pattern_indices_list[randi_range(0, chosen_pattern_indices_list.size() - 1)]

					# Get the TileMapPattern resource from the TileSet using the index
					var chosen_pattern: TileMapPattern = obstacle_tile_set.get_pattern(chosen_pattern_index)

					if chosen_pattern: # Ensure the pattern was successfully retrieved
						# Get the size of the pattern in tiles
						var pattern_size = chosen_pattern.get_size()

						# --- Check if the area required by the pattern is clear on the obstacle layer ---
						var can_place_obstacle = true
						# Iterate through the cells the pattern would cover
						for dx in range(pattern_size.x):
							for dy in range(pattern_size.y):
								var abs_map_coord = cell_coords + Vector2i(dx, dy) # Calculate the absolute map coordinate

								# Check bounds: Ensure the entire pattern fits within the map dimensions
								if abs_map_coord.x < 0 or abs_map_coord.x >= map_width or \
									abs_map_coord.y < 0 or abs_map_coord.y >= map_height:
									can_place_obstacle = false
									break # Exit inner dy loop
								# Check if cell is already occupied on the obstacle layer: Avoid placing on top of existing obstacles
								# get_cell_atlas_coords returns Vector2i(-1, -1) if the cell is empty
								if obstacle_layer_node.get_cell_atlas_coords(abs_map_coord) != Vector2i(-1, -1):
									can_place_obstacle = false
									break # Exit inner dy loop
							if not can_place_obstacle:
								break # Exit outer dx loop

						# --- If the entire required area is clear and within bounds, place the pattern ---
						if can_place_obstacle:
							# Place the entire obstacle pattern with its top-left at cell_coords
							obstacle_layer_node.set_pattern(cell_coords, chosen_pattern)
							obstacle_placed = true # Mark that an obstacle was successfully placed starting at this cell
					else:
						print("Warning: Could not retrieve pattern with index ", chosen_pattern_index, " from ObstacleLayer's TileSet.")
				else:
					print("Warning: ObstacleLayer node has no TileSet assigned.")

			# --- End Obstacle Layer Placement ---


			# --- Coin Placement ---
			# Check if a coin should be placed at this cell, AND if no obstacle was placed STARTING at this cell's TOP-LEFT COORDINATE
			var random_coin_value = randf()
			# We check if an obstacle pattern was placed starting at THIS cell's top-left coordinate.
			# This prevents coins from spawning *exactly* where a multi-tile obstacle begins.
			# Note: Coins might still spawn under other parts of a multi-tile obstacle if the obstacle is larger than 1x1.
			if random_coin_value < coin_density and not obstacle_placed:
				# --- Check if the cell is within the coin boundary margin ---
				if cell_coords.x >= coin_boundary_margin and cell_coords.x < map_width - coin_boundary_margin and \
				   cell_coords.y >= coin_boundary_margin and cell_coords.y < map_height - coin_boundary_margin:
					# --- Place the coin if all conditions are met ---
					if coin_scene: # Ensure coin_scene PackedScene is assigned
						var coin_instance = coin_scene.instantiate()
						# Position the coin at the center of the cell relative to the MapGeneration node's origin
						# map_to_local converts tile coordinates to local pixel coordinates of the TileMapLayer's parent
						coin_instance.position = ground_layer_node.map_to_local(cell_coords) + tile_size / 2.0

						# Add the coin instance to the scene tree as a child of the MapGeneration node
						add_child(coin_instance)

						# Increment the total coins generated counter
						total_coins_generated += 1

						# Connect the coin's collected signal to the player's collection method
						# We need a reference to the player node here. Assuming Player is a sibling of the Map node.
						var player_node = get_node_or_null("../Player") # Use get_node_or_null for safety
						if player_node and player_node.has_method("collect_coin"):
							# Use Callable for connecting signals in Godot 4
							coin_instance.collected.connect(player_node.collect_coin)
						# Suppress warning for common editor scenario where player might not be in scene
						# else:
						# 	print("Warning: Could not find Player node or 'collect_coin' method to connect coin signal.")

			# --- End Coin Placement ---

	print("Random TileMap Generated! Total coins generated: ", total_coins_generated)


# --- Function to get the number of coins currently in the scene ---
func get_coins_left() -> int:
	var coins_count = 0
	# Iterate through all children of this MapGeneration node
	for child in get_children():
		# Check if the child is an instance of the Coin scene (or the Coin script)
		# Using is_instance_of() is generally safer than checking class_name string
		if child.is_instance_of(Area2D) and child.has_signal("collected"): # Check if it's an Area2D and has the 'collected' signal (from Coin.gd)
		# Alternatively, if Coin.gd has a class_name, you could use:
		# if child is Coin:
			coins_count += 1
	return coins_count

# --- Function to get the total number of coins generated ---
func get_total_coins_generated() -> int:
	return total_coins_generated
