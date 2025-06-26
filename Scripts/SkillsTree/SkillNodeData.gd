class_name SkillNodeData extends Resource

signal next_tier_unlocked()
signal upgrade_maxed()
signal upgrade_level_changed(new_level: int, max_level: int)

enum DataStatus {LOCKED = 0, UNLOCKED = 1, MAXED_OUT = 2}

## The type of stat to upgrade.
enum StatType {
	## Default state.
	NONE = 0,
	## Upgrades the player's health.
	HEALTH = 1,
	## Upgrades the player's speed.
	SPEED = 2,
	## Upgrades the player's damage multiplier.
	DAMAGE = 3}


@export_category("Upgrade Basic Parameters")
## Defines if this node should unlock a new weapon, player ability or simply upgrade a player stat.
@export var feature_type: SkillNode.FEATURE_TYPE = SkillNode.FEATURE_TYPE.NONE
@export var upgrade_name: String = ""
@export_multiline var upgrade_description: String = ""
@export var skill_image: Texture = Texture.new()
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

var next_tier_threshold: int = int(upgrade_max_level * 0.6) # 60% of max level
var upgrade_level: int = 0:
	set(value):
		if upgrade_level != value:
			upgrade_level = value
			upgrade_level_changed.emit(upgrade_level, upgrade_max_level)
			check_next_tier_unlock()
			check_upgrade_maxed_out()

var _id: int = 0
var status: DataStatus = DataStatus.LOCKED

#region Main

func buy_upgrade(currency_type: Constants.CurrencyType = Constants.CurrencyType.FIAT) -> bool:
        if upgrade_level >= upgrade_max_level: return false

        var success: bool = _buy_with_bitcoin() if currency_type == Constants.CurrencyType.BITCOIN else _buy_with_fiat()
        if success:
                check_next_tier_unlock()
                check_upgrade_maxed_out()
        return success

func set_id(id:int = 0) -> void:
	_id = id

func _buy_with_bitcoin() -> bool:
        if BitcoinWallet.spend_bitcoin(upgrade_cost(Constants.CurrencyType.BITCOIN)):
		upgrade_level = min(upgrade_level+1, upgrade_max_level)
		return true
	else:
		# print("Not enough Bitcoin balance: {0}".format([BitcoinWallet.get_bitcoin_balance()]))
		return false


func _buy_with_fiat() -> bool:
        if BitcoinWallet.spend_fiat(upgrade_cost(Constants.CurrencyType.FIAT)):
		upgrade_level = min(upgrade_level+1, upgrade_max_level)
		return true
	else:
		# print("Not enough fiat balance: {0}".format([BitcoinWallet.get_fiat_balance()]))
		return false

func buy_max(currency_type: Constants.CurrencyType = Constants.CurrencyType.FIAT) -> void:
        if upgrade_level >= upgrade_max_level: return

        if currency_type == Constants.CurrencyType.BITCOIN:
                BitcoinWallet.spend_bitcoin(_buy_max(currency_type))
        else:
                BitcoinWallet.spend_fiat(_buy_max(currency_type))
			# print("Not enough fiat balance: {0}".format([BitcoinWallet.get_fiat_balance()]))

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

func upgrade_cost(currency_type: Constants.CurrencyType = Constants.CurrencyType.FIAT) -> float:
        return _upgrade_cost_btc() if currency_type == Constants.CurrencyType.BITCOIN else _upgrade_cost_fiat()

func _upgrade_cost_fiat() -> float:
	var inflation_adjustment = 1.0 + FED.get_total_inflation()
	return upgrade_cost_base * pow(upgrade_cost_multiplier, upgrade_level) * inflation_adjustment

func _upgrade_cost_btc() -> float:
	var deflation_adjustment = 1.0 + BitcoinNetwork.get_total_deflation()
	return upgrade_cost_base_btc * pow(upgrade_cost_multiplier_btc, upgrade_level) / deflation_adjustment

func upgrade_cost_string() -> String:
	return str(_upgrade_cost_fiat())

func upgrade_cost_btc_string() -> String:
	return str(_upgrade_cost_btc())

#endregion

#region Power
func get_current_power() -> float:
	return upgrade_base_power * pow(upgrade_power_multiplier, upgrade_level)
#endregion

#region Other

func _log(value: float, base: float) -> float:
	return 2.302585 / log(base) * (log(value) / log(10))


func check_upgrade_maxed_out() -> bool:
	if upgrade_level == upgrade_max_level:
		if status != DataStatus.MAXED_OUT:
			upgrade_maxed.emit()
		status = DataStatus.MAXED_OUT
		upgrade_maxed.emit()
		return true
	return false

func check_next_tier_unlock() -> bool:
	if upgrade_level >= next_tier_threshold:
		if status != DataStatus.UNLOCKED:
			next_tier_unlocked.emit()
		status = DataStatus.UNLOCKED
		next_tier_unlocked.emit()
		return true
	return false

func _to_string() -> String:
        return "ID: %s"%_id + "\nLevel: %s"%upgrade_level + "\nFiat Cost: %s"%upgrade_cost(Constants.CurrencyType.FIAT) + "\nBitcoin Cost: %s"%upgrade_cost(Constants.CurrencyType.BITCOIN)

#endregion
