class_name Hud extends CanvasLayer

@onready var label_collected:Label = $Control/LabelCollected

func _ready() -> void:
	GameManager.coin_collected.connect(on_coin_collected)
	refresh_hud.call_deferred()

func refresh_hud()->void:
	label_collected.text = ""+str(Player.instance.coins)+"/"+str(MapGeneration.instance.get_total_coins_generated())

func on_coin_collected()->void:
	refresh_hud()
