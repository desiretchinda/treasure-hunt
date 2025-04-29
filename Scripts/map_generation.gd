# Extends a parent node like Node2D
class_name MapGeneration extends Node2D

# Static variable for singleton-like access (if needed from other scripts)
# Other scripts can access this instance using MapGeneration.instance
static var instance:MapGeneration

# --- Map Dimensions ---
@export var map_width = 50 # Width of the tilemap in tiles
@export var map_height = 50 # Height of the tilemap in tiles

# --- Tile Atlas Coordinates (REPLACE WITH YOURS) ---
# These are for the Ground Layer TileSet source.
# Ensure these coordinates match the tiles in the TileSet assigned to GroundLayer.
@export var base_dirt_atlas_coords = Vector2i(4, 0) # Atlas coordinates of your base dirt tile (this will form roads where no grass is)
@export var grass_atlas_coords = Vector2i(0, 0) # Atlas coordinates of your small grass tile


# --- TileMap Pattern Indices for Obstacles (Get these from your Obstacle TileSet Patterns tab) ---
# These are for the Obstacle Layer TileSet source. Each array holds the indices of patterns
# for a specific obstacle type within the TileSet assigned to ObstacleLayer.
# You will need to know the index of each pattern you created in the TileSet editor
# (in the Patterns tab, indices usually start from 0).
@export var tree_pattern_indices: Array[int] = [] # Example: [0, 1] if your first two patterns are trees
@export var rock_pattern_indices: Array[int] = [] # Example: [2] if your third pattern is a rock
@export var tuft_pattern_indices: Array[int] = [] # Example: [3, 4, 5]
@export var water_pattern_indices: Array[int] = [] # Example: [6]


# --- Noise Parameters for Grass Placement ---
# Using FastNoiseLite for generating organic patterns on the ground layer
var noise = FastNoiseLite.new()

# Seed for the noise generator AND the general random number generator (for obstacle/coin/enemy placement)
# Change this value to generate a different map layout.
@export var generation_seed = 123


@export var noise_frequency = 0.05 # Controls the size of grass patches. Lower is larger, higher is more detailed.
@export var grass_threshold = 0.1 # Noise value threshold for placing grass (-1 to 1). Higher means less grass, more dirt "roads".


# --- Spawn Chances (0 to 1) for Each Obstacle Type ---
# Probabilities are checked sequentially for obstacle placement.
# The total chance of an obstacle instance being considered for placement in a cell is the sum of these.
@export var tree_spawn_chance = 0.008 # Probability of attempting to place a tree instance
@export var rock_spawn_chance = 0.004 # Probability of attempting to place a rock instance
@export var tuft_spawn_chance = 0.01 # Probability of attempting to place a tuft of grass instance
@export var water_spawn_chance = 0.003 # Probability of attempting to place a water instance


# --- Coin Parameters ---
@export var coin_scene: PackedScene # Drag your Coin.tscn scene file here in the Inspector
@export var coin_density = 0.02 # Probability (0 to 1) of a coin appearing in a cell where allowed
@export var coin_boundary_margin = 2 # Number of tiles from the edge where coins won't spawn


# --- Enemy Parameters ---
@export var enemy_scene: PackedScene # Drag your Enemy.tscn scene file here in the Inspector
@export var enemy_density = 0.005 # Probability (0 to 1) of an enemy appearing in a cell where allowed
@export var enemy_boundary_margin = 3 # Number of tiles from the edge where enemies won't spawn
@export var min_distance_from_player_start = 5 # Minimum distance (in tiles) from player start position to spawn enemy


# --- Coin Counters ---
var total_coins_generated = 0 # Variable to store the total number of coins generated


# --- Node References ---
# Get references to the TileMapLayer child nodes.
# Make sure the node names here match the names in your scene tree under the Map node.
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
	# Assign this instance to the static variable for singleton access
	instance = self

	# --- Seed the random number generators ---
	# Use the user-provided seed for Godot's general RNG (used by randf(), randi() etc. for obstacle/coin/enemy chances)
	seed(generation_seed)
	# Also use the seed for the noise object (used for terrain patterns on the ground layer)
	noise.seed = generation_seed

	# --- Configure Noise ---
	noise.frequency = noise_frequency
	# You can add other noise parameters here for more complex patterns, e.g.:
	# noise.fractal_octaves = 3
	# noise.fractal_lacunarity = 2.0
	# noise.fractal_gain = 0.5
	# noise.noise_type = FastNoiseLite.TYPE_PERLIN

	# Generate the map across all layers and place coins/enemies
	generate_map()


