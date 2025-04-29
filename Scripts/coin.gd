class_name Coin extends Area2D

# Define a signal to emit when the coin is collected
signal collected

func _ready():
	# Connect the Area2D's body_entered signal to this script's function
	# This signal is emitted when a PhysicsBody2D (like CharacterBody2D) enters the Area2D
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Check if the entering body is the player (assuming your player script has a "collect_coin" method)
	if body is Player:
		body.collected_coin()
		# Queue the coin node for removal from the scene tree
		queue_free()
