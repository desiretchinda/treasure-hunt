class_name Hud extends CanvasLayer

@onready var label_collected:Label = $Control/LabelCollected
@onready var label_goal1:Label = $Control/Goals/LabelGoal1
@onready var label_goal2:Label = $Control/Goals/LabelGoal2

func _ready() -> void:
	GameManager.coin_collected.connect(on_coin_collected)
	refresh_hud.call_deferred()

func refresh_hud()->void:
	label_goal1.text = "Collect "+str(MapGeneration.instance.get_total_coins_generated())+" coins."
	label_collected.text = ""+str(Player.instance.coins)+"/"+str(MapGeneration.instance.get_total_coins_generated())
	
	if Player.instance.has_collected_all_coins():
		label_goal1.label_settings.font_color = Color.GREEN

	if Player.instance.has_reached_starting_point():
		label_goal2.label_settings.font_color = Color.GREEN
	
func on_coin_collected()->void:
	refresh_hud()
