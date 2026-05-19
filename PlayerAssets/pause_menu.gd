extends ColorRect

@onready var continue_button = $CenterContainer/VBoxContainer/ContinueBtn
@onready var restart_button = $CenterContainer/VBoxContainer/RestartBtn
@onready var exit_button = $CenterContainer/VBoxContainer/ExitBtn
@onready var mute_checkbox = $CenterContainer/VBoxContainer/MuteCheckBox

func _ready() -> void:
	visible = false
	
	continue_button.pressed.connect(_on_continue_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	mute_checkbox.toggled.connect(_on_mute_toggled)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_button"):
		toggle_pause()

func toggle_pause() -> void:
	# Flip the current pause state
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	
	if new_pause_state:
		visible = true # Show the translucent screen and buttons
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE 
	else:
		visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_continue_pressed() -> void:
	# Unpause and hide the menu
	toggle_pause()

func _on_restart_pressed() -> void:
	# Unpause the game first, otherwise the new scene will start frozen!
	get_tree().paused = false 
	get_tree().reload_current_scene()

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_mute_toggled(toggled_on: bool) -> void:
	# Find the Master audio bus
	var master_bus = AudioServer.get_bus_index("Master")
	
	# Mute or unmute it based on the checkbox state
	AudioServer.set_bus_mute(master_bus, toggled_on)