# --- Map Generation Function ---
func generate_map():
	print("Generating tilemap...")
	# Clear existing tiles from ALL TileMapLayer nodes before generating a new map
	ground_layer_node.clear()
	obstacle_layer_node.clear()

	# Remove any existing coins and enemies from previous generations
	# This is important if you regenerate the map without changing scenes.
	# Assuming you add your coins to a "coin" group and enemies to an "Enemies" group in their respective scripts.
	for child in get_children():
		if child.is_in_group("coin") or child.is_in_group("Enemies"):
			child.queue_free()

	# Reset the total coins generated counter for this new map
	total_coins_generated = 0

	# Get tile size once for positioning coins/enemies and checking obstacle pattern size
	var tile_size = Vector2.ONE # Default to 1 just in case TileSet is not assigned yet
	if ground_layer_node and ground_layer_node.tile_set:
		tile_size = ground_layer_node.tile_set.get_tile_size()

	# Calculate player start position in map coordinates (bottom-left assumed)
	# This is used to prevent enemies from spawning too close to the player's starting point.
	# Adjust this if your player starts at a different tile coordinate.
	var player_start_tile_coords = Vector2i(0, map_height - 1)


	# Loop through each cell in the map grid (iterate column by column, row by row)
	for y in range(map_height):
		for x in range(map_width):
			var cell_coords = Vector2i(x, y) # The current cell's map coordinates

			# --- Ground Layer Placement (Base Dirt and Grass based on Noise) ---
			# Get a noise value for the current cell coordinates
			var noise_value = noise.get_noise_2d(x, y)

			var current_ground_tile_coords # Variable to hold the chosen tile's atlas coordinates

			# If the noise value is above the grass threshold, place a grass tile
			if noise_value > grass_threshold:
				current_ground_tile_coords = grass_atlas_coords
			# Otherwise, place the base dirt tile (these areas will form the "roads" where grass is absent)
			else:
				current_ground_tile_coords = base_dirt_atlas_coords

			# Set the chosen tile on the ground layer node
			ground_layer_node.set_cell(cell_coords, tile_set_ground_source_id, current_ground_tile_coords)
			# --- End Ground Layer Placement ---


			# --- Obstacle Layer Placement (Various Multi-Tile Types using Patterns - deterministic) ---
			# Generate a random value to decide if an obstacle should be considered for placement at this cell
			var random_obstacle_chooser = randf()

			var chosen_obstacle_type = "" # To store the name of the chosen obstacle type (e.g., "tree", "rock")
			var chosen_pattern_indices_list: Array[int] = [] # To store the list of pattern indices for the chosen type

			# --- Determine Obstacle Type based on Spawn Chances ---
			# Probabilities are checked sequentially. The first condition met determines the obstacle type.
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

			# --- If an Obstacle Type was Chosen and Patterns Exist for it ---
			var obstacle_placed = false # Flag to track if an obstacle pattern was successfully placed starting at this cell
			if chosen_obstacle_type != "" and not chosen_pattern_indices_list.is_empty():
				# Get the TileSet resource from the obstacle layer node
				var obstacle_tile_set: TileSet = obstacle_layer_node.tile_set

				if obstacle_tile_set: # Ensure the ObstacleLayer node has a TileSet assigned
					# Choose a random pattern index from the list for the chosen obstacle type
					var chosen_pattern_index = chosen_pattern_indices_list[randi_range(0, chosen_pattern_indices_list.size() - 1)]

					# Get the TileMapPattern resource from the TileSet using the chosen index
					var chosen_pattern: TileMapPattern = obstacle_tile_set.get_pattern(chosen_pattern_index)

					if chosen_pattern: # Ensure the pattern was successfully retrieved from the TileSet
						# Get the size of the pattern in tiles (e.g., Vector2i(1, 2) for a 1x2 tree)
						var pattern_size = chosen_pattern.get_size()

						# --- Check if the entire area required by the pattern is clear on the obstacle layer ---
						var can_place_obstacle = true
						# Iterate through all the cells the pattern would occupy if placed with its top-left at cell_coords
						for dx in range(pattern_size.x):
							for dy in range(pattern_size.y):
								# Calculate the absolute map coordinate for each tile piece of the pattern
								var abs_map_coord = cell_coords + Vector2i(dx, dy)

								# Check bounds: Ensure the entire pattern fits within the map dimensions
								if abs_map_coord.x < 0 or abs_map_coord.x >= map_width or \
								   abs_map_coord.y < 0 or abs_map_coord.y >= map_height:
									can_place_obstacle = false
									break # If any part is out of bounds, we cannot place the obstacle. Exit inner dy loop.
								# Check if cell is already occupied on the obstacle layer: Avoid placing on top of existing obstacles or other parts of multi-tile obstacles already placed in this generation pass.
								# get_cell_atlas_coords returns Vector2i(-1, -1) if the cell is empty on this layer.
								if obstacle_layer_node.get_cell_atlas_coords(abs_map_coord) != Vector2i(-1, -1):
									can_place_obstacle = false
									break # If any part is already occupied, we cannot place the obstacle. Exit inner dy loop.
							if not can_place_obstacle:
								break # If can_place_obstacle became false in the inner loop, exit the outer dx loop.

						# --- If the entire required area is clear and within bounds, place the pattern ---
						if can_place_obstacle:
							# Place the entire obstacle pattern on the obstacle layer, with its top-left at the current cell_coords
							obstacle_layer_node.set_pattern(cell_coords, chosen_pattern)
							# Set the flag to true since an obstacle pattern was successfully placed starting at this cell's top-left.
							obstacle_placed = true
					else:
						print("Warning: Could not retrieve pattern with index ", chosen_pattern_index, " from ObstacleLayer's TileSet. Check pattern indices in the Inspector and TileSet.")
				else:
					print("Warning: ObstacleLayer node has no TileSet assigned. Cannot place obstacles.")

			# --- End Obstacle Layer Placement ---


			# --- Coin Placement ---
			# Check if a coin should be placed at this cell, AND if no obstacle pattern was placed STARTING at this cell's TOP-LEFT COORDINATE.
			# This prevents coins from spawning exactly where a multi-tile obstacle begins.
			# Note: Coins might still spawn under other parts of a multi-tile obstacle if the obstacle is larger than 1x1.
			var random_coin_value = randf()
			if random_coin_value < coin_density and not obstacle_placed:
				# --- Check if the cell is within the coin boundary margin ---
				# Coins will only spawn if they are at least 'coin_boundary_margin' tiles away from all map edges.
				if cell_coords.x >= coin_boundary_margin and cell_coords.x < map_width - coin_boundary_margin and \
				   cell_coords.y >= coin_boundary_margin and cell_coords.y < map_height - coin_boundary_margin:
					# --- Place the coin if all conditions (density, no obstacle at top-left, within margin) are met ---
					if coin_scene: # Ensure the Coin scene PackedScene is assigned in the Inspector
						var coin_instance = coin_scene.instantiate()
						# Position the coin at the center of the cell relative to the MapGeneration node's origin.
						# map_to_local converts tile coordinates to the local pixel coordinates of the TileMapLayer's parent (this node).
						coin_instance.position = ground_layer_node.map_to_local(cell_coords) + tile_size / 2.0

						# Add the coin instance to the scene tree as a child of this MapGeneration node.
						add_child(coin_instance)

						# Add the coin to the "coin" group for easier counting.
						# Make sure you have created a group named "coin" in your project settings or editor.
						coin_instance.add_to_group("coin")

						# Increment the total coins generated counter
						total_coins_generated += 1

						# Connect the coin's 'collected' signal to the player's 'collect_coin' method.
						# We need a reference to the player node. Assuming Player is a sibling of the Map node.
						var player_node = get_node_or_null("../Player") # Use get_node_or_null for safety in case player isn't in scene yet
						if player_node and player_node.has_method("collect_coin"):
							# Use Callable for connecting signals in Godot 4 (Callable.bind() can pass extra arguments if needed)
							coin_instance.collected.connect(player_node.collect_coin)
						# Suppress warning for common editor scenario where player might not be in scene during map generation preview.
						# else:
						# 	print("Warning: Could not find Player node or 'collect_coin' method to connect coin signal.")


			# --- End Coin Placement ---

			# --- Enemy Placement ---
			# Generate a random value to decide if an enemy should be considered for placement at this cell
			var random_enemy_value = randf()
			# Check if an enemy should be placed, AND if no obstacle was placed STARTING at this cell's top-left,
			# AND if the cell is within the enemy boundary margin,
			# AND if the cell is far enough from the player start position.
			if random_enemy_value < enemy_density and not obstacle_placed:
				# Check if the cell is within the enemy boundary margin
				# Enemies will only spawn if they are at least 'enemy_boundary_margin' tiles away from all map edges.
				if cell_coords.x >= enemy_boundary_margin and cell_coords.x < map_width - enemy_boundary_margin and \
				   cell_coords.y >= enemy_boundary_margin and cell_coords.y < map_height - enemy_boundary_margin:

					# Check if the cell is far enough (in tiles) from the player's assumed start position
					if cell_coords.distance_to(player_start_tile_coords) >= min_distance_from_player_start:

						# --- Place the enemy if all conditions (density, no obstacle at top-left, within margin, far from player) are met ---
						if enemy_scene: # Ensure the Enemy scene PackedScene is assigned in the Inspector
							var enemy_instance = enemy_scene.instantiate()
							# Position the enemy at the center of the cell relative to the MapGeneration node's origin
							enemy_instance.position = ground_layer_node.map_to_local(cell_coords) + tile_size / 2.0

							# Add the enemy instance to the scene tree as a child of this MapGeneration node
							add_child(enemy_instance)

							# Add enemy to a group for easier management (e.g., "Enemies")
							# Make sure you have created a group named "Enemies" in your project settings or editor.
							enemy_instance.add_to_group("Enemies")

						else:
							print("Warning: Enemy scene PackedScene is not assigned in the Inspector. Cannot place enemies.")

			# --- End Enemy Placement ---

	if GameManager.has_signal("map_generated"):
		GameManager.map_generated.emit()

	print("Random TileMap Generated! Total coins generated: ", total_coins_generated)


# --- Function to get the number of coins currently in the scene ---
# Counts all nodes currently in the "coin" group.
func get_coins_left() -> int:
	var coins = get_tree().get_nodes_in_group("Coins")
	return coins.size()

# --- Function to get the total number of coins generated ---
# Returns the total count of coins that were initially placed during generation.
func get_total_coins_generated() -> int:
	return total_coins_generated
