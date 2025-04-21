extends Node2D

@export_category("Player")
## Used to easily modify/upgrade the values needed for the player like speed, health, etc.
@export var player_details: PlayerDetails
@export_category("Main Event Buses")
@export var main_skill_tree_event_bus: SkillTreeEventBus
@export var main_event_bus: MainEventBus

@export_category("Levels")
@export var game_levels: Array[LevelBuilderArgs]

var levels_unlocked: int = 1
var previous_levels_unlocked_index: int = 0
var _current_level: int = 0

var current_level_args: LevelBuilderArgs = null
var player: PlayerController = null
var pool_fracture_bullets: PoolFracture
var current_block_core: BlockCore
var current_quadrant_builder: QuadrantBuilder
var player_camera: AdvanceCamera

var loaded: bool = false

const NetworkDataSaveName: String = "network_data"
const WalletDataSaveName: String = "wallet_data"
const GameManagerSaveName: String = "save_not_nigga"

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _ready() -> void:
	# Set the level index for each level
	# This is used to identify the level in the game
	# and to unlock the next level when the current one is completed
	for i in range(game_levels.size()):
		game_levels[i].level_index = i

#region Public API
func complete_level(code: String = "") -> void:
	main_event_bus.level_completed.emit(MainEventBus.LevelCompletedArgs.new(code))
	if player_in_completed_level(): return
	
	levels_unlocked = clamp(levels_unlocked + 1, 1, game_levels.size())
	previous_levels_unlocked_index = levels_unlocked - 1

func emit_level_completed(code: String = "") -> void:
	main_event_bus.level_completed.emit(MainEventBus.LevelCompletedArgs.new(code))

func player_in_completed_level() -> bool:
	if levels_unlocked < previous_levels_unlocked_index:
		return true
	if _current_level < previous_levels_unlocked_index - 1: # Means the player is in an already completed level
		return true
	return false

func init_tween() -> Tween:
	return create_tween()

func init_timer(delay: float) -> SceneTreeTimer:
	return get_tree().create_timer(delay)

func shake_camera(amplitude: float, frequency: float, duration: float, axis_ratio: float, armonic_ratio: Array[int], phase_offset_degrees: int, samples: int, tween_trans: Tween.TransitionType) -> void:
	player_camera.shake(amplitude, frequency, duration, axis_ratio, armonic_ratio, phase_offset_degrees, samples, tween_trans)

#endregion

#region Commented Code
# Stays commented just in case it's needed in the future.
# I don't think that will be the case, but you never know.

# func add_weapon_details_to_dictionary(key: String, value: WeaponDetails) -> void:
# 	weapon_details_dictionary[key] = value
	
# func get_weapon_details_from_dictionary(key: String) -> WeaponDetails:
# 	if weapon_details_dictionary.has(key):
# 		return weapon_details_dictionary[key]
# 	else:
# 		return null

# func unlock_weapon(weapon_name: String) -> void:
# 	if unlocked_weapons.has(weapon_name):
# 		return
	
# 	var weapon_details: WeaponDetails = get_weapon_details_from_dictionary(weapon_name)
# 	if weapon_details:
# 		unlocked_weapons[weapon_name] = weapon_details
# 		player_details.add_weapon_to_array(weapon_details)
# 		# print("Weapon Unlocked: {0}".format([weapon_name]))
# 	# else:
# 	# 	printerr("NO WEAPON FOUND FOR {0} ON {1}".format([weapon_name, self.name]))

# func _on_stat_upgraded(event: SkillTreeEventBus.SkillTreeStatEvent) -> void:
# 	var stat_name = event.stat_name
# 	var stat_type = event.stat_type
# 	var upgrade_power = event.upgrade_power
# 	upgraded_stats[stat_name] = {"value": upgrade_power, "stat_type": stat_type}
# 	match stat_type:
# 		SkillNode.STAT_TYPE.SPEED:
# 			upgraded_stats[stat_name].value += upgrade_power
# 		SkillNode.STAT_TYPE.HEALTH:
# 			upgraded_stats[stat_name].value += upgrade_power
# 		SkillNode.STAT_TYPE.DAMAGE:
# 			upgraded_stats[stat_name].value += upgrade_power
# 		_:
# 			return

# func upgrade_stat(stat_name: String, value: float, stat_type: SkillNode.STAT_TYPE) -> void:
# 	upgraded_stats[stat_name] = {"value": value, "stat_type": stat_type}
# 	match stat_type:
# 		SkillNode.STAT_TYPE.SPEED:
# 			upgraded_stats[stat_name].value += value
# 		SkillNode.STAT_TYPE.HEALTH:
# 			upgraded_stats[stat_name].value += value
# 		SkillNode.STAT_TYPE.DAMAGE:
# 			upgraded_stats[stat_name].value += value
# 		_:
# 			return

