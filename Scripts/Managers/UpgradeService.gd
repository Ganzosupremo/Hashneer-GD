extends Node

@export var progress_event_bus: PlayerProgressEventBus
@export var main_event_bus: MainEventBus
var current_currency: Constants.CurrencyType = Constants.CurrencyType.FIAT

func _ready() -> void:
	if progress_event_bus == null:
		progress_event_bus = preload("res://Resources/Upgrades/MainPlayerProgressEventBus.tres")
	if main_event_bus == null:
		main_event_bus = preload("res://Resources/MainEventBus.tres")
	main_event_bus.currency_changed.connect(_on_currency_changed)

func _on_currency_changed(new_currency: Constants.CurrencyType) -> void:
	current_currency = new_currency
	print("UpgradeService: Currency changed to {0}".format([current_currency]))

func can_afford(data: UpgradeData, currency: Constants.CurrencyType = current_currency) -> bool:
	if data == null:
		return false
	var cost = data.upgrade_cost(currency)
	var balance = BitcoinWallet.get_bitcoin_balance() if currency == Constants.CurrencyType.BITCOIN else BitcoinWallet.get_fiat_balance()
	return balance >= cost

func purchase_upgrade(data: UpgradeData) -> bool:
	if data == null:
		return false
	if !can_afford(data, current_currency):
		return false
	if !data.buy_upgrade(current_currency):
		return false
	_emit_upgrade_event(data)
	return true

func _emit_upgrade_event(data: UpgradeData) -> void:
	match data.feature_type:
		UpgradeData.PlayerFeatureType.WEAPON:
			progress_event_bus.unlock_weapon(
				Utils.weapon_name_to_string(data.weapon_data.weapon_type),
				data.weapon_data.weapon_to_unlock
			)
		UpgradeData.PlayerFeatureType.ABILITY:
			progress_event_bus.unlock_ability(
				Utils.ability_name_to_string(data.ability_data.ability_type),
				data.ability_data.ability_to_unlock
			)
		UpgradeData.PlayerFeatureType.STAT_UPGRADE:
			progress_event_bus.upgrade_stat(
				Utils.player_stat_type_to_string(data.stat_type),
				data.get_current_power(),
				data.is_percentage
			)
		_:
			pass
