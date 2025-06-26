extends Node
class_name UpgradeService

@export var progress_event_bus: PlayerProgressEventBus

func _ready() -> void:
        if progress_event_bus == null:
                progress_event_bus = preload("res://Resources/Upgrades/MainPlayerProgressEventBus.tres")

func can_afford(data: SkillNodeData, use_bitcoin: bool = false) -> bool:
        if data == null:
                return false
        var cost = data.upgrade_cost(use_bitcoin)
        var balance = BitcoinWallet.get_bitcoin_balance() if use_bitcoin else BitcoinWallet.get_fiat_balance()
        return balance >= cost

func purchase_upgrade(data: SkillNodeData, use_bitcoin: bool = false) -> bool:
        if data == null:
                return false
        if !can_afford(data, use_bitcoin):
                return false
        if !data.buy_upgrade(use_bitcoin):
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

