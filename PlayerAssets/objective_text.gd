extends Label

func _process(delta: float) -> void:
	if Global.is_in_tutorial == false:
		text = "Objective: Get 10000 score"
