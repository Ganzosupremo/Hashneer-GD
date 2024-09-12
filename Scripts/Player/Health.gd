extends Node2D
class_name Health

signal zero_health()
signal damage_taken(damage_dealt: float)

@export var initial_health: float = 50.0

var current_health: float = 0.0

func _ready() -> void:
	current_health = initial_health
	GameManager.quadrant_hitted.connect(on_quadrant_hitted)

func set_initial_health(new_health: float):
	initial_health = new_health
	current_health = initial_health

func increase_max_health(new_max: float) -> void:
	initial_health = new_max
	current_health = initial_health

func on_quadrant_hitted(deal_damage: float) -> void:
	substract_health(deal_damage)

func heal(amount_to_heal: float) -> void:
	current_health += amount_to_heal
	
	if current_health >= initial_health:
		current_health = initial_health

func substract_health(damage: float) -> void:
	current_health -= damage
	emit_signal("damage_taken", damage)
	
	if current_health <= 0.0:
		emit_signal("zero_health")

func get_current_health() -> float:
	return current_health

func get_initial_health() -> float:
	return initial_health
