class_name Utils extends Node
## Utility functions for the game.
## 
## This class provides various utility functions for the game, including:
## - Converting enums to strings and vice versa
## - Formatting currency
## - Creating resource instances from dictionaries
## - Copying properties between nodes
## - Handling player stats and abilities

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
	var res = target_resource.new()
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

static func _enum_name(enum_dict: Dictionary, value: int) -> String:
	var values = enum_dict.values()
	var idx = values.find(value)
	if idx == -1:
			return "UNKNOWN"
	return str(enum_dict.keys()[idx])

## Formats an enum value into a user friendly string.
static func enum_label(enum_dict: Dictionary, value: int) -> String:
	var e_name = _enum_name(enum_dict, value)
	var parts = e_name.to_lower().split("_")
	for i in range(parts.size()):
			parts[i] = parts[i].capitalize()
	return " ".join(parts)

## Converts a formatted enum label back to its enum value
## This is the reverse of [method Utils.enum_label()]
static func label_to_enum(label: String, enum_dict: Dictionary) -> int:
	for enum_key in enum_dict.keys():
		if Utils.enum_label(enum_dict, enum_dict[enum_key]) == label:
			return enum_dict[enum_key]
	return -1

## Converts the [param Constants.WeaponNames] enum to a string.[br]
## This is useful for displaying the weapon name in the UI or for debugging purposes.
## It uses the [method enum_label] function to get a user-friendly string representation of the enum value.[br]
#### Example:
## [codeblock]
## var weapon_name: String = Utils.weapon_name_to_string(Constants.WeaponNames.RIFLE)
## print(weapon_name) # Output: "Rifle"
## [/codeblock]
## [param weapon_name]: The [enum Constants.WeaponNames] enum value to convert.
## [return]: A user-friendly string representation of the weapon name.[br]
## See [method enum_label].
## See: [Constants.WeaponNames].
## See: [Constants.WeaponNames.RIFLE].[br]
## Returns the raw enum name for a given enum value.
static func weapon_name_to_string(weapon_name: Constants.WeaponNames) -> String:
	return enum_label(Constants.WeaponNames, weapon_name)

# static func weapon_string_to_weapon_enum(weapon_name: String) -> Constants.WeaponNames:
# 	var weapon_names: Dictionary = {
# 		"Rifle": Constants.WeaponNames.RIFLE,
# 		"Shotgun": Constants.WeaponNames.SHOTGUN,
# 		"AWP Sniper": Constants.WeaponNames.SNIPER,
# 		"Pistol": Constants.WeaponNames.PISTOL,
# 		"AK-47": Constants.WeaponNames.AK47,
# 		"Machine Gun": Constants.WeaponNames.MACHINE_GUN,
# 		"Rocket Launcher": Constants.WeaponNames.ROCKET_LAUNCHER,
# 		"Flamethrower": Constants.WeaponNames.FLAMETHROWER,
# 		"Minigun": Constants.WeaponNames.MINIGUN,
# 		"Bow": Constants.WeaponNames.BOW,
# 		"Crossbow": Constants.WeaponNames.CROSSBOW,
# 		"Grenade Launcher": Constants.WeaponNames.GRENADE_LAUNCHER,
# 		"SlingShot": Constants.WeaponNames.SLINGSHOT,
# 		"Sword": Constants.WeaponNames.SWORD,
# 		"Axe": Constants.WeaponNames.AXE,
# 		"Spear": Constants.WeaponNames.SPEAR,
# 		"Whip": Constants.WeaponNames.WHIP,
# 		"Cannon": Constants.WeaponNames.CANNON,
# 		"Bazooka": Constants.WeaponNames.BAZOOKA,
# 		"Laser": Constants.WeaponNames.LASER,
# 		"Railgun": Constants.WeaponNames.RAILGUN,
# 		"Plasma": Constants.WeaponNames.PLASMA,
# 		"Raygun": Constants.WeaponNames.RAYGUN,
# 		"Mini Uzi": Constants.WeaponNames.MINI_UZI,
# 	}

# 	if weapon_names.has(weapon_name):
# 			return weapon_names[weapon_name]
# 	return Constants.WeaponNames.NONE


