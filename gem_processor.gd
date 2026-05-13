extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if "largecrystal" in body.name.to_lower():
		Global.money += 200
		body.queue_free()
