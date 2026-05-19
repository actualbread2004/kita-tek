extends Label

var upgrade_cost: int = 300

@onready var player = get_parent().get_parent()

func _ready() -> void:
	text = "Press X to improve Drone speed\nCost: %d score (Level %d)" % [upgrade_cost, Global.drone_level]

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("upgrade"):
		if Global.score >= upgrade_cost:
	
			Global.score -= upgrade_cost
			
			player.max_speed += 50
			player.acceleration += 50
			player.vertical_speed += 30
			player.friction += 20
			
			Global.drone_level += 1
			upgrade_cost *= 2
			
			text = "Press X to improve Drone speed\nCost: %d score (Level %d)" % [upgrade_cost, Global.drone_level]
		else:
			add_theme_color_override("font_color", Color.RED)
			await get_tree().create_timer(0.2).timeout
			add_theme_color_override("font_color", Color.WHITE)