## Converts the [enum Constants.AbilityNames] enum to a string.[br]
## This is useful for displaying the ability name in the UI or for debugging purposes.
## It uses the [method enum_label] function to get a user-friendly string representation of the enum value.[br]
#### Example:[br]
## [codeblock]
## var ability_name: String = Utils.ability_name_to_string(Constants.AbilityNames.MAGNET)
## print(ability_name) # Output: "Magnet"
## [/codeblock]
## [param ability_name]: The [enum Constants.AbilityNames] enum value to convert.
## Return A user-friendly string representation of the ability name.
## See: [method enum_label].
## See: [Constants.AbilityNames].
## See: [Constants.AbilityNames.MAGNET].
static func ability_name_to_string(ability_name: int) -> String:
	return enum_label(Constants.AbilityNames, ability_name)


## Converts the [enum UpgradeData.StatType] enum to a string.
## This is useful for displaying the stat type in the UI or for debugging purposes.
## It uses the [func Utils.enum_label] function to get a user-friendly string representation of the enum value.[br]
#### Example:
## [codeblock]
## var stat_type_name: String = Utils.player_stat_type_to_string(UpgradeData.StatType.HEALTH)
## print(stat_type_name) # Output: "Health"
## [/codeblock]
## [param stat_type]: The [enum UpgradeData.StatType] enum value to convert.[br]
## Return A user-friendly string representation of the stat type.[br]
## See [method enum_label].
## See [enum UpgradeData.StatType].
## See [enum UpgradeData.StatType.HEALTH].
static func player_stat_type_to_string(stat_type: UpgradeData.StatType) -> String:
	return enum_label(UpgradeData.StatType, stat_type)

static func int_to_skill_node_state(state: int) -> SkillNode.NodeState:
	match state:
		0: return SkillNode.NodeState.LOCKED
		1: return SkillNode.NodeState.CAN_AFFORD
		2: return SkillNode.NodeState.CANNOT_AFFORD
		3: return SkillNode.NodeState.MAXED_OUT
		_: return SkillNode.NodeState.UNKNOWN


## @deprecated: Use [method enum_label] instead.
## Converts an enum value to its string name.
static func enum_to_string(_enum: int, enum_type: Dictionary) -> String:
	for key in enum_type.keys():
			if enum_type[key] == _enum:
					return key
	return "Unknown Enum"

static func string_to_enum(s_name: String, enum_type: Dictionary) -> int:
	if enum_type.has(s_name):
			return enum_type[s_name]
	return -1

static func return_currency_suffix(amount: float) -> String:
	if amount < 1000.0:
		return ""
	
	var suffixes: Array = ["K", "M", "B", "T", "Q", "QQ", "S", "SS", "O", "N", "D", "UN", "DD", "TD", "QD", "QQD", "SD", "SSD", "OD", "ND"]
	var suffix_index: int = 0

	while amount >= 1000 and suffix_index < suffixes.size():
		amount /= 1000
		suffix_index += 1
	
	return suffixes[suffix_index - 1] if suffix_index > 0 else ""

static func format_currency(amount: float, use_short_format: bool = false) -> String:
	if use_short_format:
		return format_short_currency(amount)
	return format_full_currency(amount)

static func format_full_currency(amount: float) -> String:
	# Convert to integer if it's a whole number
	if amount == floor(amount):
		amount = int(amount)
	
	var str_amount = str(amount)
	var parts = str_amount.split(".", false, 1)
	var int_part = parts[0]
	var formatted = ""
	var count = 0
	
	# Format the integer part with commas
	for i in range(int_part.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "," + formatted
		formatted = int_part[i] + formatted
		count += 1

	if parts.size() > 1:
		formatted += "." + parts[1]

	return formatted

static func format_short_currency(amount: float) -> String:
	if amount < 1000.0:
		return format_full_currency(amount)
	
	var suffixes: Array = ["K", "M", "B", "T", "Q", "QQ", "S", "SS", "O", "N", "D", "UN", "DD", "TD", "QD", "QQD", "SD", "SSD", "OD", "ND"]
	var suffix_index: int = 0

	while amount >= 1000 and suffix_index < suffixes.size():
		amount /= 1000
		suffix_index += 1
	
	# Round to 1 decimal place
	var rounded: float = round(amount * 10) / 10
	var num_str = str(rounded)
	if num_str.ends_with(".0"):
		num_str = num_str.substr(0, num_str.length() - 2)
	
	return "%s%s" % [num_str, suffixes[suffix_index-1]]
