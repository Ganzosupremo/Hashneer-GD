extends Resource
class_name SkillUpgradeData

signal next_tier_unlocked()
signal upgrade_maxed()

enum SkillType {
	DAMAGE_UPGRADE1,
	DAMAGE_UPGRADE2,
	DAMAGE_UPGRADE3,
	SPEED_UPGRADE1,
	SPEED_UPGRADE2,
	SPEED_UPGRADE3,
	HEALTH_UPGRADE1,
	HEALTH_UPGRADE2,
	HEALTH_UPGRADE3
}

@export_category("Upgrade Base")
## Used internally to keep track of unlocked skills
@export var skill_type: SkillType
## Used in the Game UI
@export var upgrade_name: String = ""
@export_multiline var upgrade_description: String = ""
@export var upgrade_tier: int = 0
## Defines the type of skill this is. True will just upgrade an ability/skill. False to unlock an entire new skill/ability
@export var is_upgrade: bool = false
@export var is_unlocked: bool = false

@export_category("Upgrade Power")
@export var upgrade_base_power: float = 5.0
@export var upgrade_power_multiplier: float = 1.2

@export_category("Upgrade Power in Bitcoin")
@export var bitcoin_base_power: float = 15.0
@export var bitcoin_power_multiplier: float = 1.5

@export_category("Upgrade Cost")
@export var upgrade_cost_base: float = 10.0
@export var upgrade_cost_multiplier: float = 1.2

@export_category("Upgrade Cost in Bitcoin")
@export var bitcoin_cost_base: float = 1.0
@export var bitcoin_cost_multiplier: float = 1.05


@export var upgrade_max_level : int = 10

var next_tier_threshold: int = int(upgrade_max_level * 0.3) # 30% of max level
var upgrade_level: int = 0:
	set(value):
		upgrade_level = value
		check_next_tier_unlock()
		check_upgrade_maxed_out()
var _id: int = 0
var current_power: float = 0.0

# ------------------ MAIN FUNCTIONS ----------------------------

func buy_upgrade(is_bitcoin: bool = false):
	if is_bitcoin:
		_buy_with_bitcoin()
	else:
		_buy_with_fiat()

func _buy_with_bitcoin() -> void:
	if BitcoinWallet.spend_bitcoin(upgrade_cost(true)):
		upgrade_level = min(upgrade_level+1, upgrade_max_level)
		check_upgrade_maxed_out()
		check_next_tier_unlock()
		upgrade_power(true)
		

func _buy_with_fiat() -> void:
	if BitcoinWallet.spend_fiat(upgrade_cost(false)):
		upgrade_level = min(upgrade_level+1, upgrade_max_level)
		check_upgrade_maxed_out()
		check_next_tier_unlock()
		upgrade_power(false)


func buy_max(is_bitcoin: bool = false):
	if is_bitcoin:
		if BitcoinWallet.spend_bitcoin(_buy_max_bitcoin()):
			check_upgrade_maxed_out()
			check_next_tier_unlock()
			upgrade_power(true)
	else:
		if BitcoinWallet.spend_fiat(_buy_max_fiat()):
			check_upgrade_maxed_out()
			check_next_tier_unlock()
			upgrade_power(false)
			

func _buy_max_bitcoin() -> float:
	var n: int = floor(_log((BitcoinWallet.get_bitcoin_balance() * (bitcoin_cost_multiplier - 1.0)) / upgrade_cost(true) + 1.0, bitcoin_cost_multiplier))
	if n >= upgrade_max_level: n = upgrade_max_level
	upgrade_level += n
	if upgrade_level >= upgrade_max_level: upgrade_level = upgrade_max_level
	
	return upgrade_cost(true) * ((pow(bitcoin_cost_multiplier, n) - 1.0) / (bitcoin_cost_multiplier - 1.0))

func _buy_max_fiat() -> float:
	var n: int = floor(_log((BitcoinWallet.get_fiat_balance() * (upgrade_cost_multiplier - 1.0)) / upgrade_cost(false) + 1.0, upgrade_cost_multiplier))
	if n >= upgrade_max_level: n = upgrade_max_level
	upgrade_level += n
	if upgrade_level >= upgrade_max_level: upgrade_level = upgrade_max_level
	
	return upgrade_cost(false) * ((pow(upgrade_cost_multiplier, n) - 1.0) / (upgrade_cost_multiplier - 1.0))


#----------------------- COST FUNCTIONS ---------------------


func upgrade_cost(is_bitcoin: bool = false) -> float:
	if is_bitcoin:
		return _bitcoin_cost()
	else:
		return _fiat_cost()

func _fiat_cost() -> float:
	return upgrade_cost_base * pow(upgrade_cost_multiplier, upgrade_level)

func _bitcoin_cost() -> float:
	return bitcoin_cost_base * pow(bitcoin_cost_multiplier, upgrade_level)

# ----------------------- POWER FUNCTIONS -------------------------

func get_upgrade_power() -> float:
	return current_power

func upgrade_power(is_bitcoin: bool) -> void:
	if is_bitcoin:
		current_power += _bitcoin_power()
	else:
		current_power += _fiat_power()

func _bitcoin_power() -> float:
	var total: float = 0.0
	total += bitcoin_base_power * pow(bitcoin_power_multiplier, upgrade_level)
	return total

func _fiat_power() -> float:
	var total: float = 0.0
	total += upgrade_base_power * pow(upgrade_power_multiplier, upgrade_level)
	return total

# --------------- OTHER FUNCTIONS -------------------------

func _log(value: float, base: float) -> float:
	return 2.302585 / log(base) * (log(value) / log(10))

func can_update_status() -> bool:
	return check_next_tier_unlock() || check_upgrade_maxed_out()

func check_upgrade_maxed_out() -> bool:
	if upgrade_level == upgrade_max_level:
		emit_signal("upgrade_maxed")
		return true
	else: return false

func check_next_tier_unlock() -> bool:
	if upgrade_level >= next_tier_threshold:
		emit_signal("next_tier_unlocked")
		return true
	else: return false

func _to_string() -> String:
	return "ID: %s"%_id +"\nUnlocked: %s"%is_unlocked + "\nLevel: %s"%upgrade_level + "\nFiat Cost: %s"%upgrade_cost() + "\nBitcoin Cost: %s"%upgrade_cost(true)
