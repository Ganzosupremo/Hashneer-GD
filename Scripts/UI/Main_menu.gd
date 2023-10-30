extends Control

var main_game_ui: String = "res://Scenes/UI/Main_game_ui.tscn"

func _on_button_pressed() -> void:
	SceneManager.switch_scene(main_game_ui)


func _on_quit_game_button_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
