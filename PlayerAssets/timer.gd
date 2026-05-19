extends Label

# 300 sec = 5 min
var time_left: float = 300.0 
var game_over: bool = false

func _process(delta: float) -> void:
	if Global.is_in_tutorial == true:
			text = ""
	# Check for restart if the game is over
	if game_over:
		if Input.is_physical_key_pressed(KEY_R):
			get_tree().reload_current_scene() # Restarts the current level
		return 

	# Countdown
	if time_left > 0 && Global.is_in_tutorial == false:
		time_left -= delta
		
		# Colored timer
		if time_left <= 60.0:
			add_theme_color_override("font_color", Color.RED)
		elif time_left <= 150.0:
			add_theme_color_override("font_color", Color.YELLOW)
		else:
			add_theme_color_override("font_color", Color.WHITE)
		
		# Game over
		if time_left <= 0:
			add_theme_font_size_override("font_size", 64)
			add_theme_color_override("font_color", Color.DARK_RED)
			time_left = 0
			game_over = true
			horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			text = "You lose!\nPress R to restart" 
			return
			
		# Calculate and format the time
		var minutes: int = int(time_left) / 60
		var seconds: int = int(time_left) % 60
		
		text = "Time left: %02d:%02d" % [minutes, seconds]
