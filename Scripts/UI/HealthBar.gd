extends Control
class_name HealthBar

@onready var health_bar : TextureProgressBar = %THealthBar
@onready var text : Label = %Text

func _ready() -> void:
	GameManager.player.get_health_node().update_health.connect(update_ui)
	init_ui()

func init_ui() -> void:
	var max_health: float = GameManager.player.get_max_health()
	var current_health: float = GameManager.player.get_current_health()
	health_bar.max_value = max_health
	update_ui(current_health, max_health)


func update_ui(current_health: float, max_health: float) -> void:
	health_bar.value = current_health
	text.text = "HP Remaining: " + "%.1f"%current_health +  "/"  + "%.1f"%max_health
