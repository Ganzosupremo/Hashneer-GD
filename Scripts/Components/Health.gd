extends Node2D
class_name HealthComponent

signal zero_health()
signal update_health(current_health: float, max_health: float)

@export var max_health: float = 300.0
var current_health: float = 0.0

func _ready() -> void:
	current_health = max_health
	_update_health()

func set_max_health(new_health: float):
	max_health = new_health
	current_health = max_health

func increase_max_health(new_max: float) -> void:
	max_health = new_max
	current_health = max_health

func heal(amount_to_heal: float) -> void:
	current_health = clamp(current_health + amount_to_heal, 0.0, max_health)
	_update_health()

func take_damage(damage: float) -> void:
	current_health -= damage
	_update_health()
	
	if current_health <= 0.0:
		emit_signal("zero_health")

func get_current_health() -> float:
	return current_health

func get_max_health() -> float:
	return max_health

func _update_health() -> void:
	emit_signal("update_health", current_health, max_health)
