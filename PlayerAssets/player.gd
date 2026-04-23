extends CharacterBody3D

# ==========================================
# VARIABLES
# ==========================================

@export_group("Movement Settings")
@export var max_speed: float = 100.0
@export var acceleration: float = 150.0
@export var friction: float = 300.0
@export var vertical_speed: float = 40.0

@export_group("Building Settings")
@export var block_scene: PackedScene         # Put your StaticBody3D block here!

@export_group("Camera Settings")
@export var mouse_sensitivity: float = 0.002

# --- Node References ---
@onready var camera: Camera3D = $Camera3D
@onready var raycast: RayCast3D = $Camera3D/RayCast3D
@onready var hologram: MeshInstance3D = $Hologram
@onready var placeSound: AudioStreamPlayer = $PlaceSound
@onready var break_sound: AudioStreamPlayer = $BreakSound
@onready var ambient_music: AudioStreamPlayer = $AmbientMusic

# ==========================================
# ENGINE CALLBACKS (Built-in Functions)
# ==========================================

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hologram.visible = false # Hide hologram until we look at the ground/wall

func _process(_delta: float) -> void:
	# We use _process so the hologram moves smoothly on the screen every frame
	handle_hologram()

func _unhandled_input(event: InputEvent) -> void:
	# 1. Handle Mouse Look (Aiming)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		handle_camera_rotation(event)
		
	# 2. Handle Right Click (Place Block)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		elif hologram.visible: 
			place_block()
			
	# 3. Handle Left Click (Break Block)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			break_block()
			
	# 4. Handle Escape Key
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	handle_horizontal_movement(delta)
	handle_vertical_movement(delta)
	move_and_slide()


# ==========================================
# CUSTOM FUNCTIONS (Movement)
# ==========================================

func handle_camera_rotation(event: InputEventMouseMotion) -> void:
	rotate_y(-event.relative.x * mouse_sensitivity)
	camera.rotate_x(-event.relative.y * mouse_sensitivity)
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func handle_horizontal_movement(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * max_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)

func handle_vertical_movement(delta: float) -> void:
	var vertical_input = 0.0
	if Input.is_action_pressed("fly_up"):
		vertical_input += 1.0
	if Input.is_action_pressed("fly_down"):
		vertical_input -= 1.0

	if vertical_input != 0.0:
		velocity.y = move_toward(velocity.y, vertical_input * vertical_speed, acceleration * delta)
	else:
		velocity.y = move_toward(velocity.y, 0, friction * delta)

# ==========================================
# CUSTOM FUNCTIONS (Building & Snapping)
# ==========================================

func handle_hologram() -> void:
	"""Calculates perfect voxel grid-snapping math."""
	if raycast.is_colliding():
		hologram.visible = true
		
		var hit_point = raycast.get_collision_point()
		var hit_normal = raycast.get_collision_normal()
		
		# 1. Step slightly INTO the object we hit (so the math knows what block we are touching)
		var inside_point = hit_point - (hit_normal * 0.5)
		
		# 2. Snap that point to the absolute grid
		var snapped_center = inside_point.snapped(Vector3(20,20,20))
		
		# 3. Step exactly one whole unit OUTWARD in the direction of the face we hit
		var target_pos = snapped_center + hit_normal
		target_pos.y += 11.0
		
		# 4. Move the hologram to this perfect voxel coordinate
		hologram.global_position = target_pos
	else:
		hologram.visible = false

func place_block() -> void:
	"""Spawns the StaticBody3D block exactly where the hologram is."""
	if block_scene == null:
		printerr("Wait! You forgot to put the Block Scene in the Inspector!")
		return

	var new_block = block_scene.instantiate()
	get_tree().current_scene.add_child(new_block)
	
	new_block.global_position = hologram.global_position
	placeSound.pitch_scale = randf_range(0.85, 1.15)
	placeSound.play()

func break_block() -> void:
	if raycast.is_colliding():
		var target = raycast.get_collider()
		
		# Only delete it if it is in the "buildable" group!
		if target != null and target.is_in_group("buildable"):
			target.queue_free()
			break_sound.pitch_scale = randf_range(0.85, 1.15)
			break_sound.play()
