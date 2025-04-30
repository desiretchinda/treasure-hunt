extends Node

@onready var sfx_click:AudioStream = preload("res://Audios/Sfx/Click.wav")
@onready var sfx_coin:AudioStream = preload("res://Audios/Sfx/coin.mp3")

var sfx_stream:AudioStreamPlayer

func _ready() -> void:
	sfx_stream = AudioStreamPlayer.new()
	add_child(sfx_stream)

func play_click()->void:
	sfx_stream.stream = sfx_click
	sfx_stream.volume_db = 0
	sfx_stream.play()

func play_coin()->void:
	sfx_stream.stream = sfx_coin
	sfx_stream.volume_db = -10
	sfx_stream.play()
