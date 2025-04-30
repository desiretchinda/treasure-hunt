class_name MainMenu extends Control

@onready var btn_start:Button = $Panel/StartButton
@onready var quit_start:Button = $Panel/QuitButton

func _ready() -> void:
	if btn_start:
		btn_start.pressed.connect(_on_start_pressed)

	if quit_start:
		quit_start.pressed.connect(_on_quit_pressed)


func _on_start_pressed()->void:
	SoundManager.play_click()
	get_tree().change_scene_to_file("res://Scenes/game_play.tscn")

func _on_quit_pressed()->void:
	SoundManager.play_click()
	get_tree().quit()
