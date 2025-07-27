class_name UpgradeData extends Resource
## UpgradeData is a resource that contains all the data for a skill upgrade.
## 
## It is used to define the upgrade's name, description, cost, power, and other parameters.
## It also contains the logic for purchasing the upgrade, applying economic events, and checking if the upgrade is maxed out or if the next tier is unlocked.


signal next_tier_unlocked(next_tier_nodes: Array)
signal upgrade_maxed()
signal upgrade_level_changed(new_level: int, max_level: int)
signal update_ui()

enum PlayerFeatureType {
	## Default state.
	NONE,
	## Unlocks a new weapon, the weapon_to_unlock must be specified.
	WEAPON,
	## Unlocks a new player ability, not implemented yet.
	ABILITY,
	## Upgrades a player stat, like health, damage or speed.
	STAT_UPGRADE
}

## The type of stat to upgrade.
enum StatType {
	## Default state.
	NONE = 0,
	## Upgrades the player's health.
	HEALTH = 1,
	## Upgrades the player's speed.
	SPEED = 2,
	## Upgrades the player's damage multiplier.
	DAMAGE = 3
}


@export_category("Upgrade Basic Parameters")
## Defines if this node should unlock a new weapon, player ability or simply upgrade a player stat.
@export var feature_type: PlayerFeatureType = PlayerFeatureType.NONE
@export var upgrade_name: String = ""
@export_multiline var upgrade_description: String = ""
@export var upgrade_tier: int = 0
## Defines the type of skill this is. True will just upgrade an ability/skill. False to unlock an entire new skill/ability
@export var is_upgrade: bool = false
## Defines if the upgrade should be in percentage increase or flat increase.
@export var is_percentage: bool = false
@export var stat_type: StatType = StatType.NONE

@export_category("Weapon Unlock Settings")
@export var weapon_data: SkillNodeWeaponData

@export_category("Ability Unlock Settings")
@export var ability_data: SkillNodeAbilityData

@export_category("Upgrade Power")
## The starting increase of this upgrade.
@export var upgrade_base_power: float = 5.0
## The upgrade_base_power will increase by this multiplier with each purchase.
@export var upgrade_power_multiplier: float = 1.2

@export_category("Upgrade Cost")
## The initial cost for this upgrade. It has two base cost because of the inflation/deflation mecanic. Inflation inceases prices in fiat while deflation decreases prices in Bitcoin.
@export var upgrade_cost_base: float = 10.0
## The cost for this upgrade will increase by this multiplier with each purchase.
@export var upgrade_cost_multiplier: float = 1.2

@export_category("Upgrade Cost Bitcoin")
## The initial cost for this upgrade. It has two base cost because of the inflation/deflation mecanic. Inflation inceases prices in fiat while deflation decreases prices in Bitcoin.
@export var upgrade_cost_base_btc: float = 1.0
## The cost for this upgrade will increase by this multiplier with each purchase.
@export var upgrade_cost_multiplier_btc: float = 1.1

@export var upgrade_max_level : int = 10

## The threshold for the next tier of the upgrade. This is a percentage of the max level.
var next_tier_threshold: int = int(upgrade_max_level * 0.6) # 60% of max level
## The current level of the upgrade. This is used to determine the current power of the upgrade.
var upgrade_level: int = 0:
	set(value):
		if upgrade_level != value:
			upgrade_level = value
			upgrade_level_changed.emit(upgrade_level, upgrade_max_level)
			check_next_tier_unlock()
			check_upgrade_maxed_out()

## Store original cost values to restore when events expire
var _original_upgrade_cost_base: float = 0.0
var _original_upgrade_cost_base_btc: float = 0.0
var _has_stored_original_values: bool = false

var _next_tier_nodes: Array[SkillNode]
var _id: int = 0

## Helper function for conditional debug logging
func _debug_log(message: String) -> void:
	if OS.is_debug_build():
		print_debug("[UpgradeData] " + message)

#region Main

## Sets the next tier nodes for this upgrade.
func set_next_tier_nodes(nodes: Array[SkillNode]) -> void:
	self._next_tier_nodes = nodes.duplicate()

## Resets the next tier nodes array to an empty array.
func reset_next_tier_nodes() -> void:
	self._next_tier_nodes = []

