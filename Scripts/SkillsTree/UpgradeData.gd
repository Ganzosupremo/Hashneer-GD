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

## The current level of the upgrade. This is used to determine the current power of the upgrade.
var upgrade_level: int = 0:
	set(value):
		if upgrade_level != value:
			upgrade_level = value
			upgrade_level_changed.emit(upgrade_level, upgrade_max_level)
			check_next_tier_unlock()
			check_upgrade_maxed_out()

## Cost multipliers set by the active economic event, 1.0 when there is none
var _event_cost_multiplier_fiat: float = 1.0
var _event_cost_multiplier_btc: float = 1.0

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

## Buys as many levels as the current balance allows in the specified currency type.
## Each level goes through [UpgradeService] so stat bonuses, weapons and abilities are applied.
## Returns the number of levels bought.
func buy_max(currency_type: Constants.CurrencyType = Constants.CurrencyType.FIAT) -> int:
	var bought: int = 0
	while upgrade_level < upgrade_max_level and UpgradeService.purchase_upgrade(self, currency_type):
		bought += 1
	return bought

#endregion

#region Cost

## Applies a random economic event to this upgrade.
## The event sets a cost multiplier per currency, the base costs of the resource are never changed,
## so applying the same event again (e.g. when the save is loaded) doesn't stack.
## The event will not apply if the upgrade is already maxed out or if the event is null.
func apply_random_economic_event(_economic_event: EconomicEvent) -> void:
	if !_economic_event or upgrade_level >= upgrade_max_level:
		return

	var multiplier: float = 1.0 + _economic_event.impact if _raises_prices(_economic_event) else max(1.0 - _economic_event.impact, 0.01)
	var currency: Constants.CurrencyType = _economic_event.currency_affected
	# Natural disasters hit both currencies
	if _economic_event.event_type == EconomicEvent.EventType.NATURAL_DISASTER:
		currency = Constants.CurrencyType.BOTH

	_event_cost_multiplier_fiat = multiplier if currency != Constants.CurrencyType.BITCOIN else 1.0
	_event_cost_multiplier_btc = multiplier if currency != Constants.CurrencyType.FIAT else 1.0
	update_ui.emit()  # Emit signal to update UI after applying the economic event

## Reverts all economic event effects, so costs go back to their normal values.
## This should be called when an economic event expires.
func revert_economic_event_effects() -> void:
	_event_cost_multiplier_fiat = 1.0
	_event_cost_multiplier_btc = 1.0
	update_ui.emit()  # Emit signal to update UI after reverting

## Returns [code]true[/code] if the event makes upgrades more expensive.
func _raises_prices(_economic_event: EconomicEvent) -> bool:
	match _economic_event.event_type:
		EconomicEvent.EventType.DEFLATION, EconomicEvent.EventType.MARKET_BOOM, EconomicEvent.EventType.TECHNOLOGY_ADVANCEMENT:
			return false
	return true

## Returns the cost of the upgrade in the specified currency type.
## If no currency type is specified, it defaults to fiat.
## The cost is calculated based on the upgrade level and the inflation/deflation adjustments.
func upgrade_cost(currency_type: Constants.CurrencyType = Constants.CurrencyType.FIAT) -> float:
	return _upgrade_cost_btc() if currency_type == Constants.CurrencyType.BITCOIN else _upgrade_cost_fiat()

func _upgrade_cost_fiat() -> float:
	var inflation_adjustment = FED.get_total_inflation()
	return upgrade_cost_base * pow(upgrade_cost_multiplier, upgrade_level) * inflation_adjustment * _event_cost_multiplier_fiat

func _upgrade_cost_btc() -> float:
	var deflation_adjustment = BitcoinNetwork.get_deflation_multiplier()
	return upgrade_cost_base_btc * pow(upgrade_cost_multiplier_btc, upgrade_level) * deflation_adjustment * _event_cost_multiplier_btc

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

func get_upgrade_cost_base() -> float:
	return upgrade_cost_base

func get_upgrade_cost_base_btc() -> float:
	return upgrade_cost_base_btc

func set_upgrade_cost_base(value: float) -> void:
	upgrade_cost_base = value

func set_upgrade_cost_base_btc(value: float) -> void:
	upgrade_cost_base_btc = value


#region Other

## The threshold for the next tier of the upgrade, 60% of the max level.
## Computed on demand because [member upgrade_max_level] is only set after the resource is created.
func get_next_tier_threshold() -> int:
	return int(upgrade_max_level * 0.6)

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
	if upgrade_level > get_next_tier_threshold():
		if _next_tier_nodes_l == []:
			next_tier_unlocked.emit(self._next_tier_nodes)
		else:
			next_tier_unlocked.emit(_next_tier_nodes_l)
		return true
	return false

func _to_string() -> String:
	return "ID: %s"%_id + "\nLevel: %s"%upgrade_level + "\nFiat Cost: %s"%upgrade_cost(Constants.CurrencyType.FIAT) + "\nBitcoin Cost: %s"%upgrade_cost(Constants.CurrencyType.BITCOIN)

#endregion
