extends Control
class_name HealthBar

@onready var health_bar : TextureProgressBar = %THealthBar
@onready var text : Label = %Text

func _ready() -> void:
	await get_tree().process_frame
	GameManager.player.health.damage_taken.connect(update_ui)
	init_ui()

func init_ui() -> void:
	health_bar.max_value = GameManager.player.health.initial_power
	health_bar.value = GameManager.player.health.current_power
	text.text = "Power " + str(GameManager.player.health.current_power) + " / " + str(GameManager.player.health.initial_power)

func update_ui(_damage_taken: float) -> void:
	health_bar.value = GameManager.player.health.current_power
	text.text = "Power " + "%.1f"%GameManager.player.health.get_current_power()+ " / " + "%.1f"%GameManager.player.health.get_initial_power()



