extends Control
class_name PauseMenu


var paused: bool = false

func _ready() -> void:
	hide()


func pause() -> void:
	if paused:
		hide()
		get_tree().paused = false
	else:
		show()
		get_tree().paused = true
	paused = !paused


func _on_resume_button_pressed() -> void:
	pause()

func _on_main_menu_button_pressed() -> void:
	pause()
	SceneManager.switch_scene("res://Scenes/UI/Main_game_ui.tscn")
	SceneManager.toggle_main_ui()


func _on_quit_game_button_pressed() -> void:
	get_tree().quit()
