extends Resource
class_name UpgradeBase

signal next_tier_unlocked()

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

var next_tier_threshold: int = int(upgrade_max_level * 0.3) # 30% of max level
var upgrade_level: int = 0:
	set(value):
		upgrade_level = value
		check_next_tier_unlock()
	get:
		return upgrade_level

func buy_upgrade():
	print("Currency Left: %s" % UpgradesManager.currency)
	
	upgrade_level = min(upgrade_level+1, upgrade_max_level)
	UpgradesManager.update_skill_stats(self)
	check_next_tier_unlock()

func buy_max():
	var n: int = floor(my_log((UpgradesManager.currency * (upgrade_cost_multiplier - 1.0) + 1.0) / upgrade_cost(), upgrade_cost_multiplier))
	var cost: float = upgrade_cost() * ((pow(upgrade_cost_multiplier, n) - 1.0) / (upgrade_cost_multiplier - 1.0))
	
	if UpgradesManager.currency < cost: return
	UpgradesManager.currency -= cost
	upgrade_level += n
	UpgradesManager.update_skill_stats(self)
	check_next_tier_unlock()

func upgrade_power() -> float:
	var total = 1.0
	total += upgrade_base_power * pow(upgrade_power_multiplier, upgrade_level)
	return total

func my_log(value: float, base: float) -> float:
	return 2.302585 / log(base) * (log(value) / log(10))

func upgrade_cost() -> float:
	return upgrade_cost_base * pow(upgrade_cost_multiplier, upgrade_level)

func build_skill_dictionary() -> Dictionary:
	return {
		id: {
			"is_upgrade": is_upgrade,
			"unlocked": false,
			"level": upgrade_level,
			"power": upgrade_power()
		},
		
	}

func check_next_tier_unlock():
	if upgrade_level >= next_tier_threshold:
		emit_signal("next_tier_unlocked")

func _to_string() -> String:
	return "[Node: %s]" % [upgrade_name]
