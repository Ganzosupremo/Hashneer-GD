extends Node2D
## Player base stats and the Armory levels.
##
## Skill bonuses, weapons and abilities come from [SkillProgress], they are worked out from the
## skill levels for the mode being played, see [method get_loadout].

## Base stats for the player, skills add to them, see [StatSkillEffect].
var base_stats: Dictionary = {
	"Speed": 150.0,
	"Health": 300.0,
	"Damage": 1.0
}

## Armory upgrade levels bought, by item id (weapon or ammo) and upgrade type.
var armory_levels: Dictionary = {}

const SAVE_NAME: String = "player_stats"
const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

#region Skills

## What the bought skills give in [param mode] (a [enum Constants.GameModeFlag], 0 for every mode).
func get_loadout(mode: int = 0) -> PlayerLoadout:
	return SkillProgress.build_loadout(mode)

## Final value of [param stat_name] with the skills of [param mode].
func get_stat_final_value(stat_name: String, mode: int = 0) -> float:
	return get_loadout(mode).get_stat(stat_name, base_stats.get(stat_name, 0.0))

## Weapons unlocked by skills in any mode, used by the Armory.
func get_unlocked_weapons() -> Array[WeaponDetails]:
	return get_loadout(0).weapons

#endregion

#region Armory

## Returns the armory level of an upgrade for a weapon or ammo item.
func get_armory_level(item_id: String, upgrade_type: Constants.ArmoryUpgradeType) -> int:
	return int(armory_levels.get(item_id, {}).get(str(upgrade_type), 0))

## Stores the armory level of an upgrade, it is saved with the player stats.
func set_armory_level(item_id: String, upgrade_type: Constants.ArmoryUpgradeType, level: int) -> void:
	if !armory_levels.has(item_id):
		armory_levels[item_id] = {}
	armory_levels[item_id][str(upgrade_type)] = level

## Applies the saved armory levels to the weapon and ammo resources, which only keep them in memory.
func _apply_armory_levels() -> void:
	for weapon in SkillProgress.get_all_weapons():
		_apply_armory_levels_to(weapon)
		if weapon.get_ammo_details():
			_apply_armory_levels_to(weapon.get_ammo_details())

func _apply_armory_levels_to(item: IUpgradeable) -> void:
	for upgrade in item.get_available_upgrades():
		var level: int = get_armory_level(item.get_upgrade_id(), upgrade.upgrade_type)
		item.apply_upgrade(upgrade.upgrade_type, level, upgrade.upgrade_power_per_level)

#endregion

## Removes every armory upgrade bought, for a new epoch. Skills are reset by [method SkillProgress.reset_all].
func reset_for_new_epoch() -> void:
	armory_levels.clear()
	_apply_armory_levels()
	# The loadout refills itself with whatever gets unlocked again
	Equipment.reset()

func save_data() -> void:
	SaveSystem.set_var(SAVE_NAME, {
		"armory_levels": armory_levels,
	})

## Older saves also kept summed stat bonuses and unlocked weapons and abilities here,
## they are ignored now: [SkillProgress] works them out from the skill levels.
func load_data() -> void:
	if !SaveSystem.has(SAVE_NAME): return
	var data: Dictionary = SaveSystem.get_var(SAVE_NAME)
	armory_levels = data.get("armory_levels", {})
	_apply_armory_levels()
