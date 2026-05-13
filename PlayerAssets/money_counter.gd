extends Label

func _process(delta: float) -> void:
	text = "Money: " + str(Global.money) + " €"
