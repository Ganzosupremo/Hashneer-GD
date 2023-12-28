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
	if (UpgradesManager.is_skill_unlocked("Player_Health_UpgradeI")):
		total += UpgradesManager.upgrades["Player_Health_UpgradeI"]["power"]
	if (UpgradesManager.is_skill_unlocked("Player_Health_UpgradeII")):
		total += UpgradesManager.upgrades["Player_Health_UpgradeII"]["power"]
	if (UpgradesManager.is_skill_unlocked("Player_Health_UpgradeIII")):
		total += UpgradesManager.upgrades["Player_Health_UpgradeIII"]["power"]
	
	return total

func on_quadrant_hitted(deal_damage: float) -> void:
	substract_power(deal_damage)

func substract_power(deal_damage: float) -> void:
	current_power -= deal_damage
	emit_signal("damage_taken", deal_damage)
	
	if current_power <= 0.0:
		emit_signal("zero_power")