# func get_upgraded_stat(stat_type: SkillNode.STAT_TYPE = SkillNode.STAT_TYPE.NONE) -> Dictionary:
# 	if upgraded_stats.size() == 0: return {
# 		"value": 0.0,
# 		"stat_type": 0
# 	}
# 	if upgraded_stats.has(Utils.player_stat_type_to_string(stat_type)):
# 		return upgraded_stats[Utils.player_stat_type_to_string(stat_type)]
# 	return {
# 		"value": 0.0,
# 		"stat_type": 0
# 	}

# func register_unlocked_ability(ability_id: String) -> void:
# 	if unlocked_abilities.has(ability_id): return
# 	unlocked_abilities[ability_id] = true

#endregion

#region Level Management
func _set_level_index(index: int) -> void:
	print("Setting Level Index: {0}".format([index]))
	_current_level = index

func get_level_index() -> int:
	return _current_level

func select_builder_args(index: int) -> void:
	current_level_args = game_levels[index]
	print("Selecting Builder Args: {0}. At index: {1}".format([current_level_args.debug_name, index]))

func get_level_args() -> LevelBuilderArgs:
	return current_level_args

func get_current_level() -> int:
	return get_level_args().level_index

#endregion

#region Persistence Data System
func save_data() -> void:
	SaveSystem.set_var(GameManagerSaveName, _build_dictionary_to_save())

func _build_dictionary_to_save() -> Dictionary:
	# var unlocked_weapons_keys: Array = unlocked_weapons.keys()
	return {
		"levels_unlocked": levels_unlocked,
		"previous_levels_unlocked_index": previous_levels_unlocked_index,
		# "unlocked_weapons": unlocked_weapons_keys,
		# "upgraded_stats": upgraded_stats,
		# "unlocked_abilities": unlocked_abilities
	}


func load_data() -> void:
	if loaded: return
	
	if !SaveSystem.has(GameManagerSaveName): return
	var data: Dictionary = SaveSystem.get_var(GameManagerSaveName)

	levels_unlocked = data["levels_unlocked"]
	previous_levels_unlocked_index = data["previous_levels_unlocked_index"]
	
	#region CC
	# _load_unlocked_weapons(data)
	# upgraded_stats = data["upgraded_stats"]
	# _apply_upgraded_stats()
	# _load_unlocked_abilities(data)
	#endregion
	loaded = true

#endregion

#region Commented Code
# Stays commented just in case it's needed in the future.
# func _load_unlocked_abilities(data: Dictionary) -> void:
# 	var unlocked_abilities_keys: Array = data["unlocked_abilities"].keys()
# 	for ability_id in unlocked_abilities_keys:
# 		register_unlocked_ability(ability_id)

# func _load_unlocked_weapons(data: Dictionary) -> void:
# 	var unlocked_weapons_keys: Array = data["unlocked_weapons"]
# 	for weapon_name in unlocked_weapons_keys:
# 		unlock_weapon(weapon_name)

# func _apply_upgraded_stats() -> void:
# 	for stat_name in upgraded_stats:
# 		var stat_info: Dictionary = upgraded_stats[stat_name]
# 		var value: float = stat_info["value"]
# 		var stat_int: int = stat_info["stat_type"]
# 		var stat_type: SkillNode.STAT_TYPE = _int_to_stat_type(stat_int)
		
# 		match stat_type:
# 			SkillNode.STAT_TYPE.SPEED:
# 				player_details.speed += value
# 				# print("Speed: {0}".format([player_details.speed]))
# 			SkillNode.STAT_TYPE.HEALTH:
# 				player_details.max_health += value
# 				# print("Max Health: {0}".format([player_details.max_health]))
# 			SkillNode.STAT_TYPE.DAMAGE:
# 				player_details.damage_multiplier += value
# 				# print("Damage Multiplier: {0}".format([player_details.damage_multiplier]))
# 			_:
# 				return
# 				# printerr("NO STAT FOUND FOR {0}".format([stat_name]))

# func _int_to_stat_type(value: int) -> SkillNode.STAT_TYPE:
# 	match value:
# 		0:
# 			return SkillNode.STAT_TYPE.NONE
# 		1:
# 			return SkillNode.STAT_TYPE.HEALTH
# 		2:
# 			return SkillNode.STAT_TYPE.SPEED
# 		3:
# 			return SkillNode.STAT_TYPE.DAMAGE
# 		_:
# 			return SkillNode.STAT_TYPE.NONE
#endregion
