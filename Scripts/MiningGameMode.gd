extends Node2D
@onready var player_bullets_pool: PoolFracture = $PlayerBulletsPool


func _ready() -> void:
	GameManager.main_event_bus.emit_bullet_pool_setted({
		"player_pool": player_bullets_pool,
		"enemy_pool": null
	})

func _on_terminate_button_pressed() -> void:
	GameManager.emit_level_completed(Constants.ERROR_210)
