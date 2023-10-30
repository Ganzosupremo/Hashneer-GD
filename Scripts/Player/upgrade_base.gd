extends Resource
class_name UpgradeBase

@export_category("Upgrade Base Parameters")
## Used internally to keep track of unlocked skills
@export var id: String = ""
## Used in the Game UI
@export var upgrade_name := ""
@export_multiline var upgrade_description := ""
@export var upgrade_tier: int = 0
## Defines the type of skill this is. True will just upgrade an ability/skill. False to unlock an entire new skill/ability
@export var is_upgrade: bool = false

@export_category("Upgrade Power")
@export var upgrade_base_power: float = 5.0
@export var upgrade_power_multiplier: float = 1.2

@export_category("Upgrade Cost Parameters")
@export var upgrade_cost_base: float = 10.0
@export var upgrade_cost_multiplier: float = 1.2
@export var upgrade_max_level : int = 100



var upgrade_level: int = 0:
	set(value):
		upgrade_level = value

#func buy_upgrade():
#	upgrade_level += 1
#	print("upgrade purchased")

func upgrade_power() -> float:
	var total = 1.0
	total += upgrade_base_power * pow(upgrade_power_multiplier, upgrade_level)
	return total

func upgrade_cost() -> float:
	return upgrade_cost_base * pow(upgrade_cost_multiplier, upgrade_level)
	
func _to_string() -> String:
	return "[Node: %s]" % [upgrade_name]
