extends Control
class_name HealthBar

@onready var health_bar : TextureProgressBar = %THealthBar
@onready var text : Label = %Text

func _ready() -> void:
	GameManager.player.get_health_node().damage_taken.connect(update_ui)
	init_ui()

func init_ui() -> void:
	var initial_health: float = GameManager.player.get_initial_health()
	var current_health: float = GameManager.player.get_current_health()
	health_bar.max_value = initial_health
	health_bar.value = current_health
	text.text = "HP Remaining: " + str(current_health) + " / " + str(initial_health)

func update_ui(_damage_taken: float) -> void:
	var initial_health: float = GameManager.player.get_initial_health()
	var current_health: float = GameManager.player.get_current_health()
	health_bar.value = current_health
	text.text = "HP Remaining: " + "%.1f" %current_health + " / " + "%.1f" %initial_health
