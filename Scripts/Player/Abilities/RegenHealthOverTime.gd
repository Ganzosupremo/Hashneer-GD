class_name RegenHealthOverTime extends BaseAbility

var health: HealthComponent

@export var regen_rate: float = 10.0  # Amount of health restored per second.

func _on_activate() -> void:
	if health == null:
		health = _find_health_node()
	health.heal(regen_rate)

func _find_health_node() -> HealthComponent:
	return get_parent().get_health_node()
