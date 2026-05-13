extends CharacterBody3D

@export_group("Movement Settings")
@export var max_speed: float = 100.0
@export var acceleration: float = 150.0
@export var friction: float = 300.0
@export var vertical_speed: float = 40.0

@export_group("Building Settings")
@export var block_scene: PackedScene         

@export_group("Camera Settings")
@export var mouse_sensitivity: float = 0.002

# --- Node References ---
@onready var camera: Camera3D = $Camera3D
@onready var raycast: RayCast3D = $Camera3D/RayCast3D
@onready var pickup_raycast: RayCast3D = $Camera3D/PickupRaycast
@onready var hologram: MeshInstance3D = $Hologram
@onready var placeSound: AudioStreamPlayer = $PlaceSound
@onready var break_sound: AudioStreamPlayer = $BreakSound
@onready var ambient_music: AudioStreamPlayer = $AmbientMusic
@onready var hold_position = $Camera3D/HoldPosition

@export_group("Crosshairs")
@onready var color_rect_crosshair = $HUD/Crosshair 
@onready var hand_icon_rect = $HUD/HandIcon


var held_object: RigidBody3D = null

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hologram.visible = false # Hide hologram until we look at the ground/wall

func _process(_delta: float) -> void:
	if Global.is_in_tutorial:
		pass
	else:
		handle_hologram()
		
	# Handle picking up stuff
	if Input.is_action_just_pressed("pick_up") and held_object == null:
		try_pick_up()
	
	# Handle dropping stuff
	elif Input.is_action_just_pressed("drop") and held_object != null:
		drop_object()

func _unhandled_input(event: InputEvent) -> void:
	# 1. Handle Mouse Look (Aiming)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		handle_camera_rotation(event)
		
	# 2. Handle Right Click (Place Block)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		elif hologram.visible: 
			place_dynamite()
			
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
	var looking_at_interactable = false
	
	if held_object == null and pickup_raycast.is_colliding():
		var target = pickup_raycast.get_collider()
		if target is RigidBody3D:
			looking_at_interactable = true
			
	if looking_at_interactable:
		color_rect_crosshair.visible = false
		hand_icon_rect.visible = true
	else:
		color_rect_crosshair.visible = true
		hand_icon_rect.visible = false
		
	handle_horizontal_movement(delta)
	handle_vertical_movement(delta)
	move_and_slide()

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

func try_pick_up() -> void:
	if pickup_raycast.is_colliding():
		var target = pickup_raycast.get_collider()
		
		if target is RigidBody3D:
			held_object = target
			
			held_object.freeze = true 
			held_object.reparent(hold_position)
			
			held_object.position = Vector3.ZERO
			held_object.rotation = Vector3.ZERO

func drop_object() -> void:
	held_object.freeze = false
	held_object.reparent(get_tree().current_scene)
	held_object = null

func handle_hologram() -> void:
	"""Calculates perfect voxel grid-snapping math."""
		
	if raycast.is_colliding():
		hologram.visible = true
		
	
		var hit_point = raycast.get_collision_point()
		var hit_normal = raycast.get_collision_normal()
		
		var grid_size = 18.5
	
		# 1. Step INWARD to confidently find the cell we hit.
		var inside_point = hit_point - (hit_normal * 0.1)
	
		# 2. Create an offset to fix the "sinking into the floor" issue.
		# We want X and Z to snap to 0, 20, 40... 
		# But we want Y to snap to 10, 30, 50... so a 20-unit block sits ON the floor.
		var y_offset = Vector3(0, grid_size / 2.0, 0) 
		
		# 3. Find the perfect absolute center of the block/floor we hit.
		# We subtract the 10-unit offset, snap to the 20-grid, and add the 10 back.
		var snapped_inside = (inside_point - y_offset).snapped(Vector3(grid_size, grid_size, grid_size)) + y_offset
		
		# 4. Now that we know exactly where the hit block is, we just add 
		# exactly 20 units in the direction of the face we hit!
		var target_pos = snapped_inside + (hit_normal * grid_size)
		
		# 5. Place the hologram
		hologram.global_position = target_pos
		hologram.global_rotation = Vector3.ZERO
	else:
		hologram.visible = false

func place_dynamite() -> void:
	"""Spawns the StaticBody3D block exactly where the hologram is."""
	if block_scene == null:
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
			Global.money += 2;
