extends Node2D

@export_category("Player Resources")
## Used to easily modify/upgrade the values needed for the player like speed, health, etc.
@export var player_details: PlayerDetails

@export_category("Weapon Resources")
## Just in case something needs to access the different weapon details
@export var weapon_details_dictionary: Dictionary

var game_levels: Array = []
var levels_unlocked: int = 1
var previous_levels_unlocked_index: int = 1
var current_level: int = 0

var builder_args: QuadrantBuilderArgs
var player: PlayerController
var pool_fracture_bullets: PoolFracture
var current_block_core: BlockCore
var current_quadrant_builder: QuadrantBuilder
var game_data_to_save: GameData
var game_data_resources_dictionary: Dictionary = {}

var loaded: bool = false

const LEVELS_UNLOCKED: String = "levels_unlocked"
const SAVED_PREVIOUS_LEVELS_UNLOCKED: String = "previous_levels_unlocked_index"
const PLAYER_DETAILS_SAVE_KEY: String = "player_details"

const NetworkDataSaveName: String = "network_data"
const WalletDataSaveName: String = "wallet_data"
const PlayerDataSaveName: String = "player_data"
const SkillNodesDataDicsSaveName: String = "skill_nodes_data_dic"

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _ready() -> void:
	add_to_group("PersistentNodes")
	game_data_to_save = GameData.new()
	_setup_dictionary()

## ___________________________PUBLIC FUNCTIONS__________________________________________

func level_completed() -> void:
	if current_level < previous_levels_unlocked_index:
		return
	
	previous_levels_unlocked_index = levels_unlocked
	levels_unlocked += 1

func add_weapon_details_to_dictionary(key: String, value: WeaponDetails) -> void:
	weapon_details_dictionary[key] = value
	
	
func get_weapon_details_from_dictionary(key: String) -> WeaponDetails:
	if weapon_details_dictionary.has(key):
		return weapon_details_dictionary[key]
	else:
		printerr("NO WEAPON FOUND FOR {0} ON {1}".format([key, self.name]))
		return null

func init_tween() -> Tween:
	return create_tween()

func init_timer(delay: float) -> SceneTreeTimer:
	return get_tree().create_timer(delay)

func set_resource_to_game_data_dic(resource, key: String, set_in_subdic: bool = false) -> void:
	if !set_in_subdic:
		game_data_resources_dictionary[key] = resource
	else:
		game_data_resources_dictionary[SkillNodesDataDicsSaveName][key] = resource

## Returns the resource contained within game_data_resource_dictionary.
## Key: Key to retrieve
##
## True if the value should be retrieved from an array. Example SkillNodeData.
##
## The value id to retrieve from the array.
func get_resource_from_game_data_dic(key: String, retrieve_from_dic: bool = false, id: String = "Should be defined"):
	if !retrieve_from_dic:
		return game_data_resources_dictionary[key]
	else:
		return game_data_resources_dictionary["skill_nodes_data_dic"][id]

func has_resource(key: String, retrieve_from_dic: bool = false, id: String = "Should be defined") -> bool:
	if !retrieve_from_dic:
		return game_data_resources_dictionary.has(key)
	else:
		return game_data_resources_dictionary["skill_nodes_data_dic"].has(id)


## ___________________________PRIVATE FUNCTIONS______________________________________________

func _setup_dictionary() -> void:
	game_data_resources_dictionary = {
		"network_data": game_data_to_save.bitcoin_network_data,
		"wallet_data": game_data_to_save.bitcoin_wallet_data,
		"player_data": game_data_to_save.player_data,
		"skill_nodes_data_dic": game_data_to_save.skill_nodes_data_dic
	}

## ___________________________PERSISTENCE DATA FUNCTIONS_____________________________________

func save_data() -> void:
	var error = ResourceSaver.save(game_data_to_save, _get_resource_save_path())
	if error != OK:
		print_debug("Failed at saving resource: %s" % error)
	# SaveSystem.set_var(LEVELS_UNLOCKED, levels_unlocked)
	# SaveSystem.set_var(SAVED_PREVIOUS_LEVELS_UNLOCKED, previous_levels_unlocked_index)
	# SaveSystem.set_var(PLAYER_DETAILS_SAVE_KEY, player_details)

func load_data() -> void:
	if loaded: return

	var loaded_game_data: GameData = ResourceLoader.load(_get_resource_save_path())

	if loaded_game_data == null: return

	game_data_to_save = loaded_game_data
	print_debug("Game data loaded %s" % game_data_to_save)
	loaded = true
	# if SaveSystem.has(LEVELS_UNLOCKED) and SaveSystem.has(SAVED_PREVIOUS_LEVELS_UNLOCKED):
	# 	levels_unlocked = SaveSystem.get_var(LEVELS_UNLOCKED)
	# 	previous_levels_unlocked_index = SaveSystem.get_var(SAVED_PREVIOUS_LEVELS_UNLOCKED)
	
	# if !SaveSystem.has(PLAYER_DETAILS_SAVE_KEY): return

	# var data: Dictionary = SaveSystem.get_var(PLAYER_DETAILS_SAVE_KEY)
	# player_details = Utils.dict_to_resource(data, PlayerDetails.new())

func _get_resource_save_path() -> String:
	return "user://saves/game_data.tres"
