extends Control

@onready var start_game: Button = %StartGame
@onready var quit_game: Button = %QuitGame
@onready var network_layer: ColorRect = $Background/NetworkLayer

@export var main_menu_music: MusicDetails

var time_passed: float = 0.0

func _ready() -> void:
	start_game.grab_focus()
	AudioManager.change_music_clip(main_menu_music, 2.5)
	
	# Add subtle fade-in animation
	modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.8)

func _on_animation_timer_timeout() -> void:
	time_passed += 0.05
	if network_layer and network_layer.material:
		network_layer.material.set_shader_parameter("time", time_passed)

func _on_button_pressed() -> void:
	SceneManager.switch_scene_with_enum(SceneManager.MainScenes.SAVE_SLOTS_SELECTOR)

func _on_quit_game_button_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
