extends Node3D

@export var asset_to_spawn : PackedScene 
@export var spawn_count : int = 50       
@export var radius : float = 500        
@export var random_y_rotation : bool = true

func _ready() -> void:
	spawn_assets()

func spawn_assets() -> void:

	for i in range(spawn_count):
		var instance = asset_to_spawn.instantiate()
		
		add_child(instance)
		
		var random_pos = get_random_position_in_radius()
		instance.position = random_pos
		
		if random_y_rotation:
			instance.rotation.y = randf_range(0, TAU) # TAU este 2 * PI

func get_random_position_in_radius() -> Vector3:
	# unghi aleatoriu intre 0 si 360 grade
	var angle = randf() * TAU

	# distanta random in intervalul [100,500]	
	var r = radius * sqrt(randf())
	while r < 150:
		r = radius * sqrt(randf())
		
	# convertim din coordonate polare in coordonate carteziene (X, Z)
	var x = r * cos(angle)
	var z = r * sin(angle)
	
	return Vector3(x, 9, z)
