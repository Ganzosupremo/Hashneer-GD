extends Control

@onready var main_game_packed: PackedScene = preload("res://Scenes/UI/SaveSlotsSelector.tscn")
@onready var start_game: TweenableButton = %StartGame
@onready var quit_game: TweenableButton = %QuitGame

func _ready() -> void:
	start_game.grab_focus()

func _on_button_pressed() -> void:
	await start_game.sound_effect_component_ui.play_sound()
	SceneManager.switch_scene_with_packed(main_game_packed)

func _on_quit_game_button_pressed() -> void:
	await quit_game.sound_effect_component_ui.play_sound()
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
