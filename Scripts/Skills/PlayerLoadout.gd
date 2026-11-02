class_name PlayerLoadout extends RefCounted
## What the skills give the player in one game mode: stat bonuses, weapons and abilities.
##
## Built from scratch by [method SkillProgress.build_loadout], nothing here is saved.

## Mode it was built for, a [enum Constants.GameModeFlag] or 0 for every mode.
var mode: int = 0
var flat_bonuses: Dictionary = {}
## Decimals, 0.1 is +10%.
var percent_bonuses: Dictionary = {}
var weapons: Array[WeaponDetails] = []
var abilities: Array[PackedScene] = []


func _init(_mode: int = 0) -> void:
	mode = _mode

func add_stat(stat: String, value: float, is_percentage: bool = false) -> void:
	var bonuses: Dictionary = percent_bonuses if is_percentage else flat_bonuses
	bonuses[stat] = bonuses.get(stat, 0.0) + value

func add_weapon(weapon: WeaponDetails) -> void:
	if weapon and not weapons.has(weapon):
		weapons.append(weapon)

func add_ability(scene: PackedScene) -> void:
	if scene and not abilities.has(scene):
		abilities.append(scene)

## Final value of [param stat]: [code](base + flat bonuses) * (1 + percent bonuses)[/code].
func get_stat(stat: String, base_value: float) -> float:
	return (base_value + flat_bonuses.get(stat, 0.0)) * (1.0 + percent_bonuses.get(stat, 0.0))
