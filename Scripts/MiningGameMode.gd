class_name MiningGameMode extends Node2D
@onready var player_bullets_pool: PoolFracture = $PlayerBulletsPool

func _ready() -> void:
	Tutorial.show_once.call_deferred("mining")

func _on_terminate_button_pressed() -> void:
	GameManager.emit_level_completed(Constants.ERROR_210)
