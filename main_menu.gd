extends Control

func _on_new_game_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://Game.tscn")


func _on_exit_btn_pressed() -> void:
	get_tree().quit()
