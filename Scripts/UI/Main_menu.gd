extends Control

@onready var main_game_packed: PackedScene = preload("res://Scenes/UI/SaveSlotsSelector.tscn")
@onready var start_game: TweenableButton = %StartGame
@onready var quit_game: TweenableButton = %QuitGame

@export var main_menu_music: MusicDetails

func _ready() -> void:
	start_game.grab_focus()
	AudioManager.change_music_clip(main_menu_music, 2.5)
	await NotificationManager.show_notification("Welcome to Hashneer!", 2.0)
	await NotificationManager.show_notification("Use the buttons below to start or quit the game.", 2.0)

func _on_button_pressed() -> void:
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_CLICK, AudioManager.DestinationAudioBus.SFX)
	SceneManager.switch_scene_with_packed(main_game_packed)

func _on_quit_game_button_pressed() -> void:
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_CLICK, AudioManager.DestinationAudioBus.SFX)
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
