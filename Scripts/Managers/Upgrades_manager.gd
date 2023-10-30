extends Node2D
class_name UpdradeM

var damage_upgrade_base_power: float = 5.0
var damage_upgrade_power_multiplier: float = 1.50
var damage_upgrade_cost:float = 5.0
var damage_upgrade_cost_multiplier: float = 1.75
var damage_upgrade_level:int = 0
@export var currency: float = 10000.0

var upgrades: Dictionary = {
	"Damage_upgrade": {
		"is_upgrade":true,
		"unlocked": false,
		"level": 0,
		"power": 0.0
	}
}

func unlock_skill(data: String):
	if data in upgrades.keys():
		upgrades[data]["unlocked"] = true

func update_skill_stats(data: UpgradeBase):
	if data.id in upgrades.keys():
		if !is_skill_unlocked(data.id): unlock_skill(data.id)
		
		upgrades[data.id]["is_upgrade"] = data.is_upgrade
		upgrades[data.id]["level"] = data.upgrade_level
		upgrades[data.id]["power"] = data.upgrade_power()


## Checks if the skill is already unlocked
func is_skill_unlocked(data: String) -> bool:
	return upgrades[data]["unlocked"]

func buy_upgrade(type: String):
	match type:
		"damage":
			buy(type)
	
func buy(type: String) -> void:
	if currency >= upgrade_cost(type):
		currency -= upgrade_cost(type)
		damage_upgrade_level += 1
		damage_upgrade_base_power += 5.0

func damage_power() -> float:
	var total = 1.0
	total += damage_upgrade_base_power * pow(damage_upgrade_power_multiplier, damage_upgrade_level)
	return total


func upgrade_cost(type: String) -> float:
	match type:
		"damage":
			return damage_upgrade_cost * pow(damage_upgrade_cost_multiplier, damage_upgrade_level)
	return 0.0


