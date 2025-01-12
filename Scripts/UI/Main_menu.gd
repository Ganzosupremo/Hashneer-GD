extends Control

@onready var main_game_packed: PackedScene = preload("res://Scenes/UI/save_slots_selector.tscn")
@onready var start_game: TweenableButton = $AspectRatioContainer/FlowContainer/StartGame

func _ready() -> void:
	start_game.grab_focus()

func _on_button_pressed() -> void:
	SceneManager.switch_scene_with_packed(main_game_packed)

func _on_quit_game_button_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
