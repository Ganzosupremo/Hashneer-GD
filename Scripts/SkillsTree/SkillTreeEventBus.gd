class_name SkillTreeEventBus extends Resource

signal stat_upgraded(event: SkillTreeStatEvent)

signal weapon_unlocked(event: SkillTreeWeaponEvent)

signal ability_unlocked(event: SkillTreeAbilityEvent)


func upgrade_stat(_stat_name: String, _upgrade_power: float, _is_percentage) -> void:
    var event = SkillTreeStatEvent.new(_stat_name, _upgrade_power, _is_percentage)
    print("SkillTreeEventBus: Upgrading stat: {0}. Stat power: {1}".format([_stat_name, _upgrade_power]))
    stat_upgraded.emit(event)

func unlock_weapon(_weapon_id: String, _weapon_resource: WeaponDetails) -> void:
    var event = SkillTreeWeaponEvent.new(_weapon_id, _weapon_resource)
    print("SkillTreeEventBus: Unlocking weapon: {0}.".format([_weapon_id]))
    weapon_unlocked.emit(event)

func unlock_ability(_ability_id: String, _ability_scene: PackedScene) -> void:
    var event = SkillTreeAbilityEvent.new(_ability_id, _ability_scene)
    print("SkillTreeEventBus: Unlocking Ability: {0}".format([_ability_id]))
    ability_unlocked.emit(event)


class SkillTreeStatEvent:
    extends Object

    var stat_name: String = ""
    var upgrade_power: float = 0.0
    var is_percentage: bool = false

    func _init(_stat_name: String, _upgrade_power: float, _is_percentage: bool = false) -> void:
        stat_name = _stat_name
        upgrade_power = _upgrade_power
        is_percentage = _is_percentage

class SkillTreeWeaponEvent:
    extends Object

    var weapon_id: String = ""
    var weapon_resource: WeaponDetails = null

    func _init(_weapon_id: String, _weapon_resource: WeaponDetails) -> void:
        weapon_id = _weapon_id
        weapon_resource = _weapon_resource


class SkillTreeAbilityEvent:
    extends Object

    var ability_id: String = ""
    var ability_scene: PackedScene = null

    func _init(_ability_id: String, _ability_scene: PackedScene) -> void:
        ability_id = _ability_id
        ability_scene = _ability_scene