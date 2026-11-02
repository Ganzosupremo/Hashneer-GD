class_name UnlockWeaponSkillEffect extends SkillEffect
## Gives the player a weapon. It also shows up in the Armory once the skill has a level.

@export var weapon: WeaponDetails


func apply(loadout: PlayerLoadout, _level: int) -> void:
	if weapon:
		loadout.add_weapon(weapon)

func describe(_level: int) -> String:
	if weapon == null:
		return ""
	var weapon_name: String = weapon.weapon_name if weapon.weapon_name != "" else weapon.resource_path.get_file().get_basename().capitalize()
	return "Unlocks the %s" % weapon_name

func is_level_independent() -> bool:
	return true