## Buys the upgrade using the specified currency type.
## If the currency type is not specified, it defaults to fiat.
## Returns [code]true[/code] if the purchase was successful, [code]false[/code] otherwise.
## This function will also increase the upgrade level by 1 if the purchase is successful.
## It will not increase the level if the upgrade is already maxed out.
## If the upgrade is maxed out, it will not perform any purchase and return false.
func buy_upgrade(currency_type: Constants.CurrencyType = Constants.CurrencyType.FIAT) -> bool:
	if upgrade_level >= upgrade_max_level: return false

	var success: bool = _buy_with_bitcoin() if currency_type == Constants.CurrencyType.BITCOIN else _buy_with_fiat()
	if success:
		upgrade_level = min(upgrade_level+1, upgrade_max_level)
	return success

## Sets the ID of this upgrade data.
## This is used to identify the upgrade in the SkillNode.
func set_id(id:int = 0) -> void:
	_id = id

func _buy_with_bitcoin() -> bool:
	if BitcoinWallet.spend_bitcoin(upgrade_cost(Constants.CurrencyType.BITCOIN)):
		# It should increase the level only one time per purchase, but may leave as a feature
		# upgrade_level = min(upgrade_level+1, upgrade_max_level)
		return true
	else:
		return false

func _buy_with_fiat() -> bool:
	if BitcoinWallet.spend_fiat(upgrade_cost(Constants.CurrencyType.FIAT)):
		return true
	else:
		return false

## Buys the maximum number of upgrades possible with the current balance in the specified currency type.
## If the currency type is not specified, it defaults to fiat.
func buy_max(currency_type: Constants.CurrencyType = Constants.CurrencyType.FIAT) -> void:
	if upgrade_level >= upgrade_max_level: return

	if currency_type == Constants.CurrencyType.BITCOIN:
		BitcoinWallet.spend_bitcoin(_buy_max(currency_type))
	else:
		BitcoinWallet.spend_fiat(_buy_max(currency_type))

func _buy_max(currency_type: Constants.CurrencyType = Constants.CurrencyType.FIAT) -> float:
	var balance: float = 0.0

	balance = BitcoinWallet.get_bitcoin_balance() if currency_type == Constants.CurrencyType.BITCOIN else BitcoinWallet.get_fiat_balance()
	
	var n: int = floor(_log((balance * (upgrade_cost_multiplier - 1.0)) / upgrade_cost(currency_type) + 1.0, upgrade_cost_multiplier))
	if n >= upgrade_max_level: n = upgrade_max_level
	upgrade_level += n
	
	if upgrade_level >= upgrade_max_level:
		upgrade_level = upgrade_max_level
	
	check_next_tier_unlock()
	check_upgrade_maxed_out()
	return upgrade_cost(currency_type) * ((pow(upgrade_cost_multiplier, n) - 1.0) / (upgrade_cost_multiplier - 1.0))

#endregion

#region Cost

## Applies a random economic event to this upgrade.
## This function will modify the upgrade cost based on the economic event's impact.
## The event will not apply if the upgrade is already maxed out or if the event is null.
func apply_random_economic_event(_economic_event: EconomicEvent) -> void:
	if !_economic_event or upgrade_level >= upgrade_max_level:
		return

	# Store original values before applying the event (only once)
	_store_original_cost_values()

	match _economic_event.event_type:
		EconomicEvent.EventType.INFLATION:
			_apply_inflation_event(_economic_event)
		EconomicEvent.EventType.DEFLATION:
			_apply_deflation_event(_economic_event)
		EconomicEvent.EventType.MARKET_CRASH:
			_apply_market_crash_event(_economic_event)
		EconomicEvent.EventType.MARKET_BOOM:
			_apply_market_boom_event(_economic_event)
		EconomicEvent.EventType.TAX_CHANGE:
			_apply_tax_change_event(_economic_event)
		EconomicEvent.EventType.TECHNOLOGY_ADVANCEMENT:
			_apply_technology_advancement_event(_economic_event)
		EconomicEvent.EventType.NATURAL_DISASTER:
			_apply_natural_disaster_event(_economic_event)
	
	update_ui.emit()  # Emit signal to update UI after applying the economic event

