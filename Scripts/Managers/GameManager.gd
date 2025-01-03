extends Node2D

signal game_terminated()

@export_category("Player Resources")
## Used to easily modify/upgrade the values needed for the player like speed, health, etc.
@export var player_details: PlayerDetails

@export_category("Weapon Resource")
## This dictionary is used to store all the weapons available in the game.
@export var weapon_details_dictionary: Dictionary

@export_category("Stats Resource")
## This dictionary is used to store all the stats available in the game.
@export var base_stats_dictionary: Dictionary = {
	"speed": 400.0,
	"health": 300.0,
	"damage_mul": 1.0
}

var game_levels: Array = []
var levels_unlocked: int = 1
var previous_levels_unlocked_index: int = 1
var current_level: int = 0

var builder_args: QuadrantBuilderArgs
var player: PlayerController
var pool_fracture_bullets: PoolFracture
var current_block_core: BlockCore
var current_quadrant_builder: QuadrantBuilder
var unlocked_weapons: Dictionary = {}
var upgraded_stats: Dictionary = {}

var loaded: bool = false

const NetworkDataSaveName: String = "network_data"
const WalletDataSaveName: String = "wallet_data"
const GameManagerSaveName: String = "save_not_nigga"

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _ready() -> void:
	player_details.speed = base_stats_dictionary["speed"]
	player_details.max_health = base_stats_dictionary["health"]
	player_details.damage_multiplier = base_stats_dictionary["damage_mul"]


## ___________________________PUBLIC FUNCTIONS__________________________________________

func level_completed() -> void:
	if levels_unlocked < previous_levels_unlocked_index:
		return
	if current_level < previous_levels_unlocked_index: # Means the player is in an already completed level
		return
	
	levels_unlocked += 1
	previous_levels_unlocked_index = levels_unlocked-1

func add_weapon_details_to_dictionary(key: String, value: WeaponDetails) -> void:
	weapon_details_dictionary[key] = value
	
func get_weapon_details_from_dictionary(key: String) -> WeaponDetails:
	if weapon_details_dictionary.has(key):
		return weapon_details_dictionary[key]
	else:
		return null

func init_tween() -> Tween:
	return create_tween()

func init_timer(delay: float) -> SceneTreeTimer:
	return get_tree().create_timer(delay)

func unlock_weapon(weapon_name: String) -> void:
	if unlocked_weapons.has(weapon_name):
		return
	
	var weapon_details: WeaponDetails = get_weapon_details_from_dictionary(weapon_name)
	if weapon_details:
		unlocked_weapons[weapon_name] = weapon_details
		player_details.add_weapon_to_array(weapon_details)
		print("Weapon Unlocked: {0}".format([weapon_name]))
	else:
		printerr("NO WEAPON FOUND FOR {0} ON {1}".format([weapon_name, self.name]))


func upgrade_stat(stat_name: String, value: float, stat_type: SkillNode.STAT_TYPE) -> void:
	upgraded_stats[stat_name] = {"value": value, "stat_type": stat_type}
	match stat_type:
		SkillNode.STAT_TYPE.SPEED:
			#upgraded_stats[stat_name] = value
			player_details.speed += value
		SkillNode.STAT_TYPE.HEALTH:
			#upgraded_stats[stat_name] = value
			player_details.max_health += value
		SkillNode.STAT_TYPE.DAMAGE:
			#upgraded_stats[stat_name] = value
			player_details.damage_multiplier += value
		_:
			printerr("NO STAT FOUND FOR {0}".format([stat_name]))

## ___________________________PRIVATE FUNCTIONS______________________________________________



## ___________________________PERSISTENCE DATA FUNCTIONS_____________________________________

func save_data() -> void:
	SaveSystem.set_var(GameManagerSaveName, _build_dictionary_to_save())

func _build_dictionary_to_save() -> Dictionary:
	var unlocked_weapons_keys: Array = unlocked_weapons.keys()
	return {
		"levels_unlocked": levels_unlocked,
		"previous_levels_unlocked_index": previous_levels_unlocked_index,
		"current_level": current_level,
		# "player_speed": player_details.speed,
		# "player_health": player_details.max_health,
		# "player_damage_multiplier": player_details.damage_multiplier,
		"unlocked_weapons": unlocked_weapons_keys,
		"upgraded_stats": upgraded_stats
	}


func load_data() -> void:
	if loaded: return
	
	if !SaveSystem.has(GameManagerSaveName): return
	var data: Dictionary = SaveSystem.get_var(GameManagerSaveName)

	levels_unlocked = data["levels_unlocked"]
	previous_levels_unlocked_index = data["previous_levels_unlocked_index"]
	current_level = data["current_level"]
	# player_details.speed = data["player_speed"]
	# player_details.max_health = data["player_health"]
	# player_details.damage_multiplier = data["player_damage_multiplier"]

	_load_unlocked_weapons(data)
	
	if !data.has("upgraded_stats"): return

	upgraded_stats = data["upgraded_stats"]
	_apply_upgraded_stats()
	loaded = true

func _load_unlocked_weapons(data: Dictionary) -> void:
	var unlocked_weapons_keys: Array = data["unlocked_weapons"]
	for weapon_name in unlocked_weapons_keys:
		unlock_weapon(weapon_name)

func _apply_upgraded_stats() -> void:
	for stat_name in upgraded_stats.keys():
		var stat_info: Dictionary = upgraded_stats[stat_name]
		var value: float = stat_info["value"]
		var stat_int: int = stat_info["stat_type"]
		var stat_type: SkillNode.STAT_TYPE = _int_to_stat_type(stat_int)
		match stat_type:
			SkillNode.STAT_TYPE.SPEED:
				player_details.speed += value
				print("Speed: {0}".format([player_details.speed]))
			SkillNode.STAT_TYPE.HEALTH:
				player_details.max_health += value
				print("Max Health: {0}".format([player_details.max_health]))
			SkillNode.STAT_TYPE.DAMAGE:
				player_details.damage_multiplier += value
				print("Damage Multiplier: {0}".format([player_details.damage_multiplier]))
			_:
				printerr("NO STAT FOUND FOR {0}".format([stat_name]))

func _int_to_stat_type(value: int) -> SkillNode.STAT_TYPE:
	match value:
		0:
			return SkillNode.STAT_TYPE.NONE
		1:
			return SkillNode.STAT_TYPE.HEALTH
		2:
			return SkillNode.STAT_TYPE.SPEED
		3:
			return SkillNode.STAT_TYPE.DAMAGE
		_:
			return SkillNode.STAT_TYPE.NONE
