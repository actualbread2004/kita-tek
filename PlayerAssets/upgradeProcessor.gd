extends Label

var current_level: int = 1
var upgrade_cost: int = 500


func _ready() -> void:
	# Set the initial text when the game starts
	text = "Press Z to upgrade Crystal Processor\nCost: %d score (Level %d)" % [upgrade_cost, current_level]

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("upgrade_processor"):
		if Global.score >= upgrade_cost:
	
			Global.score -= upgrade_cost
			Global.processor_level += 1
			
			upgrade_cost += 500
			
			text = "Press Z to upgrade Crystal Processor\nCost: %d score (Level %d)" % [upgrade_cost, Global.processor_level]
		else:
			add_theme_color_override("font_color", Color.RED)
			await get_tree().create_timer(0.2).timeout
			add_theme_color_override("font_color", Color.WHITE)
