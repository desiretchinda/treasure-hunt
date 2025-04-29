class_name MapGeneration extends Node2D

@export var map_width = 50 # Width of the tilemap in tiles
@export var map_height = 50 # Height of the tilemap in tiles

@export var grass_atlas_coords = Vector2i(0, 0) # Atlas coordinates of your grass tile
@export var ground_tile_atlas_coords = Vector2i(3, 0) # Atlas coordinates of your additional ground tile
@export var tree_atlas_coords = Vector2i(1, 0) # Atlas coordinates of your tree tile
@export var obstacle_atlas_coords = Vector2i(2, 0) # Atlas coordinates of your obstacle tile

@export var ground_tile_density = 0.3 # Probability (0 to 1) of the additional ground tile appearing instead of grass
@export var tree_density = 0.1 # Probability (0 to 1) of a tree appearing in a cell
@export var obstacle_density = 0.05 # Probability (0 to 1) of an obstacle appearing in a cell

# Get references to the TileMapLayer nodes
# Make sure the node names here match the names in your scene tree
@onready var ground_layer_node: TileMapLayer = $GroundLayer # Change $GroundLayer to the actual path if needed
@onready var obstacle_layer_node: TileMapLayer = $ObstacleLayer # Change $ObstacleLayer to the actual path if needed

var tile_set_source_id = 0 # Usually 0 if you only have one Atlas source in your TileSet(s)

func _ready():
	# Randomize the random number generator based on time
	randomize()

	generate_map()

func generate_map():
	# Clear existing tiles from each TileMapLayer node
	ground_layer_node.clear()
	obstacle_layer_node.clear()

	# Loop through each cell in the map grid
	for x in range(map_width):
		for y in range(map_height):
			var cell_coords = Vector2i(x, y)

			# --- Ground Layer Placement (Grass or another Ground Tile) ---
			var current_ground_tile_coords = grass_atlas_coords # Default tile is grass
			var random_ground_value = randf() # Random value to decide between grass and the other ground tile

			if random_ground_value < ground_tile_density:
				current_ground_tile_coords = ground_tile_atlas_coords # If random value is below density, place the other ground tile

			# Set the chosen tile on the ground layer node
			ground_layer_node.set_cell(cell_coords, tile_set_source_id, current_ground_tile_coords)
			# --- End Ground Layer Placement ---


			# --- Obstacle Layer Placement (Trees or Obstacles) ---
			# Randomly decide if a tree or obstacle should be placed on the obstacle layer node
			var random_obstacle_value = randf() # Get a random float between 0.0 and 1.0

			if random_obstacle_value < tree_density:
				# Place a tree
				obstacle_layer_node.set_cell(cell_coords, tile_set_source_id, tree_atlas_coords)
			elif random_obstacle_value < tree_density + obstacle_density:
				# Place an obstacle (only if a tree wasn't placed)
				obstacle_layer_node.set_cell(cell_coords, tile_set_source_id, obstacle_atlas_coords)
			# --- End Obstacle Layer Placement ---

	print("Random TileMap Generated using TileMapLayer nodes!")
