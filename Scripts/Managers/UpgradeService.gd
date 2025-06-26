extends Node
class_name UpgradeService

@export var progress_event_bus: PlayerProgressEventBus
var current_currency: Currency.CurrencyType = Currency.CurrencyType.FIAT

func _ready() -> void:
        if progress_event_bus == null:
                progress_event_bus = preload("res://Resources/Upgrades/MainPlayerProgressEventBus.tres")

func can_afford(data: SkillNodeData, currency: Currency.CurrencyType = current_currency) -> bool:
        if data == null:
                return false
        var cost = data.upgrade_cost(currency)
        var balance = BitcoinWallet.get_bitcoin_balance() if currency == Currency.CurrencyType.BITCOIN else BitcoinWallet.get_fiat_balance()
        return balance >= cost

func purchase_upgrade(data: SkillNodeData, currency: Currency.CurrencyType = current_currency) -> bool:
        if data == null:
                return false
        if !can_afford(data, currency):
                return false
        if !data.buy_upgrade(currency):
                return false
        _emit_upgrade_event(data)
        return true

func _emit_upgrade_event(data: SkillNodeData) -> void:
        match data.feature_type:
                SkillNode.FEATURE_TYPE.WEAPON:
                        progress_event_bus.unlock_weapon(
                                Utils.weapon_name_to_string(data.weapon_data.weapon_type),
                                data.weapon_data.weapon_to_unlock
                        )
                SkillNode.FEATURE_TYPE.ABILITY:
                        progress_event_bus.unlock_ability(
                                Utils.ability_name_to_string(data.ability_data.ability_type),
                                data.ability_data.ability_to_unlock
                        )
                SkillNode.FEATURE_TYPE.STAT_UPGRADE:
                        progress_event_bus.upgrade_stat(
                                Utils.player_stat_type_to_string(data.stat_type),
                                data.get_current_power(),
                                data.is_percentage
                        )
                _:
                        pass

