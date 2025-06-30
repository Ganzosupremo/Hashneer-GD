class_name PlayerProgressEventBus extends Resource

signal stat_upgraded(event: StatUpgradeEvent)

signal weapon_unlocked(event: WeaponUnlockEvent)

signal ability_unlocked(event: AbilityUnlockEvent)


func upgrade_stat(_stat_type: UpgradeData.StatType, _upgrade_power: float, _is_percentage) -> void:
    var event = StatUpgradeEvent.new(_stat_type, _upgrade_power, _is_percentage)
    print("PlayerProgressEventBus: Upgrading stat: {0}. Stat power: {1}".format([_stat_type, _upgrade_power]))
    stat_upgraded.emit(event)

func unlock_weapon(_weapon_id: Constants.WeaponNames, _weapon_resource: WeaponDetails) -> void:
    var event = WeaponUnlockEvent.new(_weapon_id, _weapon_resource)
    print("PlayerProgressEventBus: Unlocking weapon: {0}.".format([_weapon_id]))
    weapon_unlocked.emit(event)

func unlock_ability(_ability_id: Constants.AbilityNames, _ability_scene: PackedScene) -> void:
    var event = AbilityUnlockEvent.new(_ability_id, _ability_scene)
    print("PlayerProgressEventBus: Unlocking Ability: {0}".format([_ability_id]))
    ability_unlocked.emit(event)


class StatUpgradeEvent:
    extends Object

    var stat_type: UpgradeData.StatType = UpgradeData.StatType.NONE
    var upgrade_power: float = 0.0
    var is_percentage: bool = false

    func _init(_stat_type: UpgradeData.StatType, _upgrade_power: float, _is_percentage: bool = false) -> void:
        stat_type = _stat_type
        upgrade_power = _upgrade_power
        is_percentage = _is_percentage

class WeaponUnlockEvent:
    extends Object

    var weapon_id: Constants.WeaponNames = Constants.WeaponNames.NONE
    var weapon_resource: WeaponDetails = null

    func _init(_weapon_id: Constants.WeaponNames, _weapon_resource: WeaponDetails) -> void:
        weapon_id = _weapon_id
        weapon_resource = _weapon_resource


class AbilityUnlockEvent:
    extends Object

    var ability_id: Constants.AbilityNames = Constants.AbilityNames.NONE
    var ability_scene: PackedScene = null

    func _init(_ability_id: Constants.AbilityNames, _ability_scene: PackedScene) -> void:
        ability_id = _ability_id
        ability_scene = _ability_scene
