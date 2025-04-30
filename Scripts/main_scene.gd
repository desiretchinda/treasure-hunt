class_name MainMenu extends Node2D

@onready var btn_start:Button = $Panel/StartButton
@onready var quit_start:Button = $Panel/QuitButton

func _ready() -> void:
	if btn_start:
		btn_start.pressed.connect(_on_start_pressed)

	if quit_start:
		quit_start.pressed.connect(_on_quit_pressed)


func _on_start_pressed()->void:
	print("start game")

func _on_quit_pressed()->void:
	print("quit game")
