class_name UpgradeData extends Resource

signal next_tier_unlocked()
signal upgrade_maxed()

enum SKILL_NODE_STATUS {LOCKED = 0, UNLOCKED = 1, MAXED_OUT = 2}


@export_category("Upgrade Basic Parameters")
## Deprecated. Used internally to keep track of unlocked skills
#@export var skill_type: SkillType
@export var upgrade_name: String = ""
@export_multiline var upgrade_description: String = ""
@export var skill_image: Texture = Texture.new()
@export var upgrade_tier: int = 0
## Defines the type of skill this is. True will just upgrade an ability/skill. False to unlock an entire new skill/ability
@export var is_upgrade: bool = false
#@export var i_unlocked: bool = false
## 
@export var status: SKILL_NODE_STATUS = SKILL_NODE_STATUS.LOCKED
## Defines if the upgrade should be in percentage increase or flat increase.
@export var is_percentage: bool = false

@export_category("Upgrade Power")
## The starting increase of this upgrade.
@export var upgrade_base_power: float = 5.0
## The upgrade_base_power will increase by this multiplier with each purchase.
@export var upgrade_power_multiplier: float = 1.2

#@export_category("Upgrade Power in Bitcoin")
#@export var bitcoin_base_power: float = 15.0
#@export var bitcoin_power_multiplier: float = 1.5

@export_category("Upgrade Cost")
## The initial cost for this upgrade.
@export var upgrade_cost_base: float = 10.0
## The cost for this upgrade will increase by this multiplier with each purchase.
@export var upgrade_cost_multiplier: float = 1.2

#@export_category("Upgrade Cost in Bitcoin")
#@export var bitcoin_cost_base: float = 1.0
#@export var bitcoin_cost_multiplier: float = 1.05

@export var upgrade_max_level : int = 10

var next_tier_threshold: int = int(upgrade_max_level * 0.6) # 60% of max level
var upgrade_level: int = 0
	#set(value):
		#upgrade_level = value
		#check_next_tier_unlock()
		#check_upgrade_maxed_out()
var _id: int = 0
var current_power: float = 0.0

# ------------------ MAIN FUNCTIONS ----------------------------

func apply_upgrade() -> float:
	return get_upgrade_power()

## Returns the status of the upgrade. If it's locked, unlocked or maxed out
func get_upgrade_status() -> SKILL_NODE_STATUS:
	return status

func set_upgrade_status(new: SKILL_NODE_STATUS) -> void:
	status = new


func buy_upgrade(in_bitcoin: bool = false) -> bool:
	if upgrade_level >= upgrade_max_level: return false
	
	if in_bitcoin:
		return _buy_with_bitcoin()
	else:
		return _buy_with_fiat()


func _buy_with_bitcoin() -> bool:
	if BitcoinWallet.spend_bitcoin(upgrade_cost()):
		upgrade_level = min(upgrade_level+1, upgrade_max_level)
		check_upgrade_maxed_out()
		check_next_tier_unlock()
		_upgrade_power()
		return true
		#apply_upgrade()
	else:
		print("Not enough Bitcoin balance: {0}".format([BitcoinWallet.get_bitcoin_balance()]))
		return false


func _buy_with_fiat() -> bool:
	if BitcoinWallet.spend_fiat(upgrade_cost()):
		upgrade_level = min(upgrade_level+1, upgrade_max_level)
		check_upgrade_maxed_out()
		check_next_tier_unlock()
		_upgrade_power()
		return true
		#apply_upgrade()
	else:
		print("Not enough fiat balance: {0}".format([BitcoinWallet.get_fiat_balance()]))
		return false

func buy_max(in_bitcoin: bool = false) -> void:
	if upgrade_level >= upgrade_max_level: return
	
	if !in_bitcoin:
		if BitcoinWallet.spend_fiat(_buy_max(in_bitcoin)):
			_upgrade_power()
			#apply_upgrade()
			return
		else:
			print("Not enough fiat balance: {0}".format([BitcoinWallet.get_fiat_balance()]))
			return
	
	if BitcoinWallet.spend_bitcoin(_buy_max(in_bitcoin)):
		_upgrade_power()
		#apply_upgrade()
	else:
		print("Not enough Bitcoin balance: {0}".format([BitcoinWallet.get_bitcoin_balance()]))

func _buy_max(in_bitcoin: bool = false) -> float:
	var balance: float = 0.0
	if in_bitcoin:
		balance = BitcoinWallet.get_bitcoin_balance()
	else:
		balance = BitcoinWallet.get_fiat_balance()
	
	var n: int = floor(_log((balance * (upgrade_cost_multiplier - 1.0)) / upgrade_cost() + 1.0, upgrade_cost_multiplier))
	if n >= upgrade_max_level: n = upgrade_max_level
	upgrade_level += n
	
	if check_upgrade_maxed_out():
		upgrade_level = upgrade_max_level
	
	check_next_tier_unlock()
	return upgrade_cost() * ((pow(upgrade_cost_multiplier, n) - 1.0) / (upgrade_cost_multiplier - 1.0))


#----------------------- COST FUNCTIONS ---------------------


func upgrade_cost() -> float:
	return upgrade_cost_base * pow(upgrade_cost_multiplier, upgrade_level)

func upgrade_cost_string() -> String:
	return str(upgrade_cost())

#func _cost() -> float:
	#return upgrade_cost_base * pow(upgrade_cost_multiplier, upgrade_level)

#func _bitcoin_cost() -> float:
	#return upgrade_cost_base * pow(upgrade_cost_multiplier, upgrade_level)

# ----------------------- POWER FUNCTIONS -------------------------

func get_upgrade_power() -> float:
	return current_power

func _upgrade_power() -> void:
	current_power += _power()
#
#func _bitcoin_power() -> float:
	#var total: float = 0.0
	#total += bitcoin_base_power * pow(bitcoin_power_multiplier, upgrade_level)
	#return total

func _power() -> float:
	var total: float = 0.0
	total += upgrade_base_power * pow(upgrade_power_multiplier, upgrade_level)
	return total

# --------------- OTHER FUNCTIONS -------------------------

func _log(value: float, base: float) -> float:
	return 2.302585 / log(base) * (log(value) / log(10))


func check_upgrade_maxed_out() -> bool:
	if upgrade_level == upgrade_max_level:
		if status != SKILL_NODE_STATUS.MAXED_OUT:
			print("Upgrade maxed out, shoud become gold now...")
			emit_signal("upgrade_maxed")
		status = SKILL_NODE_STATUS.MAXED_OUT
		return true
	return false

func check_next_tier_unlock() -> bool:
	if upgrade_level >= next_tier_threshold:
		if status != SKILL_NODE_STATUS.UNLOCKED:
			print("Next tier node should unlock now...")
			emit_signal("next_tier_unlocked")
		status = SKILL_NODE_STATUS.UNLOCKED
		return true
	return false

func _to_string() -> String:
	return "ID: %s"%_id + "\nLevel: %s"%upgrade_level + "\nFiat Cost: %s"%upgrade_cost() + "\nBitcoin Cost: %s"%upgrade_cost()
