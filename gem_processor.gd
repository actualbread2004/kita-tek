extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D and Global.is_holding_object == false:
		Global.score += (200 + 200 * Global.processor_level)
		body.queue_free()
	
