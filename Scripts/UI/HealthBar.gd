extends Control
class_name SphereHealthBar

@onready var text : Label = %Text
@onready var sphere_health: ColorRect = %SphereHealth

func _ready() -> void:
	GameManager.get_player().get_health_node().update_health.connect(update_ui)
	init_ui()

func init_ui() -> void:
	var max_health: float = GameManager.get_player().get_max_health()
	var current_health: float = GameManager.get_player().get_current_health()
	update_ui(current_health, max_health)

func update_ui(current_health: float, max_health: float) -> void:
	text.text = "%.1f"%current_health +  "/"  + "%.1f"%max_health
	var fill_per: float = current_health / max_health
	sphere_health.material["shader_parameter/fill_per"] = fill_per
