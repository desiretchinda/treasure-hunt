# Extends the Area2D node
class_name Door extends Area2D

static var instance:Door

func _ready():
	instance = self
	# Connect the Area2D's 'body_entered' signal to this script's '_on_body_entered' function.
	body_entered.connect(_on_body_entered)


# This function is called when a body enters the Area2D
func _on_body_entered(body):
	# Check if the entering body is the player
	if body is Player: # Assumes your Player script has 'class_name Player'
		print("Player entered the door area.")
		if body.has_collected_all_coins():
			body.can_move = false
			body.starting_point_reached = true
			if GameManager.has_signal("coin_collected"):
				GameManager.coin_collected.emit()
			WinPanel.instance.show_panel()
			print("Player win: all coins collected.")
		else:
			print("All coins not collected.")
