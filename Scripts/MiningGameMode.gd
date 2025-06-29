extends Node2D


func _on_terminate_button_pressed() -> void:
	GameManager.emit_level_completed(Constants.ERROR_210)
