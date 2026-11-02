class_name MiningGameMode extends Node2D
@onready var player_bullets_pool: PoolFracture = $PlayerBulletsPool

func _ready() -> void:
	Tutorial.show_once.call_deferred("mining")

## Skills marked for this mode apply here, see [method SkillProgress.get_mode_for].
func get_skill_mode() -> int:
	return Constants.GameModeFlag.MINING

func _on_terminate_button_pressed() -> void:
	GameManager.emit_level_completed(Constants.ERROR_210)
