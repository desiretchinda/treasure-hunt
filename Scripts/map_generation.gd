# Extends a parent node like Node2D
class_name MapGeneration extends Node2D

# --- Map Dimensions ---
@export var map_width = 50 # Width of the tilemap in tiles
@export var map_height = 50 # Height of the tilemap in tiles

# --- Tile Atlas Coordinates (REPLACE WITH YOURS) ---
@export var base_dirt_atlas_coords = Vector2i(4, 0) # Atlas coordinates of your base dirt tile (this will form roads where no grass is)
@export var grass_atlas_coords = Vector2i(0, 0) # Atlas coordinates of your small grass tile

@export var tree_atlas_coords = Vector2i(1, 0) # Atlas coordinates of your tree tile
@export var obstacle_atlas_coords = Vector2i(2, 0) # Atlas coordinates of your obstacle tile


# --- Noise Parameters for Grass Placement ---
# Using FastNoiseLite for generating organic patterns
var noise = FastNoiseLite.new()

# Seed for the noise generator AND the general random number generator
@export var generation_seed = 123 # Change this value to generate a different map


@export var noise_frequency = 0.05 # Controls the size of grass patches. Lower is larger patches.
@export var grass_threshold = 0.1 # Noise value threshold for placing grass (-1 to 1). Higher means more grass.


# --- Densities (0 to 1) for Obstacles (These now use the seeded random number generator) ---
@export var tree_density = 0.1 # Probability of a tree appearing in a cell
@export var obstacle_density = 0.05 # Probability of an obstacle appearing in a cell

# --- Node References ---
# Get references to the TileMapLayer nodes
# Make sure the node names here match the names in your scene tree
@onready var ground_layer_node: TileMapLayer = $GroundLayer # Ground layer (base dirt and grass)
@onready var obstacle_layer_node: TileMapLayer = $ObstacleLayer # Obstacle layer

# --- Tile Set Source ---
var tile_set_source_id = 0 # Usually 0 if you only have one Atlas source in your TileSet(s) for each layer


# --- Ready Function ---
func _ready():
	# --- Seed the random number generators ---
	# Use the user-provided seed for Godot's general RNG (used by randf(), randi() etc.)
	seed(generation_seed)
	# Also use the seed for the noise object (used for terrain patterns)
	noise.seed = generation_seed

	# --- Configure Noise ---
	noise.frequency = noise_frequency

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
			var cell_coords = Vector2i(x, y)

			# --- Ground Layer Placement (Dirt and Grass based on Noise) ---
			# Note: get_noise_2d is already deterministic due to noise.seed
			var noise_value = noise.get_noise_2d(x, y)

			var current_ground_tile_coords: Vector2i # Variable to hold the chosen tile coordinates

			# If the noise value is above the grass threshold, place grass
			if noise_value > grass_threshold:
				current_ground_tile_coords = grass_atlas_coords
			# Otherwise, place the base dirt tile (this forms the "roads")
			else:
				current_ground_tile_coords = base_dirt_atlas_coords

			# Set the chosen tile on the ground layer node
			ground_layer_node.set_cell(cell_coords, tile_set_source_id, current_ground_tile_coords)
			# --- End Ground Layer Placement ---


			# --- Obstacle Layer Placement (Trees or Obstacles - now deterministic) ---
			# Note: randf() is now deterministic due to the seed(generation_seed) call in _ready
			var random_obstacle_value = randf()

			if random_obstacle_value < tree_density:
				# Place a tree on the obstacle layer node
				obstacle_layer_node.set_cell(cell_coords, tile_set_source_id, tree_atlas_coords)
			elif random_obstacle_value < tree_density + obstacle_density:
				# Place an obstacle on the obstacle layer node (only if a tree wasn't placed)
				obstacle_layer_node.set_cell(cell_coords, tile_set_source_id, obstacle_atlas_coords)
			# --- End Obstacle Layer Placement ---

	print("Random TileMap Generated!")
