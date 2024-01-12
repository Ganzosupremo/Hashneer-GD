extends Node2D
class_name Health

signal zero_power()
signal damage_taken(damage_dealt: float)

@export var initial_power: float = 50.0

var current_power: float = 0.0

func _ready() -> void:
	initial_power += add_health_upgrades()
	current_power = initial_power
	GameManager.quadrant_hitted.connect(on_quadrant_hitted)

func add_health_upgrades() -> float:
	var total: float = 0.0
	var golden = "Golden Shell"
	var silver = "Silver Shell"
	var copper = "Copper Shell"
	total += UpgradesManager.get_skill_power(copper)
	total += UpgradesManager.get_skill_power(silver)
	total += UpgradesManager.get_skill_power(golden)
	
	return total

func on_quadrant_hitted(deal_damage: float) -> void:
	substract_power(deal_damage)

func substract_power(deal_damage: float) -> void:
	current_power -= deal_damage
	emit_signal("damage_taken", deal_damage)
	
	if current_power <= 0.0:
		emit_signal("zero_power")

func get_current_power() -> float:
	return current_power

func get_initial_power() -> float:
	return initial_power
