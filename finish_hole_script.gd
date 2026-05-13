extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		
		Global.is_in_tutorial = false
		var items_to_delete = get_tree().get_nodes_in_group("TutorialElements")

		for item in items_to_delete:
			item.queue_free()
			
		queue_free()
