# Extends a parent node like Node2D
class_name MapGeneration extends Node2D

# --- Map Dimensions ---
@export var map_width = 50 # Width of the tilemap in tiles
@export var map_height = 50 # Height of the tilemap in tiles

# --- Tile Atlas Coordinates (REPLACE WITH YOURS) ---
# These are for the Ground Layer
@export var base_dirt_atlas_coords = Vector2i(4, 0) # Atlas coordinates of your base dirt tile (this will form roads where no grass is)
@export var grass_atlas_coords = Vector2i(0, 0) # Atlas coordinates of your small grass tile


# --- TileMap Patterns for Obstacles (Drag and Drop from TileSet Patterns tab in Inspector) ---
# Each array holds patterns for a specific obstacle type.
@export var tree_patterns: Array[TileMapPattern] = []
@export var rock_patterns: Array[TileMapPattern] = []
@export var tuft_patterns: Array[TileMapPattern] = []
@export var water_patterns: Array[TileMapPattern] = []


# --- Noise Parameters for Grass Placement ---
var noise = FastNoiseLite.new() # Using FastNoiseLite for generating organic patterns

# Seed for the noise generator AND the general random number generator
@export var generation_seed = 123 # Change this value to generate a different map


@export var noise_frequency = 0.05 # Controls the size of grass patches. Lower is larger patches.
@export var grass_threshold = 0.1 # Noise value threshold for placing grass (-1 to 1). Higher means more grass.


# --- Spawn Chances (0 to 1) for Each Obstacle Type ---
# Probabilities are checked sequentially. Total chance of an obstacle instance is the sum of these.
@export var tree_spawn_chance = 0.008 # Probability of placing a tree instance
@export var rock_spawn_chance = 0.004 # Probability of placing a rock instance
@export var tuft_spawn_chance = 0.01 # Probability of placing a tuft of grass instance
@export var water_spawn_chance = 0.003 # Probability of placing a water instance


# --- Node References ---
# Get references to the TileMapLayer nodes
# Make sure the node names here match the names in your scene tree
@onready var ground_layer_node: TileMapLayer = $GroundLayer # Ground layer (base dirt and grass)
@onready var obstacle_layer_node: TileMapLayer = $ObstacleLayer # Obstacle layer

# --- Tile Set Source ---
# These refer to the Source ID within the TileSet resources assigned to each layer.
var tile_set_ground_source_id = 0 # Usually 0 if only one source in GroundLayer's TileSet
# Note: When using patterns, the source ID is part of the pattern itself,
# so we don't strictly need tile_set_obtstacle_source_id here, but keeping it
# for consistency if other obstacle placement methods were used.
# var tile_set_obtstacle_source_id = 0


# --- Ready Function ---
func _ready():
	# --- Seed the random number generators ---
	seed(generation_seed) # Use the user-provided seed for Godot's general RNG
	noise.seed = generation_seed # Also use the seed for the noise object

	# --- Configure Noise ---
	noise.frequency = noise_frequency
	# Add other noise parameters here

	# Generate the map across all layers
	generate_map()


# --- Map Generation Function ---
func generate_map():
	print("Generating tilemap...")
	# Clear existing tiles from ALL TileMapLayer nodes
	ground_layer_node.clear()
	obstacle_layer_node.clear()

	# Loop through each cell in the map grid
	for x in range(map_width):
		for y in range(map_height):
			var cell_coords = Vector2i(x, y) # The current cell's map coordinates

			# --- Ground Layer Placement (Base Dirt and Grass based on Noise) ---
			var noise_value = noise.get_noise_2d(x, y)

			var current_ground_tile_coords # Variable to hold the chosen tile coordinates

			if noise_value > grass_threshold:
				current_ground_tile_coords = grass_atlas_coords
			else:
				current_ground_tile_coords = base_dirt_atlas_coords

			ground_layer_node.set_cell(cell_coords, tile_set_ground_source_id, current_ground_tile_coords)
			# --- End Ground Layer Placement ---


			# --- Obstacle Layer Placement (Various Multi-Tile Types using Patterns - deterministic) ---
			var random_obstacle_chooser = randf() # Random value to decide which obstacle type (if any) to place

			var chosen_obstacle_type = "" # To store the name of the chosen type
			var chosen_patterns_list: Array[TileMapPattern] = [] # To store the list of patterns for the type

			# --- Determine Obstacle Type based on Chances ---
			# Probabilities are checked sequentially
			if random_obstacle_chooser < tree_spawn_chance:
				chosen_obstacle_type = "tree"
				chosen_patterns_list = tree_patterns
			elif random_obstacle_chooser < tree_spawn_chance + rock_spawn_chance:
				chosen_obstacle_type = "rock"
				chosen_patterns_list = rock_patterns
			elif random_obstacle_chooser < tree_spawn_chance + rock_spawn_chance + tuft_spawn_chance:
				chosen_obstacle_type = "tuft"
				chosen_patterns_list = tuft_patterns
			elif random_obstacle_chooser < tree_spawn_chance + rock_spawn_chance + tuft_spawn_chance + water_spawn_chance:
				chosen_obstacle_type = "water"
				chosen_patterns_list = water_patterns

			# --- If an Obstacle Type was Chosen and Patterns Exist ---
			if chosen_obstacle_type != "" and not chosen_patterns_list.is_empty():
				# Choose a random pattern for the obstacle type
				var chosen_pattern = chosen_patterns_list[randi_range(0, chosen_patterns_list.size() - 1)]

				# Get the size of the pattern in tiles
				var pattern_size = chosen_pattern.get_size()

				# --- Check if all cells required by the pattern are clear on the obstacle layer ---
				var can_place_obstacle = true
				# Iterate through the area the pattern would occupy
				for dx in range(pattern_size.x):
					for dy in range(pattern_size.y):
						var abs_map_coord = cell_coords + Vector2i(dx, dy) # Calculate the absolute map coordinate

						# Check bounds
						if abs_map_coord.x < 0 or abs_map_coord.x >= map_width or \
						   abs_map_coord.y < 0 or abs_map_coord.y >= map_height:
							can_place_obstacle = false
							break # Break inner loop
						# Check if cell is already occupied on the obstacle layer
						if obstacle_layer_node.get_cell_atlas_coords(abs_map_coord) != Vector2i(-1, -1):
							can_place_obstacle = false
							break # Break inner loop
					if not can_place_obstacle:
						break # Break outer loop

				# --- If the area is clear, place the pattern ---
				if can_place_obstacle:
					# Place the entire obstacle pattern with its top-left at cell_coords
					obstacle_layer_node.set_pattern(cell_coords, chosen_pattern)

			# --- End Obstacle Layer Placement ---

	print("Random TileMap Generated!")
