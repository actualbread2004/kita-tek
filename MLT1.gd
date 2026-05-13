extends Area3D

@onready var tower_model: Node3D = $"../Model"

var target: Node3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	if is_instance_valid(target):
		
		var target_pos = target.global_position
		
		target_pos.y = tower_model.global_position.y 
		
		if tower_model.global_position.distance_to(target_pos) > 0.1:
			tower_model.look_at(target_pos, Vector3.UP)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Enemy"):
		target = body

func _on_body_exited(body: Node3D) -> void:
	if body == target:
		target = null
