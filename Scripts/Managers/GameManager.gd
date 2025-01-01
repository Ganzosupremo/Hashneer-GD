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

const NetworkDataSaveName: String = "user://saves/network_data.tres"
const WalletDataSaveName: String = "user://saves/wallet_data.tres"
const PlayerDataSaveName: String = "user://saves/player_data.tres"
const GameManagerSavePath: String = "user://saves/save_not_nigga.tres"
const SkillNodesDataDicsSaveName: String = "skill_nodes_data_dic"


enum ResourceDataType {
	None = 0,
	NetworkData = 1,
	WalletData = 2,
	PlayerData = 3,
	SkillNodeData = 4
}

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _ready() -> void:
	ResourceLoader.add_resource_format_loader(HashneerFormatLoader.new())
	ResourceSaver.add_resource_format_saver(HashneerFormatSaver.new())
	game_data_to_save = GameData.new()
	_setup_dictionary()

## ___________________________PUBLIC FUNCTIONS__________________________________________

func level_completed() -> void:
	if levels_unlocked < previous_levels_unlocked_index:
		return
	
	levels_unlocked += 1
	previous_levels_unlocked_index = levels_unlocked-1

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

func set_resource_to_game_data_dic(resource, type: ResourceDataType, key: String = "Only define if type is ResourceDataType.SkillNodeData") -> void:
	match type:
		ResourceDataType.NetworkData:
			game_data_to_save.bitcoin_network_data = resource
			print_debug("Resource %s" % resource + "setted on %s" % game_data_to_save)
		ResourceDataType.WalletData:
			game_data_to_save.bitcoin_network_data = resource
			print_debug("Resource %s" % resource + "setted on %s" % game_data_to_save)
		ResourceDataType.PlayerData:
			game_data_to_save.player_data = resource
			print_debug("Resource %s" % resource + "setted on %s" % game_data_to_save)
		ResourceDataType.SkillNodeData:
			game_data_to_save.skill_nodes_data_dic[key] = resource
			print_debug("Resource %s" % resource + "setted on %s" % game_data_to_save.skill_nodes_data_dic)

	# if !set_in_subdic:
	# 	game_data_resources_dictionary[key] = resource
	# else:
	# 	game_data_resources_dictionary[SkillNodesDataDicsSaveName][key] = resource

## Returns the resource contained within game_data_resource_dictionary.
## Key: Key to retrieve
##
## True if the value should be retrieved from an array. Example SkillNodeData.
##
## The value id to retrieve from the array.
func get_resource_from_game_data_dic(type: ResourceDataType, key: String = "Only define if type is ResourceDataType.SkillNodeData"):
	match type:
		ResourceDataType.NetworkData:
			return game_data_to_save.bitcoin_network_data
		ResourceDataType.WalletData:
			return game_data_to_save.bitcoin_wallet_data
		ResourceDataType.PlayerData:
			return game_data_to_save.player_data
		ResourceDataType.SkillNodeData:
			return game_data_to_save.skill_nodes_data_dic[key]
		ResourceDataType.None:
			print_debug("No Resource type defined, returning null...")
			return null
	# if !retrieve_from_dic:
	# 	return game_data_resources_dictionary[key]
	# else:
	# 	return game_data_resources_dictionary["skill_nodes_data_dic"][id]

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
	var data: GameManagerData = GameManagerData.new(levels_unlocked, previous_levels_unlocked_index, current_level)
	var error = ResourceSaver.save(data, GameManagerSavePath)
	if error != OK:
		print_debug("Failed at saving resource: %s" % error)

	var player_data: PlayerSaveData = PlayerSaveData.new(150.0,1000.0,player_details.initial_weapon, player_details.weapons_array, player_details)
	var p_error = ResourceSaver.save(player_data, PlayerDataSaveName)
	if p_error != OK:
		print_debug("Failed at saving player data: %s" % p_error)
	
	# SaveSystem.set_var(LEVELS_UNLOCKED, levels_unlocked)
	# SaveSystem.set_var(SAVED_PREVIOUS_LEVELS_UNLOCKED, previous_levels_unlocked_index)
	# SaveSystem.set_var(PLAYER_DETAILS_SAVE_KEY, player_details)

func load_data() -> void:
	if loaded: return

	if !ResourceLoader.exists(GameManagerSavePath):
		return
	var loaded_game_data: GameManagerData = ResourceLoader.load(GameManagerSavePath).duplicate(true)
	levels_unlocked = loaded_game_data.levels_unlocked
	previous_levels_unlocked_index = loaded_game_data.previous_levels_unlocked_index
	current_level = loaded_game_data.current_level

	var loaded_player_data: PlayerSaveData = ResourceLoader.load(PlayerDataSaveName)
	if loaded_player_data == null: return
	game_data_to_save.player_data = loaded_player_data
	print_debug("Player data loaded %s" % game_data_to_save.player_data)
	loaded = true
	# if SaveSystem.has(LEVELS_UNLOCKED) and SaveSystem.has(SAVED_PREVIOUS_LEVELS_UNLOCKED):
	# 	levels_unlocked = SaveSystem.get_var(LEVELS_UNLOCKED)
	# 	previous_levels_unlocked_index = SaveSystem.get_var(SAVED_PREVIOUS_LEVELS_UNLOCKED)
	# if !SaveSystem.has(PLAYER_DETAILS_SAVE_KEY): return
	# var data: Dictionary = SaveSystem.get_var(PLAYER_DETAILS_SAVE_KEY)
	# player_details = Utils.dict_to_resource(data, PlayerDetails.new())

func _get_resource_save_path() -> String:
	return "user://saves/game_data.tres"