## Reverts all economic event effects and restores original cost values.
## This should be called when an economic event expires.
func revert_economic_event_effects() -> void:
	if !_has_stored_original_values:
		return
	
	# Restore original cost values
	upgrade_cost_base = _original_upgrade_cost_base
	upgrade_cost_base_btc = _original_upgrade_cost_base_btc
	
	# _debug_log("Reverted economic event effects for upgrade: " + upgrade_name)
	# _debug_log("  Fiat cost restored to: " + str(upgrade_cost_base))
	# _debug_log("  Bitcoin cost restored to: " + str(upgrade_cost_base_btc))
	
	# Clear the stored values flag so new events can store fresh values
	_has_stored_original_values = false
	
	update_ui.emit()  # Emit signal to update UI after reverting

## Stores the original cost values before applying economic events.
## This is called automatically when the first economic event is applied.
func _store_original_cost_values() -> void:
	if _has_stored_original_values:
		return  # Already stored, don't overwrite
	
	_original_upgrade_cost_base = upgrade_cost_base
	_original_upgrade_cost_base_btc = upgrade_cost_base_btc
	_has_stored_original_values = true
	
	# _debug_log("Stored original cost values for upgrade: " + upgrade_name)
	# _debug_log("  Original fiat cost: " + str(_original_upgrade_cost_base))
	# _debug_log("  Original bitcoin cost: " + str(_original_upgrade_cost_base_btc))

#region Economic Event Handlers

func _apply_inflation_event(_economic_event: EconomicEvent) -> void:
	match _economic_event.currency_affected:
		Constants.CurrencyType.FIAT:
			upgrade_cost_base *= (1 + _economic_event.impact)
		Constants.CurrencyType.BITCOIN:
			upgrade_cost_base_btc *= (1 + _economic_event.impact)
		Constants.CurrencyType.BOTH:
			upgrade_cost_base *= (1 + _economic_event.impact)
			upgrade_cost_base_btc *= (1 + _economic_event.impact)

func _apply_deflation_event(_economic_event: EconomicEvent) -> void:
	match _economic_event.currency_affected:
		Constants.CurrencyType.FIAT:
			upgrade_cost_base *= (1 - _economic_event.impact)
		Constants.CurrencyType.BITCOIN:
			upgrade_cost_base_btc *= (1 - _economic_event.impact)
		Constants.CurrencyType.BOTH:
			upgrade_cost_base *= (1 - _economic_event.impact)
			upgrade_cost_base_btc *= (1 - _economic_event.impact)

func _apply_market_crash_event(_economic_event: EconomicEvent) -> void:
	match _economic_event.currency_affected:
		Constants.CurrencyType.FIAT:
			upgrade_cost_base *= (1 + _economic_event.impact)
		Constants.CurrencyType.BITCOIN:
			upgrade_cost_base_btc *= (1 + _economic_event.impact)
		Constants.CurrencyType.BOTH:
			upgrade_cost_base *= (1 + _economic_event.impact)
			upgrade_cost_base_btc *= (1 + _economic_event.impact)


func _apply_market_boom_event(_economic_event: EconomicEvent) -> void:
	match _economic_event.currency_affected:
		Constants.CurrencyType.FIAT:
			upgrade_cost_base *= (1 - _economic_event.impact)
		Constants.CurrencyType.BITCOIN:
			upgrade_cost_base_btc *= (1 - _economic_event.impact)
		Constants.CurrencyType.BOTH:
			upgrade_cost_base *= (1 - _economic_event.impact)
			upgrade_cost_base_btc *= (1 - _economic_event.impact)

func _apply_tax_change_event(_economic_event: EconomicEvent) -> void:
	match _economic_event.currency_affected:
		Constants.CurrencyType.FIAT:
			upgrade_cost_base *= (1 + _economic_event.impact)
		Constants.CurrencyType.BITCOIN:
			upgrade_cost_base_btc *= (1 + _economic_event.impact)
		Constants.CurrencyType.BOTH:
			upgrade_cost_base *= (1 + _economic_event.impact)
			upgrade_cost_base_btc *= (1 + _economic_event.impact)

