extends Node

signal coin_collected
signal map_generated

var config = ConfigFile.new()
var level: int = 1

func _ready() -> void:
	var error = config.load("user://game_settings.ini")
	if error != OK:
		# Handle error, maybe the file doesn't exist yet
		if error == ERR_FILE_NOT_FOUND:
			print("Settings file not found, creating new one.")
		else:
			print("Error loading settings: ", error)
	load_game()
	
func load_game()->void:
	level = config.get_value("player", "level", 1.0)

func save_game()->void:
	config.set_value("player", "level", level)
	config.save("user://game_settings.ini")
