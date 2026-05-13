extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		print("Something entered the hole")
		# Do your stuff here (e.g., deal damage, trigger a cutscene)