func _apply_technology_advancement_event(_economic_event: EconomicEvent) -> void:
	match _economic_event.currency_affected:
		Constants.CurrencyType.FIAT:
			upgrade_cost_base *= (1 - _economic_event.impact)
		Constants.CurrencyType.BITCOIN:
			upgrade_cost_base_btc *= (1 - _economic_event.impact)
		Constants.CurrencyType.BOTH:
			upgrade_cost_base *= (1 - _economic_event.impact)
			upgrade_cost_base_btc *= (1 - _economic_event.impact)

func _apply_natural_disaster_event(_economic_event: EconomicEvent) -> void:
	upgrade_cost_base *= (1 + _economic_event.impact)
	upgrade_cost_base_btc *= (1 + _economic_event.impact)

#endregion

## Returns the cost of the upgrade in the specified currency type.
## If no currency type is specified, it defaults to fiat.
## The cost is calculated based on the upgrade level and the inflation/deflation adjustments.
func upgrade_cost(currency_type: Constants.CurrencyType = Constants.CurrencyType.FIAT) -> float:
	return _upgrade_cost_btc() if currency_type == Constants.CurrencyType.BITCOIN else _upgrade_cost_fiat()

func _upgrade_cost_fiat() -> float:
	var inflation_adjustment = FED.get_total_inflation()
	return upgrade_cost_base * pow(upgrade_cost_multiplier, upgrade_level) * inflation_adjustment

func _upgrade_cost_btc() -> float:
	var deflation_adjustment = BitcoinNetwork.get_deflation_multiplier()
	return upgrade_cost_base_btc * pow(upgrade_cost_multiplier_btc, upgrade_level) * deflation_adjustment

func upgrade_cost_string() -> String:
	return str(_upgrade_cost_fiat())

func upgrade_cost_btc_string() -> String:
	return str(_upgrade_cost_btc())

#endregion

#region Power

## Returns the current power of the upgrade based on the base power and the power multiplier.
## The power is calculated as: upgrade_base_power * (upgrade_power_multiplier ^ upgrade_level).
## This function is used to determine the effectiveness of the upgrade at the current level.
func get_current_power() -> float:
	return upgrade_base_power * pow(upgrade_power_multiplier, upgrade_level)

#endregion

#region Getters and Setters

func get_original_upgrade_cost_base() -> float:
	return _original_upgrade_cost_base

func get_original_upgrade_cost_base_btc() -> float:
	return _original_upgrade_cost_base_btc

func get_upgrade_cost_base() -> float:
	return upgrade_cost_base

func get_upgrade_cost_base_btc() -> float:
	return upgrade_cost_base_btc

func set_original_upgrade_cost_base(value: float) -> void:
	_original_upgrade_cost_base = value

func set_original_upgrade_cost_base_btc(value: float) -> void:
	_original_upgrade_cost_base_btc = value

func set_upgrade_cost_base(value: float) -> void:
	upgrade_cost_base = value

func set_upgrade_cost_base_btc(value: float) -> void:
	upgrade_cost_base_btc = value


#region Other

func _log(value: float, base: float) -> float:
	return 2.302585 / log(base) * (log(value) / log(10))

## Checks if the upgrade has reached its maximum level.
func check_upgrade_maxed_out() -> bool:
	if upgrade_level == upgrade_max_level:
		upgrade_maxed.emit()
		return true
	return false

## Checks if the next tier of the upgrade should be unlocked based on the current upgrade level.
## If the upgrade level exceeds the next tier threshold, it emits the next_tier_unlocked signal with the next tier nodes.
## If no next tier nodes are provided, it uses the current _next_tier_nodes.
## Returns [code]true[/code] if the next tier is unlocked, [code]false[/code] otherwise.
func check_next_tier_unlock(_next_tier_nodes_l: Array[SkillNode] = []) -> bool:
	if upgrade_level > next_tier_threshold:
		if _next_tier_nodes_l == []:
			next_tier_unlocked.emit(self._next_tier_nodes)
		else:
			next_tier_unlocked.emit(_next_tier_nodes_l)
		return true
	return false

func _to_string() -> String:
	return "ID: %s"%_id + "\nLevel: %s"%upgrade_level + "\nFiat Cost: %s"%upgrade_cost(Constants.CurrencyType.FIAT) + "\nBitcoin Cost: %s"%upgrade_cost(Constants.CurrencyType.BITCOIN)

#endregion
