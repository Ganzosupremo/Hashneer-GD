class_name Utils extends Node

static func build_res_from_dictionary(data: Dictionary, type: Resource) -> Resource:
	var res = type
	for key in data.keys():
		var value = data[key]
		if typeof(value) == TYPE_DICTIONARY:
			var sub_res = build_res_from_dictionary(value, type)
			if res is Resource and res.has_method("set"):
				res.set(key, sub_res)
		elif typeof(value) == TYPE_ARRAY:
			var array_res = []
			for item in value:
				if typeof(item) == TYPE_DICTIONARY:
					array_res.append(build_res_from_dictionary(item, type))
				else:
					if res is Resource and res.has_method("set"):
						res.set(key, array_res)
		else:
			if res.has_method("set"):
				res.set(key, value)
	return res

static func dict_to_resource(dict : Dictionary, target_resource : Resource, debug: bool = false) -> Resource:
	var res = target_resource
	for i in range(dict.size()):
		var key = dict.keys()[i]
		var value = dict.values()[i]
		if debug:
			print("Processing key: ", key, " with value: ", value)
		if typeof(value) == TYPE_DICTIONARY:
			if debug:
				Debugger.print("Found dictionary for {0} at key: {1}".format([value, key]))
			var sub_res = dict_to_resource(value, target_resource)
			res.set(key, sub_res)
		else:
			if debug:
				print("Setting key: ", key, " with value: ", value)
			res.set(key, value)
	return res

"""Sets the properties of the TweenableButton automatically to the child AnimationComponent.
I'm lazy to do it manually."""
static func copy_properties(parent: Node, child: Node) -> void:
	if parent.has_method("get_properties") and child.has_method("set_properties"):
		var parent_properties = parent.call("get_properties")
		child.call("set_properties", parent_properties)
	
static func weapon_name_to_string(weapon_name: Constants.WeaponNames) -> String:
	var weapon_names_to_string = {
		Constants.WeaponNames.PISTOL: "Pistol",
		Constants.WeaponNames.SHOTGUN: "Shotgun",
		Constants.WeaponNames.RIFLE: "Rifle",
		Constants.WeaponNames.SNIPER: "Sniper",
		Constants.WeaponNames.AK47: "AK47",
		Constants.WeaponNames.MACHINE_GUN: "Machine Gun",
		Constants.WeaponNames.ROCKET_LAUNCHER: "Rocket Launcher",
		Constants.WeaponNames.GRENADE_LAUNCHER: "Grenade Launcher",
		Constants.WeaponNames.FLAMETHROWER: "Flamethrower",
		Constants.WeaponNames.LASER: "Laser",
		Constants.WeaponNames.RAILGUN: "Railgun",
		Constants.WeaponNames.PLASMA: "Plasma",
		Constants.WeaponNames.RAYGUN: "Raygun",
		Constants.WeaponNames.BAZOOKA: "Bazooka",
		Constants.WeaponNames.CANNON: "Cannon",
		Constants.WeaponNames.BFG: "BFG",
		Constants.WeaponNames.MINIGUN: "Minigun",
		Constants.WeaponNames.CHAINSAW: "Chainsaw",
		Constants.WeaponNames.SWORD: "Sword",
		Constants.WeaponNames.AXE: "Axe",
		Constants.WeaponNames.HAMMER: "Hammer",
		Constants.WeaponNames.MACE: "Mace",
		Constants.WeaponNames.SPEAR: "Spear",
		Constants.WeaponNames.BOW: "Bow",
		Constants.WeaponNames.CROSSBOW: "Crossbow",
		Constants.WeaponNames.SHURIKEN: "Shuriken",
		Constants.WeaponNames.KUNAI: "Kunai",
		Constants.WeaponNames.NINJA_STAR: "Ninja Star"
	}
	
	if weapon_names_to_string.has(weapon_name):
		return weapon_names_to_string[weapon_name]
	return "Unknown Weapon"

## The GameManager saves the upgrade data in the [param GameManager.upgraded_stats] dictionary based on the [param SkillNode.stat_type] variable.
## This function converts the [param SkillNode.stat_type] to a string for getting the correct stat's value from the dictionary.
## To avoid typos when trying to recover a stat's value from the dictionay, this function should be used.
## Just the player stats are saved in the dictionary. 
## The weapon and ability upgrades are saved in the [param GameManager.unlocked_weapons] and [param GameManager.unlocked_abilities] dictionaries.
static func player_stat_type_to_string(stat_type: SkillNode.STAT_TYPE) -> String:
	var saved_names: Dictionary = {
		SkillNode.STAT_TYPE.HEALTH: "Health",
		SkillNode.STAT_TYPE.SPEED: "Speed",
		SkillNode.STAT_TYPE.DAMAGE: "Damage",
	}

	if saved_names.has(stat_type):
		return saved_names[stat_type]
	return "Unknown Stat"


static func enum_to_string(_enum: int, enum_type: Dictionary) -> String:
	for key in enum_type.keys():
		if enum_type[key] == _enum:
			return key
	return "Unknown Enum"

static func format_currency(amount: float, use_short_format: bool = false) -> String:
	if use_short_format:
		return format_short_currency(amount)
	return format_full_currency(amount)

static func format_full_currency(amount: float) -> String:
	var str_amount = str(amount)
	var formatted = ""
	var count = 0
	
	# Work from right to left
	for i in range(str_amount.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "," + formatted
		formatted = str_amount[i] + formatted
		count += 1
	
	return formatted

static func format_short_currency(amount: float) -> String:
	if amount < 1000.0:
		return format_full_currency(amount)
	
	var suffixes: Array = ["K", "M", "B", "T", "Q", "QQ", "S", "SS", "O", "N", "D", "UN", "DD", "TD", "QD", "QQD", "SD", "SSD", "OD", "ND"]
	var suffix_index: int = 0

	while amount >= 1000 and suffix_index < suffixes.size() - 1:
		amount /= 1000
		suffix_index += 1
	
	# Round to 1 decimal place
	var rounded: float = round(amount * 10) / 10
	return "%s%s" % [str(rounded).trim_suffix(".0"), suffixes[suffix_index-1]]
